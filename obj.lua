local Proxy = require 'tts/proxy'
local async = require 'tts/async'
local iter = require 'tts/iter'

local Obj = {}
local Ext = {}

local function fromProxy(pxy)
    local obj = {}
    local meta = {
        __index = function(_, k) return Ext[k] or pxy[k] end,
        __tostring = function(o)
            local inner = getmetatable(o).__proxy
            return tostring(inner) .. ' ' .. inner.guid
        end
    }
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

function Obj.use(o) if o then return fromProxy(Proxy(o)) end end

function Obj.load(data) return Obj.get {guid = data.guid} end

setmetatable(Obj, {__call = function(self, ...) return self.get(...) end})

function Ext:save() return {guid = self.guid} end

function Ext:snapTo(snap, offset)
    local pos = Vector(snap.position)
    if offset then pos = pos + Vector(offset) end
    local locked = self.getLock()
    if offset then self.setLock(false) end
    self.setPositionSmooth(pos)
    if snap.rotation then
        local rotation = Vector(snap.rotation)
        if not snap.allowFlip then
            rotation:setAt('z', self.getRotation().z)
        end
        self.setRotationSmooth(rotation)
    end
    return async(function()
        if offset then
            async.rest(self):await()
            self.setLock(locked)
        end
        return self
    end)
end

function Ext:leaveTowards(snap, duration)
    return async(function()
        self:snapTo(snap):await()
        async.frames(duration or 10):await()
        self.destroy()
    end)
end

function Ext:isIn(zone)
    local zones = self.getZones()
    for _, z in pairs(zones) do if z.guid == zone.guid then return true end end
    return false
end

function Ext:deckDropPosition()
    local bounds = self.getVisualBoundsNormalized()
    return {
        bounds.center.x, bounds.center.y + bounds.size.y / 2, bounds.center.z
    }
end

function Ext:removeObjectsIf(pos, f)
    local cards = self.getObjects()
    local toRemove = {}
    for i = 1, #cards do
        if f(cards[i]) then table.insert(toRemove, cards[i].guid) end
    end
    return async.par(iter.map(toRemove, function(guid)
        return async(function()
            local card = Obj.use(self.takeObject {guid = guid, position = pos})
            card:leaveTowards(pos):await()
        end)
    end))
end

return Obj
