#!/usr/bin/env luajit

package.path = (arg[0]:match("@?(.*/)") or arg[0]:match("@?(.*\\)")) .. "lib" .. package.config:sub(1, 1) .. "?.lua;" .. package.path
local utility = require "utility"

local maximum_bytes = 40000

local read_all = function(file_name)
  return utility.open(file_name, "r", function(file)
    return file:read("*all")
  end)
end

local list = function(path, fn)
  utility.list(path or ".", function(path_name)
    if not path_name:find("%.txt") then return end
    if utility.is_file(path .. "/" .. path_name) then
      fn(path .. "/" .. path_name)
    end
  end)
end

for _, path in ipairs{ ".", "extracted_texts", } do
  list(path, function(file_name)
    local path, name, extension = utility.split_path_components(file_name)
    local text = read_all(file_name)

    print(math.floor(#text/maximum_bytes + 1), math.floor(#text/1000) .. "k", name)
  end)
  print("Press enter.")
  io.read("*line")
end
