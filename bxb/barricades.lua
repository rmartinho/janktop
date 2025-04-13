local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'
local iter = require 'tts/iter'

local barricadePositions = {
    {{0, 0, 0}}, {{0, 0, 0.5}, {0, 0, -0.5}},
    {{0, 0, 0.5}, {0, 0, -0.5}, {0, 2, 0}}
}

local barricadeRotations = {
    {{0, 0, 0}}, {{0, 0, 0}, {0, 0, 0}}, {{0, 0, 0}, {0, 0, 0}, {0, 1, 0}}
}

Pattern.barricade = Pattern:extend()

function Pattern.barricade:new(params)
    self.center = params.center
    self.width = params.width
    self.tilt = params.tilt
end

function Pattern.barricade:points(n)
    if n == 0 then return {} end
    if n > #barricadePositions then return self:points(#barricadePositions) end
    local pts = {}
    local pt = Vector(self.center.position)
    local pos = barricadePositions[n]
    local rot = barricadeRotations[n]
    for i = 1, #pos do
        local p = pos[i]
        local r = rot[i]
        table.insert(pts, {
            position = pt +
                Vector(p):rotateOver('y', Vector(self.center.rotation).y) *
                self.width,
            rotation = self.center.rotation + Vector(r) * self.tilt
        })
    end
    return pts
end

return function(load)
    load.barricades = function()
        local barricades = {}

        function barricades:setup()
            local snaps = Snap.get {
                base = board,
                tags = {'Barricade', 'Spot'},
                zoned = {6, 6, 3}
            }
            for _, s in pairs(snaps) do
                Layout {
                    zone = s.zone,
                    pattern = Pattern.barricade {
                        center = s,
                        width = 0.4,
                        tilt = 15
                    }
                }
            end
            self.snaps = {}
            for i = 1, 25 do
                self.snaps[i] = {}
                for _, j in pairs({i - 1, i - 5, i + 1, i + 5}) do
                    self.snaps[i][j] = iter.find(snaps, function(s)
                        return iter.has(s.tags, 'e ' .. i .. ' ' .. j)
                    end)
                end
            end

            local layout = Layout {
                zone = Obj {tag = 'Barricade Area'},
                pattern = Pattern.rows {
                    corner = Snap.get{
                        base = board,
                        tags = {'Barricade', 'Barricade Area'}
                    }[1],
                    width = 8,
                    spreadH = 2.6,
                    spreadV = 0.41
                },
                sticky = true
            }
            return layout:insert(getObjectsWithTag('Barricade'))
        end

        function barricades:between(i, j)
            local snap = self.snaps[i][j]
            if not snap then return {} end
            local barricades = snap.zone.getObjects()

            return barricades
        end

        function barricades:alongPath(path)
            local b = {}
            for i = 2, #path do
                local new = self:between(path[i - 1], path[i])
                for _, n in ipairs(new) do table.insert(b, n) end
            end
            return b
        end

        local reserved = {}

        function barricades:install(i, j, n)
            return async(function()
                n = n or 1
                local snap = self.snaps[i][j]
                local existing = #snap.zone.getObjects()
                local storage = Obj {tag = 'Barricade Area'}
                local bs = iter.filter(storage.getObjects(), function(o)
                    return not reserved[o.guid]
                end)
                local layout = Layout.of(snap.zone)
                local installs = {}
                for i = existing + 1, n do
                    local b = table.remove(bs)
                    if b then
                        table.insert(installs, b)
                        reserved[b.guid] = true
                    end
                end
                layout:insert(installs):await()
                for _, b in pairs(installs) do
                    reserved[b.guid] = nil
                end
            end)
        end

        function barricades:remove(i, j, n)
            return async(function()
                n = n or 3
                local snap = self.snaps[i][j]
                local b = snap.zone.getObjects()
                n = math.min(n, #b)
                local removes = {}
                for i = 1, n do
                    table.insert(removes, Layout.remove(table.remove(b)))
                end
                async.par(removes):await()
            end)
        end

        function barricades:removeOnPath(path, n)
            return async(function()
                if n == 0 then return end
                n = n or 3
                local storage = Obj {tag = 'Barricade Area'}
                local layout = Layout.of(storage)
                local removes = {}
                for i = 2, #path do
                    if n == 0 then break end
                    local snap = self.snaps[path[i - 1]][path[i]]
                    local b = snap.zone.getObjects()
                    local r = math.min(n, #b)
                    for i = 1, r do
                        table.insert(removes, table.remove(b))
                    end
                    n = n - r
                end
                layout:insert(removes):await()
            end)
        end

        return barricades
    end
end
