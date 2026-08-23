local timing = {
  entries = {}
}

local function to_minutes(t)   -- floored to tenths
  return math.floor( t / 60 * 10 ) / 10
end

function timing:start()
  -- if not self then self = {} end
  self.entries[#self.entries + 1] = { start_time = os.time() }
end

function timing:stop()
  local entry = self.entries[#self.entries]
  entry.stop_time = os.time()

  return to_minutes(entry.stop_time - entry.start_time)   -- return delta
end

function timing:print_report()
  local minimum, maximum, sum = math.huge, -math.huge, 0
  for _, data in pairs(self.entries) do
    local delta = data.stop_time - data.start_time
    if delta > maximum then maximum = delta end
    if delta < minimum then minimum = delta end
    sum = sum + delta
  end
  print("Total: " .. to_minutes(sum) .. " minutes.")
  print("Averge: " .. to_minutes(sum / #self.entries) .. " minutes. Fastest: "
    .. to_minutes(minimum) .. " minutes. Slowest: " .. to_minutes(maximum) .. " minutes.")
end

return timing
