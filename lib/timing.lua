local timing = {}

function timing.timer()
  return setmetatable({
    entries = {},
  }, timing)
end

function timing:start()
  -- if not self then self = {} end
  self.entries[#self.entries + 1] = { start_time = os.time() }
end

function timing:stop()
  local entry = self.entries[#self.entries]
  entry.stop_time = os.time()

  -- delta in minutes, floored to tenths
  return math.floor( (entry.stop_time - entry.start_time) / 60 * 10 ) / 10
end

return timing
