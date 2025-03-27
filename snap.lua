local Object = require 'tts/classic'
local iter = require 'tts/iter'
local Obj = require 'tts/obj'

local Snap = Object:extend('Snap')

function Snap:new(params)
    params = params or {}
    if params.load then
        self.position = params.load.position
        self.rotation = params.load.rotation
        self.tags = params.load.tags
        self.zone = params.load.zone and Obj.get {guid = params.load.zone} or
                        nil
    else
        if params.base then
            self.position = params.base.positionToWorld(params.point.position)
        else
            self.position = params.point.position
        end
        if params.point.rotation_snap then
            if params.base then
                self.rotation = params.base.getRotation() +
                                    params.point.rotation
            else
                self.rotation = params.point.rotation
            end
        end
        self.allowFlip = params.allowFlip ~= false

        self.tags = params.point.tags

        if params.zoned then
            self.zone = spawnObject {
                type = 'ScriptingTrigger',
                position = self.position,
                rotation = self.rotation or {0, 0, 0},
                scale = {0.1, 3, 0.1}
            }
            for _, tag in pairs(params.point.tags) do
                self.zone.addTag(tag)
            end
        end
    end
end

function Snap:save()
    return {
        position = self.position,
        rotation = self.rotation,
        tags = self.tags,
        zone = self.zone and self.zone.guid or nil
    }
end

function Snap.load(data) return Snap {load = data} end

local function hasTag(pt, tag) return iter.has(pt.tags, tag) and true or false end
Snap.hasTag = hasTag
local function hasAllTags(pt, tags)
    return iter.hasAll(pt.tags, tags) and true or false
end
Snap.hasAllTags = hasAllTags
local function hasAnyTag(pt, tags)
    return iter.hasAny(pt.tags, tags) and true or false
end
Snap.hasAnyTag = hasAnyTag

function Snap.get(params)
    params = params or {}
    local obj = params.base or Global
    local pts = obj.getSnapPoints()
    if params.ordered then
        local count = iter.count(pts,
                                 function(p) return hasTag(p, params.tag) end)
        local r = {}
        for i = 1, count do
            params.point = iter.find(pts, function(p)
                return hasAllTags(p, {params.tag, 'n'..i})
            end)
            table.insert(r, Snap(params))
        end
        return r
    else
        return iter.filterMap(pts, function(p)
            params.point = p
            if not params.tag and not params.tags then
                return Snap(params)
            elseif params.tags and hasAllTags(p, params.tags) then
                return Snap(params)
            elseif params.tag and hasTag(p, params.tag) then
                return Snap(params)
            end
        end)
    end
end

return Snap
