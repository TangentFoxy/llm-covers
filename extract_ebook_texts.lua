#!/usr/bin/env luajit

package.path = (arg[0]:match("@?(.*/)") or arg[0]:match("@?(.*\\)")) .. "lib" .. package.config:sub(1, 1) .. "?.lua;" .. package.path
local utility = require "utility"

utility.ls("raw_ebooks", function(file_name)
  local _, name, extension = utility.split_path_components(file_name)
  if extension then
    name = name:sub(1, -(#extension + 2))
  end
  -- TODO this has to be configurable based on where the app is installed
  os.execute("/Applications/calibre.app/Contents/MacOS/ebook-convert " .. ("raw_ebooks/" .. file_name):enquote() .. " " .. ("extracted_texts/" .. name .. ".txt"):enquote())
end)
