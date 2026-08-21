#!/usr/bin/env luajit

package.path = (arg[0]:match("@?(.*/)") or arg[0]:match("@?(.*\\)")) .. "lib" .. package.config:sub(1, 1) .. "?.lua;" .. package.path
local utility = require "utility"

local calibre_location = "/Applications/calibre.app"
local config = utility.get_config("read-only")
if config and config.llm_covers and config.llm_covers.calibre_location then
  calibre_location = config.llm_covers.calibre_location
end

os.execute("mkdir -p raw_ebooks" .. utility.commands.silence_output)
os.execute("mkdir -p extracted_texts" .. utility.commands.silence_output)

utility.ls("raw_ebooks", function(file_name)
  local _, name, extension = utility.split_path_components(file_name)
  if extension then
    name = name:sub(1, -(#extension + 2))
  end

  local output_name = "extracted_texts/" .. name .. ".txt"
  if utility.path_exists(output_name) then return end

  os.execute(calibre_location .. "/Contents/MacOS/ebook-convert " .. ("raw_ebooks/" .. file_name):enquote() .. " " .. output_name:enquote())
end)
