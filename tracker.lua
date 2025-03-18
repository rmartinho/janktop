local Object = require 'classic'

local Tracker = Object:extend('Tracker')

function Tracker:new(params)
    self.marker = params.marker
    self:bind(params.track)
end

function Tracker:bind(track) self.track = track end

function Tracker:advance(n)
    n = n or 1
    local i = self.track:boundedIndex(self:index())
    self:reset(i + n)
end

function Tracker:reverse(n)
    n = n or 1
    self.advance(self, -n)
end

function Tracker:reset(i)
    i = self.track:boundedIndex(i or 1)
    local pt = self.track.points[i]
    self.marker:snapTo(pt.snap)
end

function Tracker:index() return self.track:indexOf(self.marker) end

return Tracker
