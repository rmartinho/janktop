local Object = require 'classic'
local iter = require 'iter'
local snap = require 'snap'

local Track = Object:extend('Track')

local function buildTrackPoints(base, snapTag, markerTag)
    local snaps = snap.filterTagOrdered(base, snapTag)
    return iter.map(snaps, function(s)
        local s1 = {position = base.positionToWorld(s.position)}
        setmetatable(s1, {__index = s})
        s = s1
        local z = spawnObject {
            type = 'ScriptingTrigger',
            position = s.position,
            rotation = s.rotation_snap and {0, 0, 0} or s.rotation,
            scale = {0.1, 1, 0.1}
        }
        if markerTag then z.addTag(markerTag) end
        return {snap = s, zone = z}
    end)
end

function Track.__len(self) return #self.points end

function Track:new(params)
    params = params or {}
    if params.base and params.snap_tag then
        self.points = buildTrackPoints(params.base, params.snap_tag,
                                       params.marker_tag)
    else
        self.points = {}
    end
    self.loop = params.loop == true
end

function Track:boundedIndex(i)
    if self.loop then
        return ((i - 1) % #self) + 1
    elseif i > #self then
        return #self
    elseif i < 1 then
        return 1
    else
        return i
    end
end

function Track:indexOf(o)
    for i, pt in ipairs(self.points) do if o:isIn(pt.zone) then return i end end
end

return Track
