local timing = {}
local entries = {}

function timing.seconds_to_minutes(seconds)   -- floored to tenths
  return math.floor( seconds / 60 * 10 ) / 10
end

function timing.start()
  entries[#entries + 1] = { start_time = os.time() }
end

function timing.stop()
  local entry = entries[#entries]
  entry.stop_time = os.time()
  entry.delta = entry.stop_time - entry.start_time

  return timing.seconds_to_minutes(entry.delta)
end

function timing.print_report()
  local minimum, maximum, sum = math.huge, -math.huge, 0
  for _, data in pairs(entries) do
    local delta = data.delta
    if delta > maximum then maximum = delta end
    if delta < minimum then minimum = delta end
    sum = sum + delta
  end

  print("Total: " .. timing.seconds_to_minutes(sum) .. " minutes.")
  print("Averge: " .. timing.seconds_to_minutes(sum / #entries)
    .. " minutes. Fastest: " .. timing.seconds_to_minutes(minimum)
    .. " minutes. Slowest: " .. timing.seconds_to_minutes(maximum)
    .. " minutes.")
end

return timing
