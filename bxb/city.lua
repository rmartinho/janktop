local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local iter = require 'tts/iter'
local async = require 'tts/async'

local dropOffset = Vector(0, 0.2, 0)

local districtIndices = {
    A = {1, 4, 6, 9, 13, 17, 20, 22, 25},
    B = {2, 5, 8, 11, 14, 16, 19, 23},
    C = {3, 7, 10, 12, 15, 18, 21, 24}
}

function layDistricts(city, deck, tag, rotate)
    async(function()
        local snaps = tag and
                          iter.filter(city.snaps,
                                      function(s)
                return s:hasTag(tag)
            end) or city.snaps
        local rotation = nil
        local moved = {}
        local remainder = nil
        for _, s in pairs(snaps) do
            if rotate then
                rotation = {0, math.random(0, 3) * 90, 180}
            end
            local card
            if remainder then
                card = remainder
                Obj.use(card):snapTo({
                    position = s.position,
                    rotation = rotation
                }, dropOffset)
            else
                card = deck.takeObject {
                    position = Vector(s.position) + dropOffset,
                    rotation = rotation
                }
            end
            remainder = deck.remainder
            async.wait()
            table.insert(moved, card)
        end
        for _, c in pairs(moved) do
            async.wait.rest(c)
            c.setLock(true)
            if rotate then
                local zone = spawnObject {
                    type = 'ScriptingTrigger',
                    position = c.getPosition(),
                    scale = {6, 6, 6}
                }
                local patterns = {}
                local blocSnap = Snap.get{base = c, tag = 'Bloc'}[1]
                if blocSnap then
                    patterns.Bloc = Pattern.squares {
                        center = blocSnap,
                        spread = 0.6,
                        rotation = c.getRotation().y
                    }
                end
                local squadSnap = Snap.get{base = c, tag = 'Squad'}[1]
                if squadSnap then
                    patterns.Squad = Pattern.squares {
                        center = squadSnap,
                        spread = 0.6,
                        rotation = c.getRotation().y
                    }
                end
                local vanSnap = Snap.get {base = c, tag = 'Van'}
                if #vanSnap > 0 then
                    patterns.Van = Pattern.fromSnaps(vanSnap)
                end
                local occupationSnap = Snap.get {base = c, tag = 'Occupation'}
                if #occupationSnap > 0 then
                    patterns.Occupation = Pattern.fromSnaps(occupationSnap)
                end
                local graffitiSnap = Snap.get {
                    base = c,
                    tag = 'Graffiti',
                    allowFlip = false
                }
                if #graffitiSnap > 0 then
                    patterns.Graffiti = Pattern.fromSnaps(graffitiSnap)
                end
                local layout = Layout {zone = zone, patterns = patterns}
            end
        end
    end)
end

local City = Object:extend('City')

function City:new(params)
    params = params or {}
    if params.load then
        self.snaps = iter.map(params.load.snaps, Snap.load)
    else
        self.snaps = Snap.get {
            base = params.base,
            tag = params.tag,
            zoned = true
        }
    end
end

function City:save() return {snaps = iter.map(self.snaps, Snap.save)} end

function City.load(data) return City {load = data} end

function City:setup()
    async(function()
        local liberation = Obj.get {tag = 'Liberation'}
        liberation.shuffle()
        layDistricts(self, liberation)
        async.fork(function()
            async(function()
                liberation:snapTo({position = {-40, 30, 0}})
                async.pause()
                liberation.destroy()
            end)

            local districtsA = Obj.get {tags = {'District', 'A'}}
            districtsA.shuffle()
            layDistricts(self, districtsA, 'A', true)
            local districtsB = Obj.get {tags = {'District', 'B'}}
            districtsB.shuffle()
            layDistricts(self, districtsB, 'B', true)
            local districtsC = Obj.get {tags = {'District', 'C'}}
            districtsC.shuffle()
            layDistricts(self, districtsC, 'C', true)
        end)
        async.pause()
    end)
end

return function(load)
    load.city = function(data)
        local city
        if data then
            city = City.load(data)
        else
            city = City {base = board, tag = 'District'}
        end

        return city
    end
end

