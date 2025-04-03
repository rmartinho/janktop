local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local Track = require 'tts/track'
local Promise = require 'tts/promise'
local async = require 'tts/async'

local Tracker = Object:extend('Tracker')

function Tracker:new(params)
    if params.load then
        self.marker = Obj {guid = params.load.marker}
        self.track = Track.load(params.load.track)
    else
        self.marker = Obj.use(params.marker)
        self.track = params.track
    end
end

function Tracker:save()
    return {marker = self.marker.guid, track = self.track:save()}
end

function Tracker.load(data) return Tracker {load = data} end

function Tracker:rebind(track, i)
    self.track = track
    return self:reset(i):await()
end

function Tracker:advance(n)
    return async(function()
        n = n or 1
        local i = self:index() or 0
        local a = self:reset(i + n):await()
        local i2, looped = a
        if looped and self.onLoop then Promise.ok(self:onLoop()):await() end
        return i2, looped
    end)
end

function Tracker:reverse(n)
    n = n or 1
    return self.advance(self, -n)
end

function Tracker:setup(i) return self:reset(i) end

local dropOffset = Vector(0, 0.5, 0)

function Tracker:reset(i)
    return async(function()
        local i2, looped = self.track:boundedIndex(i or 1)
        local pt = self.track.points[i2]
        self.marker:snapTo(pt, dropOffset):await()
        if self.onStep then Promise.ok(self:onStep(i2, looped)):await() end
        return {i2, looped}
    end)
end

function Tracker:index() return self.track:indexOf(self.marker) end

return Tracker
