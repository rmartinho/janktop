local Object = require 'tts/classic'

local Pattern = Object:extend('Pattern')

function Pattern:points()
  return {}
end

Pattern.none = Pattern()

Pattern.fromSnaps = Pattern:extend()

function Pattern.fromSnaps:new(snaps)
  self.snaps = snaps
end

function Pattern.fromSnaps:points()
  return self.snaps
end

return Pattern