local Object = require 'tts/classic'
local iter = require 'tts/iter'
local Snap = require 'tts/snap'

local Track = Object:extend('Track')

function Track.__len(self) return #self.points end

function Track:new(params)
    params = params or {}
    if params.load then
        self.loop = params.load.loop
        self.points = iter.map(params.load.points, Snap.load)
    else
        if params.snapTag then
            self.points = Snap.get {
                base = params.base,
                tag = params.snapTag,
                ordered = true,
                zoned = true
            }
        else
            self.points = {}
        end
        self.loop = params.loop == true
    end
end

function Track:save()
    return {loop = self.loop, points = iter.map(self.points, Snap.save)}
end

function Track.load(data) return Track {load = data} end

function Track:boundedIndex(i)
    if self.loop then
        local i2 = ((i - 1) % #self) + 1
        return i2, i2 < i
    elseif i > #self then
        return #self, true
    elseif i < 1 then
        return 1, true
    else
        return i, false
    end
end

function Track:indexOf(o)
    for i, pt in ipairs(self.points) do if o:isIn(pt.zone) then return i end end
end

return Track
