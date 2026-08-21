#!/usr/bin/env luajit

package.path = (arg[0]:match("@?(.*/)") or arg[0]:match("@?(.*\\)")) .. "lib" .. package.config:sub(1, 1) .. "?.lua;" .. package.path
local utility = require "utility"
local prompts = require "prompts"

local default_model = "gemma4:12b-mlx"
local maximum_bytes = 40000

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

local timings = {}
local timing_report = function()
  local minimum, maximum, sum = math.huge, 0, 0
  for _, delta in ipairs(timings) do
    if delta > maximum then maximum = delta end
    if delta < minimum then minimum = delta end
    sum = sum + delta
  end
  print("")
  print("Prompts took a total of " .. sum .. " minutes.")
  print("Average: " .. math.floor(sum / #timings) .. " minutes. Fastest: " .. minimum .. " minutes. Slowest: " .. maximum .. " minutes.")
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

  local start_time = os.time()
  -- word wrap breaks the raw output badly, so I need to implement my own for terminal output somehow
  local output = utility.capture_safe("cat " .. tmp_file_name:enquote() .. " | ollama run " .. (model or default_model) .. " --nowordwrap")
  os.execute("ollama stop " .. (model or default_model)) -- NOTE this makes things slower, but more stable
  local delta = math.floor( (os.time() - start_time) / 60 * 10 ) / 10
  print("Took " .. delta .. " minutes.")
  timings[#timings + 1] = delta
  os.execute("rm " .. tmp_file_name)
  if not output then error("ollama failed to generate output") end
  output = output:sub(1, -2) -- strip extra newline from utility.capture_safe

  output = strip_reasoning(output)

  return output
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

local generate_cover_brief = function(name)
  local text = read_all("intermediates/" .. name)
  print("Generating cover brief.")
  text = send_prompt(prompts.cover_brief .. text)
  write_all("cover_briefs/" .. name, text)
  write_all("for_gemini/" .. name, "Title: " .. name:sub(1, -5) .. prompts.for_gemini .. text)
end

local combine_summaries = function(name)
  local summaries, i = {}, 1
  while true do
    local summary_path = "intermediates/" .. name:sub(1, -5) .. "-summaries-" .. i .. ".txt"
    if utility.path_exists(summary_path) then
      print("Restored summary " .. i .. ".")
      summaries[i] = read_all(summary_path)
    else
      -- TODO how do we determine whether we ran out or needed to keep going?
    end
  end
  -- TODO I lost track of what I'm trying to do here
end

os.execute("mkdir -p extracted_texts" .. utility.commands.silence_output)
os.execute("mkdir -p intermediates" .. utility.commands.silence_output)
os.execute("mkdir -p cover_briefs" .. utility.commands.silence_output)
os.execute("mkdir -p for_gemini" .. utility.commands.silence_output)

tree("extracted_texts", function(file_name)
  local _, name, extension = utility.split_path_components(file_name)
  if utility.path_exists("cover_briefs/" .. name) then return end

  if utility.path_exists("intermediates/" .. name) then
    generate_cover_brief(name)
    return
  end

  if utility.path_exists("intermediates/" .. name:sub(1, -5) .. "-summaries-1.txt") then
    combine_summaries(name)
    generate_cover_brief(name)
    return
  end
end)



local process_intermediates = function(text, name)
  local result
  local outputs = {}

  -- TODO check if this would work just as well starting from 1 instead..
  for i = 0, #text/maximum_bytes do
    print("Processing section " .. (i + 1) .. " of " .. math.floor(#text/maximum_bytes + 1))

    local intermediate_name = "intermediates/" .. name:sub(1, -5) .. "-" .. tostring(#outputs + 1) .. ".txt"
    if utility.path_exists(intermediate_name) then
      result = read_all(intermediate_name)
      print("Loaded from file.")
    else
      local piece = text:sub(i * maximum_bytes, (i + 1) * maximum_bytes - 1)
      result = send_prompt(prompts.section_summarization .. piece)
      write_all(intermediate_name, result)
    end

    outputs[#outputs + 1] = result
    print(#result .. " characters added to intermediate context.")
  end

  text = table.concat(outputs, "\n\n")
  write_all("intermediates/" .. name, text)
  print("Saved primary intermediate prompt.")

  for i = 0, #text/maximum_bytes do
    local intermediate_name = "intermediates/" .. name:sub(1, -5) .. "-" .. tostring(#outputs + 1) .. ".txt"
    if utility.path_exists(intermediate_name) then
      os.execute("rm " .. intermediate_name:enquote())
    end
  end
  print("Removed redundant intermediate prompts.")

  return result, outputs, text
end

tree("extracted_texts", function(file_name)
  local path, name, extension = utility.split_path_components(file_name)
  if utility.path_exists("cover_briefs/" .. name) then return end

  local text = read_all(file_name)
  local result

  -- TODO there is no way to recognize a dangling intermediate and pickup from there
  print(name)
  local outputs

  -- restore previous intermediate
  -- (this is where I realized I should redo how I'm processing all of this)
  if utility.path_exists("intermediates/" .. name) then
  end

  if #text > maximum_bytes then
    -- previously overwrites result, text, outputs
    result, outputs, text = process_intermediates(text, name)
  end

  -- handle too much context (works with up to 100 slices)
  if #outputs > 10 then
    local context_slices = {}
    while #outputs > 2 do
      local summary_pieces = {}
      for i = 1, 10 do
        if #outputs >= 1 then
          summary_pieces[#summary_pieces + 1] = table.remove(outputs, 1)
        end
      end

      print("Squishing context. " .. #outputs .. " samples remaining.")
      result = send_prompt(prompts.combine_summaries .. table.concat(summary_pieces, "\n\n"))
      context_slices[#context_slices + 1] = result
      print(#result .. " characters added to final context.")
    end

    text = table.concat(context_slices, "\n\n")
    write_all("intermediates/" .. name:sub(1, -5) .. " CONDENSED.txt", text)
  end

end)

timing_report()
