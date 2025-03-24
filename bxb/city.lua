local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local iter = require 'tts/iter'
local async = require 'tts/async'

local dropOffset = Vector(0, 0.5, 0)

function layDistricts(deck, tag, rotate)
    local snaps = tag and
                      iter.filter(city.snaps,
                                  function(s) return s:hasTag(tag) end) or
                      city.snaps
    local rotation = nil
    local moved = {}
    local remainder = nil
    for _, s in pairs(snaps) do
        if rotate then rotation = {0, math.random(0, 3) * 90, 180} end
        local card
        if remainder then
            card = remainder
            Obj.use(card):snapTo({position = s.position, rotation = rotation},
                                 dropOffset)
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
    end
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
        layDistricts(liberation)
        async.fork(function()
            async(function()
                liberation:snapTo({position = {-40, 30, 0}})
                async.wait(10)
                liberation.destroy()
            end)
        end)
        local districtsA = Obj.get {tags = {'District', 'A'}}
        layDistricts(districtsA, 'A', true)
        local districtsB = Obj.get {tags = {'District', 'B'}}
        layDistricts(districtsB, 'B', true)
        local districtsC = Obj.get {tags = {'District', 'C'}}
        layDistricts(districtsC, 'C', true)
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

