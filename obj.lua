local Proxy = require 'tts/proxy'

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

local function fromTag(tag)
    return
        fromProxy(Proxy.lazy(function() return getObjectsWithTag(tag)[1] end))
end

function Obj.get(params)
    if params.guid then
        return fromGuid(params.guid)
    elseif params.tag then
        return fromTag(params.tag)
    end
end

function Obj.use(o) return fromProxy(Proxy.create(o)) end

function ObjExt:snapTo(snap)
    self.setPositionSmooth(snap.position)
    if snap.rotation_snap then self.setRotationSmooth(snap.rotation) end
end

function ObjExt:isIn(zone)
    local zones = self.getZones()
    for _, z in pairs(zones) do if z.guid == zone.guid then return true end end
    return false
end

return Obj
