local Object = require 'tts/classic'
local Track = require 'tts/track'
local Obj = require 'tts/obj'

local Tracker = Object:extend('Tracker')

function Tracker:new(params)
    if params.load then
        self.marker = Obj.get {guid = params.load.marker}
        self.track = Track.load(params.load.track)
    else
        self.marker = params.marker
        self:bind(params.track)
    end
end

function Tracker:save()
    return {marker = self.marker.guid, track = self.track:save()}
end

function Tracker.load(data)
    return Tracker {load = data} end

function Tracker:bind(track) self.track = track end

function Tracker:advance(n)
    n = n or 1
    local i = self:index() or 0
    self:reset(i + n)
end

function Tracker:reverse(n)
    n = n or 1
    self.advance(self, -n)
end

function Tracker:reset(i)
    i = self.track:boundedIndex(i or 1)
    local pt = self.track.points[i]
    self.marker:snapTo(pt)
end

function Tracker:index() return self.track:indexOf(self.marker) end

return Tracker
