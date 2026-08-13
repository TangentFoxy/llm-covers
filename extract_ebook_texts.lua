#!/usr/bin/env luajit

package.path = (arg[0]:match("@?(.*/)") or arg[0]:match("@?(.*\\)")) .. "lib" .. package.config:sub(1, 1) .. "?.lua;" .. package.path
local utility = require "utility"

local calibre_location = "/Applications/calibre.app"
local config = utility.get_config()
if config and config.llm_covers and config.llm_covers.calibre_location then
  calibre_location = config.llm_covers.calibre_location
end

utility.ls("raw_ebooks", function(file_name)
  local _, name, extension = utility.split_path_components(file_name)
  if extension then
    name = name:sub(1, -(#extension + 2))
  end
  os.execute(calibre_location .. "/Contents/MacOS/ebook-convert " .. ("raw_ebooks/" .. file_name):enquote() .. " " .. ("extracted_texts/" .. name .. ".txt"):enquote())
end)
