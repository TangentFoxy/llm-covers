#!/usr/bin/env luajit

package.path = (arg[0]:match("@?(.*/)") or arg[0]:match("@?(.*\\)")) .. "lib" .. package.config:sub(1, 1) .. "?.lua;" .. package.path
local utility = require "utility"

local default_model = "gemma4:12b-mlx"
local maximum_bytes = 40000

local partial_prompt = [[You are extracting information for a later cover design process.

This is only one section of a larger story.

Do NOT attempt to design a cover.
Do NOT decide what should appear on the cover.
Do NOT write a summary.

Extract only information that may be useful when creating a cover after all story sections have been analyzed.

Return:

GENRE:
- up to 5 items

SETTING:
- locations
- environments
- time period

CHARACTERS:
- names
- physical descriptions
- distinctive visual traits

CREATURES:
- notable creatures

OBJECTS:
- important recurring items

VISUAL MOTIFS:
- recurring imagery
- symbols
- repeated visual elements

THEMES:
- major themes

MOOD:
- emotional tone

COLORS:
- colors strongly associated with scenes or imagery

MEMORABLE VISUAL SCENES:
- 3-10 visually striking moments

CONFIDENCE:
- how central each item appears to be

]]

local cover_brief_prompt = [[Generate a cover brief from the following:

]]

local segmented_cover_brief_prompt = [[Generate a single cover brief.

Prefer elements that:
- appear repeatedly across chunks
- have highest confidence
- best represent the entire story

Avoid minor plot events.

]]

local gemini_prompt = [[

Generate a flate image of an ebook cover inset within an empty white border 10% larger than the cover using the following cover brief:

]]

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

tree("extracted_texts", function(file_name)
  local path, name, extension = utility.split_path_components(file_name)
  if utility.path_exists("cover_briefs/" .. name) then return end

  local text = read_all(file_name)
  local result

  print(name)
  if #text > maximum_bytes then
    local outputs = {}
    -- TODO check if this would work just as well starting from 1 instead..
    for i = 0, #text/maximum_bytes do
      print("Processing section " .. (i + 1) .. " of " .. math.floor(#text/maximum_bytes + 1))
      local piece = text:sub(i * maximum_bytes, (i + 1) * maximum_bytes - 1)
      result = send_prompt(partial_prompt .. piece)
      outputs[#outputs + 1] = result
      print(#result .. " characters added to intermediate context.")
    end

    text = table.concat(outputs, "\n\n")
    -- TODO handle if there is too much context!
    write_all("intermediates/" .. name, text)
  end

  print("Generating cover brief.")
  result = send_prompt(cover_brief_prompt .. text)
  write_all("cover_briefs/" .. name, result)
  write_all("for_gemini/" .. name, name:sub(1, -5) .. gemini_prompt .. result)
end)

timing_report()
