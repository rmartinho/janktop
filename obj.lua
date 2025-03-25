local Proxy = require 'tts/proxy'
local async = require 'tts/async'

local Obj = {}
local ObjExt = {}

local function fromProxy(pxy)
    local obj = {}
    local meta = {__index = function(_, k) return ObjExt[k] or pxy[k] end}
    setmetatable(meta, {__index = getmetatable(pxy)})
    setmetatable(obj, meta)
    return obj
end

local function fromGuid(guid)
    return fromProxy(Proxy.lazy(function() return getObjectFromGUID(guid) end))
end

local function fromTags(tags)
    return fromProxy(Proxy.lazy(function()
        return getObjectsWithAllTags(tags)[1]
    end))
end

function Obj.get(params)
    if params.guid then
        return fromGuid(params.guid)
    elseif params.tags then
        return fromTags(params.tags)
    elseif params.tag then
        return fromTags {params.tag}
    end
end

function Obj.use(o) if o then return fromProxy(Proxy.create(o)) end end

function Obj.load(data) return Obj.get {guid = data.guid} end

function ObjExt:save() return {guid = self.guid} end

function ObjExt:snapTo(snap, offset)
    local pos = Vector(snap.position)
    if offset then pos = pos + Vector(offset) end
    local locked = self.getLock()
    if offset then self.setLock(false) end
    self.setPositionSmooth(pos)
    if snap.rotation then self.setRotationSmooth(snap.rotation) end
    if offset then
        async(function()
            async.wait.rest(self)
            self.setLock(true)
        end)
    end
end

function ObjExt:isIn(zone)
    local zones = self.getZones()
    for _, z in pairs(zones) do if z.guid == zone.guid then return true end end
    return false
end

function ObjExt:deckDropPosition()
    local bounds = self.getVisualBoundsNormalized()
    return {
        bounds.center.x, bounds.center.y + bounds.size.y / 2, bounds.center.z
    }
end

function ObjExt:removeObjectsIf(pos, f)
    local cards = self.getObjects()
    local toRemove = {}
    for i = 1, #cards do
        if f(cards[i]) then table.insert(toRemove, cards[i].guid) end
    end

    for _, guid in pairs(toRemove) do
        local card = self.takeObject({guid = guid, position = pos})
        Wait.frames(function() card.destroy() end)
    end
end

return Obj
