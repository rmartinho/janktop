local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local async = require 'tts/async'

local Layout = Object:extend('Layout')

Layout.zones = {}

-- TODO load

function Layout.of(zone) return Layout.zones[zone.guid] end

function Layout.onDrop(p, o)
    local dropped = {}
    local zones = o.getZones()
    if #zones == 0 and o.hasTag('Return') then
        local z = Obj.get {guid = o.memo}
        table.insert(zones, z)
    end
    for _, z in pairs(zones) do
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

local leaveDelay = 30
function Layout.onLeave(z, o)
    local l = Layout.of(z)
    if o.hasTag('Return') and l and l.sticky then o.memo = z.guid end
    if l and not Layout.inserting[o.guid] then
        if l.leaving then Wait.stop(l.leaving) end
        l.leaving = Wait.frames(function()
            l.leaving = nil
            l:layout(true)
        end, leaveDelay)
    end
end

local function layoutWith(self, dropped, pattern, tag)
    local set = {}
    local objects = {}
    for _, o in pairs(self.zone.getObjects()) do
        if not tag or o.hasTag(tag) then
            table.insert(objects, o)
            set[o.guid] = true
        end
    end
    for _, o in pairs(dropped) do
        if not tag or o.object.hasTag(tag) then
            if not set[o.object.guid] then
                table.insert(objects, o.object)
                set[o.object.guid] = true
            end
        end
    end

    local points = pattern:points(#objects)
    local max = #points > #objects and #objects or #points
    local moves = {}
    for i = 1, max do
        local o = Obj.use(objects[i])
        if self.preserveRotationValue then
            local value = o.getValue()
            points[i].rotation = o.getRotationValues()[value].rotation
        end
        table.insert(moves, async(function()
            o:snapTo(points[i], {0, 1, 0}):await()
            Layout.inserting[o.guid] = nil
        end))
    end
    return async.par(moves)
end

function Layout:new(params)
    self.zone = params.zone
    Layout.zones[params.zone.guid] = self
    self.patterns = params.patterns
    self.pattern = params.pattern
    self.sticky = params.sticky == true
    self.preserveRotationValue = params.preserveRotationValue == true
    self.dropped = {}
end

function Layout:drop(p, o) table.insert(self.dropped, {object = o, player = p}) end

Layout.inserting = {}

function Layout:insert(objects)
    for _, o in pairs(objects) do
        if o.type ~= 'Scripting' then
            Layout.inserting[o.guid] = true
            table.insert(self.dropped, {object = o, player = nil})
        end
    end
    return self:layout()
end

function Layout.remove(o)
    return async(function()
        local z = Obj.get {guid = o.memo}
        local l = Layout.of(z)
        if l then
            l:drop(p, o)
            async.frames():await()
            return l:layout()
        end
    end)
end

function Layout:layout(force)
    local dropped = self.dropped
    if #dropped == 0 and not force then return end
    if self.leaving then Wait.stop(self.leaving) end
    self.dropped = {}

    if self.patterns then
        local layouts = {}
        for t, p in pairs(self.patterns) do
            table.insert(layouts, layoutWith(self, dropped, p, t))
        end
        return async.par(layouts)
    else
        return layoutWith(self, dropped, self.pattern)
    end
end

return Layout
