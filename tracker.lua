local Object = require 'tts/classic'
local Track = require 'tts/track'
local Obj = require 'tts/obj'
local async = require 'tts/async'

local Tracker = Object:extend('Tracker')

function Tracker:new(params)
    if params.load then
        self.marker = Obj.get {guid = params.load.marker}
        self.track = Track.load(params.load.track)
    else
        self.marker = params.marker
        self.track = params.track
    end
end

function Tracker:save()
    return {marker = self.marker.guid, track = self.track:save()}
end

function Tracker.load(data) return Tracker {load = data} end

function Tracker:rebind(track, i)
    self.track = track
    self:reset(i)
end

function Tracker:advance(n)
    n = n or 1
    local i = self:index() or 0
    local i2, looped = self:reset(i + n)
    if looped and self.onLoop then self:onLoop() end
    return i2, looped
end

function Tracker:reverse(n)
    n = n or 1
    self.advance(self, -n)
end

function Tracker:setup() return self:reset() end

local dropOffset = Vector(0, 0.5, 0)

function Tracker:reset(i)
    i, looped = self.track:boundedIndex(i or 1)
    local pt = self.track.points[i]
    async(function()
        self.marker:snapTo(pt, dropOffset)
        async.wait.rest(self.marker)
    end)
    if self.onStep then self:onStep(i, looped) end
    return i, looped
end

function Tracker:index() return self.track:indexOf(self.marker) end

return Tracker
