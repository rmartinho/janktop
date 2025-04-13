local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local iter = require 'tts/iter'
local async = require 'tts/async'

local Layout = Object:extend('Layout')

Layout.zones = {}

-- TODO load

function Layout.of(zone) return Layout.zones[zone.guid] end

function Layout.onDrop(p, o)
    local dropped = {}
    local zones = o.getZones()
    if #zones == 0 and o.hasTag('Return') and o.memo then
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

local function layoutWith(self, dropped, pattern, tag, tags)
    local set = {}
    local objects = {}

    local function checkTags(o)
        if tag and #tag == 0 then
            if not iter.any(tags, function(t) return o.hasTag(t) end) then
                table.insert(objects, o)
                set[o.guid] = true
            end
        else
            if not tag or o.hasTag(tag) then
                table.insert(objects, o)
                set[o.guid] = true
            end
        end
    end

    for _, o in pairs(self.zone.getObjects()) do checkTags(o) end
    for _, o in pairs(dropped) do
        if not set[o.object.guid] then checkTags(o.object) end
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
        local heightDiff = o.getVisualBoundsNormalized().size.y / 2
        local diff =
            Vector.distance(o.getPosition(), Vector(points[i].position)) -
                heightDiff - o.getVisualBoundsNormalized().offset:magnitude()
        if diff > 0.015 then
            table.insert(moves, async(function()
                o:snapTo(points[i], {0, 1, 0}):await()
                Layout.inserting[o.guid] = nil
            end))
        else
            Layout.inserting[o.guid] = nil
        end
    end
    return async.par(moves)
end

function Layout:new(params)
    Layout.zones[params.zone.guid] = self
    self.zone = params.zone
    self.patterns = params.patterns
    self.pattern = params.pattern
    self.sticky = params.sticky == true
    self.preserveRotationValue = params.preserveRotationValue == true
    self.dropped = {}
end

function Layout:drop(p, o) table.insert(self.dropped, {object = o, player = p}) end

Layout.inserting = {}

function Layout:insert(objects)
    if #objects == 0 then return end
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
            l:layout():await()
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
        local tags = {}
        for t, _ in pairs(self.patterns) do
            if #t > 0 then table.insert(tags, t) end
        end
        for t, p in pairs(self.patterns) do
            table.insert(layouts, layoutWith(self, dropped, p, t, tags))
        end
        return async.par(layouts)
    else
        return layoutWith(self, dropped, self.pattern)
    end
end

return Layout
