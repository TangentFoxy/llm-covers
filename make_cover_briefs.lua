#!/usr/bin/env luajit

package.path = (arg[0]:match("@?(.*/)") or arg[0]:match("@?(.*\\)")) .. "lib" .. package.config:sub(1, 1) .. "?.lua;" .. package.path
local utility = require "utility"
local prompts = require "prompts"
local timing = require "timing"

local config = utility.get_config("read-only")
if not config.llm_covers then config.llm_covers = {} end
if not config.llm_covers.calibre_location then config.llm_covers.calibre_location = "/Applications/calibre.app" end
if not config.llm_covers.default_model then config.llm_covers.default_model = "gemma4:12b-mlx" end
if not config.llm_covers.maximum_bytes then config.llm_covers.maximum_bytes = 40000 end

local read_all = function(file_name)
  return utility.open(file_name, "r", function(file)
    return file:read("*all")
  end)
end
local write_all = function(file_name, text)
  return utility.open(file_name, "w", function(file)
    file:write(text)
    file:write("\n")
  end)
end

local strip_reasoning = function(text, reasoning_lines)
  if not reasoning_lines then reasoning_lines = {} end
  local tab = text:split("\n")
  table.remove(tab, 1) -- remove "Thinking..."

  while true do
    local done = tab[1] == "...done thinking."
    local line = table.remove(tab, 1)
    if done then
      table.remove(tab, 1) -- remove newline after end of thinking
      return table.concat(tab, "\n")
    elseif #tab < 1 then
      return text -- no reasoning output
    else
      reasoning_lines[#reasoning_lines + 1] = line -- export thinking lines
    end
  end
end

local send_prompt = function(text, model)
  if type(text) == "table" then text = table.concat(text, "\n") end

  local tmp_file_name = utility.tmp_file_name()
  utility.open(tmp_file_name, "w", function(file)
    file:write(text)
  end)

  timing:start()
  -- word wrap breaks the raw output badly, so I need to implement my own for terminal output somehow
  local output = utility.capture_safe("cat " .. tmp_file_name:enquote() .. " | ollama run " .. (model or default_model) .. " --nowordwrap")
  os.execute("ollama stop " .. (model or default_model)) -- NOTE this makes things slower, but more stable
  local delta = timing:stop()

  print("Took " .. delta .. " minutes.")
  os.execute("rm " .. tmp_file_name)
  if not output then error("ollama failed to generate output") end

  output = output:sub(1, -2) -- strip extra newline from utility.capture_safe
  output = strip_reasoning(output)
  return output
end

local make_directories = function()
  os.execute("mkdir -p raw_ebooks" .. utility.commands.silence_output)
  os.execute("mkdir -p extracted_texts" .. utility.commands.silence_output)
  os.execute("mkdir -p intermediates" .. utility.commands.silence_output)
  os.execute("mkdir -p cover_briefs" .. utility.commands.silence_output)
  os.execute("mkdir -p for_gemini" .. utility.commands.silence_output)
end

local tree
tree = function(path, fn)
  utility.list(path or ".", function(path_name)
    local blacklist = {
      [".git"] = true,
      [".gitkeep"] = true,
      [".gitignore"] = true,
      [".DS_Store"] = true,
    }
    if blacklist[path_name] then return end
    if utility.is_file(path_name) then
      fn(path_name)
    else
      tree(path .. utility.path_separator .. path_name, fn)
    end
  end)
end

local find_ebook_files = function(books)
  if not books then books = {} end

  tree("raw_ebooks", function(file_name)
    local _, name, extension = utility.split_path_components(file_name)
    if extension then
      name = name:sub(1, -(#extension + 2))
    end

    if not books[name] then
      books[name] = {}
    end
    books[name].ebook_file = file_name
  end)

  return books
end

local find_extracted_texts = function(books)
  if not books then books = {} end

  tree("extracted_texts", function(file_name)
    local _, name, extension = utility.split_path_components(file_name)
    if extension then
      name = name:sub(1, -(#extension + 2))
    end

    if not books[name] then
      books[name] = {}
    end
    books[name].extracted_file = file_name
    books[name].extracted_file_size = utility.file_size(file_name)
  end)

  return books
end

local find_cover_briefs = function(books)
  if not books then books = {} end

  tree("cover_briefs", function(file_name)
    local _, name, extension = utility.split_path_components(file_name)
    if extension then
      name = name:sub(1, -(#extension + 2))
    end

    if not books[name] then
      books[name] = {}
    end
    books[name].cover_brief_file = file_name
  end)

  return books
end

local get_books = function()
  local books = {}
  find_ebook_files(books)
  find_extracted_texts(books)
  find_cover_briefs(books)
  return books
end

local convert_ebooks = function(books)
  for name, data in pairs(books) do
    if data.extracted_file then return end
    if not data.ebook_file then return end

    local extracted_file = "extracted_texts/" .. name .. ".txt"
    os.execute(config.llm_covers.calibre_location .. "/Contents/MacOS/ebook-convert "
      .. data.ebook_file:enquote() .. " " .. extracted_file:enquote())

    if utility.path_exists(extracted_file) then
      data.extracted_file = extracted_file
    end
  end
end

local condense_summary = function(name, data, sections)
  local condensed_sections = {}

  while #sections > 2 do -- this intentionally can skip the end of a book?
    local sections_slice = {}
    for i = 1, 10 do
      if #sections >= 1 then
        sections_slice[#sections_slice + 1] = table.remove(sections, 1)
      end
    end

    local intermediate_condensation_file = "intermediates/" .. name .. "-" .. (#condensed_sections + 1) .. "-condensed.txt"
    if utility.path_exists(intermediate_condensation_file) then
      condensed_sections[#condensed_sections + 1] = read_all(intermediate_condensation_file)
      print("Loaded condensed summary segment. " .. #sections .. " sections remaining.")
    else
      print("Condensing summary. " .. #sections .. " sections remaining.")
      local text = send_prompt(prompts.combine_summaries .. table.concat(sections_slice, "\n\n"))
      condensed_sections[#condensed_sections + 1] = text
      print(#text .. " characters added to final context.")
      write_all(intermediate_condensation_file, text)
    end
  end

  text = table.concat(condensed_sections, "\n\n")
  local condensed_intermediate_file = "intermediates/" .. name .. " CONDENSED.txt"
  write_all(condensed_intermediate_file, text)
  data.condensed_intermediate_file = condensed_intermediate_file

  -- if deleted any sooner, could break resuming
  for i = 1, #condensed_sections do
    local intermediate_condensation_file = "intermediates/" .. name .. "-" .. i .. "-condensed.txt"
    os.execute("rm " .. intermediate_condensation_file:enquote())
  end

  return text
end

local generate_summary = function(name, data)
  local text = read_all(data.extracted_file)
  local sections = {}

  for i = 0, data.extracted_file_size/config.llm_covers.maximum_bytes do
    local intermediate_section_file = "intermediates/" .. name .. "-" .. i .. ".txt"
    if utility.path_exists(intermediate_section_file) then
      sections[#sections + 1] = read_all(intermediate_section_file)
      print("Loaded section " .. (i + 1) .. ".")
    else
      print("Processing section " .. (i + 1) .. " of " .. math.floor(data.extracted_file_size/config.llm_covers.maximum_bytes + 1))
      local section = text:sub(i * config.llm_covers.maximum_bytes, (i + 1) * config.llm_covers.maximum_bytes - 1)
      section = send_prompt(prompts.section_summarization .. section)
      sections[#sections + 1] = section
      print(#section .. " characters added to intermediate context.")
      write_all(intermediate_section_file, section)
    end
  end

  text = table.concat(sections, "\n\n")
  local intermediate_file = "intermediates/" .. name .. ".txt"
  write_all(intermediate_file, text)
  data.intermediate_file = intermediate_file

  if #sections > 10 then
    text = condense_summary(name, data, sections)
  end

  -- if these temporary files are removed before condense_summary is called,
  --   sections cannot be individually loaded, which breaks condense_summary
  for i = 0, data.extracted_file_size/config.llm_covers.maximum_bytes do
    local intermediate_section_file = "intermediates/" .. name .. "-" .. i .. ".txt"
    os.execute("rm " .. intermediate_section_file:enquote())
  end

  return text
end

local generate_cover_briefs = function(books)
  for name, data in pairs(books) do
    if data.cover_brief_file then return end
    print(name)

    local text
    if data.extracted_file_size > config.llm_covers.maximum_bytes then
      text = generate_summary(name, data)
    else
      text = read_all(extracted_file)
    end

    print("Generating cover brief.")
    text = send_prompt(prompts.cover_brief .. text)

    local cover_brief_file = "cover_briefs/" .. name .. ".txt"
    write_all(cover_brief_file, text)
    write_all("for_gemini/" .. name .. ".txt", "Title: " .. name .. prompts.for_gemini .. text)
    data.cover_brief_file = cover_brief_file
  end
end

make_directories()

local books = get_books()
convert_ebooks(books)
generate_cover_briefs(books)

print("")
timing:print_report()

-- ebook_file, extracted_file, extracted_file_size,
-- intermediate_file, condensed_intermediate_file, cover_brief_file
