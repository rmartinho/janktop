local Object = require 'tts/classic'
local Obj = require 'tts/obj'

local Layout = Object:extend('Layout')

Layout.zones = {}

-- TODO load

function Layout.of(zone) return Layout.zones[zone.guid] end

function Layout.onDrop(p, o)
    local dropped = {}
    for _, z in pairs(o.getZones()) do
        local l = Layout.of(z)
        if l then
            l:drop(p, o)
            dropped[z.guid] = true
        end
    end
    for g, _ in pairs(dropped) do
        Wait.frames(function() Layout.zones[g]:layout() end, 1)
    end
end

function Layout:new(params)
    self.zone = params.zone
    Layout.zones[params.zone.guid] = self
    self.pattern = params.pattern or Pattern.none

    self.dropped = {}
end

function Layout:drop(p, o) table.insert(self.dropped, {object = o, player = p}) end

function Layout:layout()
    local dropped = self.dropped
    if #dropped == 0 then return end
    self.dropped = {}

    local set = {}
    local objects = {}
    for _, o in pairs(self.zone.getObjects()) do
        table.insert(objects, o)
        set[o.guid] = true
    end
    for _, o in pairs(dropped) do
        if not set[o.object.guid] then
            table.insert(objects, o.object)
            set[o.object.guid] = true
        end
    end

    local points = self.pattern:points(#objects)
    local max = #points > #objects and #objects or #points
    for i = 1, max do Obj.use(objects[i]):snapTo(points[i], {0, 1, 0}) end
end

return Layout
