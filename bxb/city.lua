local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local Graph = require 'tts/bxb/graph'
local iter = require 'tts/iter'
local async = require 'tts/async'

local dropOffset = Vector(0, 0.3, 0)

local terrainProps = {
    ['Highway'] = {priority = -1, difficulty = 100, highway = true},
    ['1 - Commercial (M)'] = {
        priority = 1,
        difficulty = 3,
        metro = true,
        adjacency = {0, 1, 1, 1}
    },
    ['2 - Commercial'] = {
        priority = 2,
        difficulty = 3,
        adjacency = {1, 1, 1, 1}
    },
    ['3 - Commercial'] = {
        priority = 3,
        difficulty = 3,
        adjacency = {1, 1, 1, 1}
    },
    ['4 - Prisoners - Overcrowded Jail (M)'] = {
        priority = 4,
        difficulty = 4,
        metro = true,
        adjacency = {0, 1, 1, 1}
    },
    ['5 - Workers - Garment Sweatshop (M)'] = {
        priority = 5,
        difficulty = 4,
        metro = true,
        adjacency = {0, 1, 1, 1}
    },
    ['6 - Students - Underfunded High School (M)'] = {
        priority = 6,
        difficulty = 4,
        metro = true,
        adjacency = {0, 1, 1, 1}
    },
    ['7 - Neighbors - Polluted Slum (M)'] = {
        priority = 7,
        difficulty = 4,
        metro = true,
        adjacency = {0, 1, 1, 1}
    },
    ['8 - Neighbors - The Projects'] = {
        priority = 8,
        difficulty = 5,
        adjacency = {1, 1, 1, 1}
    },
    ['9 - Students - Bankrupt Junior College'] = {
        priority = 9,
        difficulty = 5,
        adjacency = {1, 1, 1, 1}
    },
    ['10 - Workers - Smartphone Factory'] = {
        priority = 10,
        difficulty = 5,
        adjacency = {1, 1, 1, 1}
    },
    ['11 - Prisoners - Immigrant Detention Center'] = {
        priority = 11,
        difficulty = 5,
        adjacency = {1, 1, 1, 1}
    },
    ['12 - State - Financial District (M)'] = {
        priority = 12,
        difficulty = 6,
        metro = true,
        adjacency = {1, 1, 1, 1}
    },
    ['13 - State - Telecom Network Hub'] = {
        priority = 13,
        difficulty = 6,
        adjacency = {1, 1, 1, 1}
    },
    ['14 - State - International Airport'] = {
        priority = 14,
        difficulty = 6,
        adjacency = {1, 1, 1, 1}
    },
    ['15 - State - Interior Ministry'] = {
        priority = 15,
        difficulty = 6,
        adjacency = {1, 1, 1, 1}
    },
    ['16 - Students - Privatized University'] = {
        priority = 16,
        difficulty = 6,
        adjacency = {1, 1, 1, 1}
    },
    ['17 - Neighbors - Gentrifying Residential Zone'] = {
        priority = 15,
        difficulty = 6,
        adjacency = {1, 1, 1, 1}
    },
    ['18 - Prisoners - Supermax Prison'] = {
        priority = 18,
        difficulty = 6,
        adjacency = {1, 1, 1, 1}
    },
    ['19 - Workers - Global Shipping and Receiving Center'] = {
        priority = 19,
        difficulty = 6,
        adjacency = {1, 1, 1, 1}
    },
    ['20 - Public - Street Market'] = {
        priority = 20,
        difficulty = 4,
        adjacency = {1, 1, 1, 1}
    },
    ['21 - Public - Park'] = {
        priority = 21,
        difficulty = 4,
        adjacency = {1, 1, 1, 1}
    },
    ['22 - Public - Plaza'] = {
        priority = 22,
        difficulty = 4,
        adjacency = {1, 1, 1, 1}
    }
}

function layDistricts(city, deck, tag)
    local districtIndices = {
        A = {25, 22, 20, 17, 13, 9, 6, 4, 1},
        B = {23, 19, 16, 14, 11, 8, 5, 2},
        C = {24, 21, 18, 15, 12, 10, 7, 3}
    }
    return async(function()
        local snaps = tag and
                          iter.filter(city.snaps,
                                      function(s)
                return s:hasTag(tag)
            end) or city.snaps
        local rotation = nil
        local moved = {}
        local remainder = nil
        local districts = {}
        for _, s in pairs(snaps) do
            local rot
            local card
            if tag then
                rot = math.random(0, 3)
                rotation = {0, (rot + 2) * 90, 180}
            end
            local move
            if remainder then
                card = Obj.use(remainder)
                move = card:snapTo({position = s.position, rotation = rotation},
                                   dropOffset)
            else
                card = Obj.use(deck.takeObject {
                    position = Vector(s.position) + dropOffset,
                    rotation = rotation
                })
                move = async.rest(card)
            end
            remainder = deck.remainder
            table.insert(moved, move)
            if tag then
                local ix = table.remove(districtIndices[tag])
                city.districts[ix] = {
                    index = ix,
                    terrain = card,
                    rot = rot,
                    props = terrainProps[card.getName()]
                }
                districts[card.guid] = city.districts[ix]
            end
        end
        moved = async.par(moved):await()
        for _, c in pairs(moved) do
            c.setLock(true)
            if tag then
                local zone = spawnObject {
                    type = 'ScriptingTrigger',
                    position = c.getPosition(),
                    scale = {6, 6, 6}
                }
                zone.addTag('Liberation')
                zone.addTag('District')
                districts[c.guid].zone = zone
                districts[c.guid].liberation =
                    iter.find(zone.getObjects(),
                              function(o)
                        o.hasTag('Liberation')
                    end)
                local patterns = {}
                local blocSnap = Snap.get{base = c, tag = 'Bloc'}[1]
                if blocSnap then
                    zone.addTag('Bloc')
                    patterns.Bloc = Pattern.squares {
                        center = blocSnap,
                        spread = 0.6,
                        rotation = c.getRotation().y
                    }
                end
                local squadSnap = Snap.get{base = c, tag = 'Squad'}[1]
                if squadSnap then
                    zone.addTag('Squad')
                    patterns.Squad = Pattern.squares {
                        center = squadSnap,
                        spread = 0.6,
                        rotation = c.getRotation().y
                    }
                end
                local vanSnap = Snap.get {base = c, tag = 'Van'}
                if #vanSnap > 0 then
                    zone.addTag('Van')
                    patterns.Van = Pattern.fromSnaps(vanSnap)
                end
                local occupationSnap = Snap.get {base = c, tag = 'Occupation'}
                if #occupationSnap > 0 then
                    zone.addTag('Occupation')
                    patterns.Occupation = Pattern.fromSnaps(occupationSnap)
                end
                local graffitiSnap = Snap.get {
                    base = c,
                    tag = 'Graffiti',
                    allowFlip = false
                }
                if #graffitiSnap > 0 then
                    zone.addTag('Graffiti')
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
    self.districts = {}
end

function City:save() return {snaps = iter.map(self.snaps, Snap.save)} end

function City.load(data) return City {load = data} end

function City:setup()
    return async(function()
        local liberation = Obj {tag = 'Liberation'}
        liberation.shuffle()
        layDistricts(self, liberation):await()

        local districtsA = Obj {tags = {'District', 'A'}}
        districtsA.shuffle()
        local districtsB = Obj {tags = {'District', 'B'}}
        districtsB.shuffle()
        local districtsC = Obj {tags = {'District', 'C'}}
        districtsC.shuffle()

        async.par {
            liberation:leaveTowards{position = {-60, 30, 0}},
            layDistricts(self, districtsA, 'A'),
            layDistricts(self, districtsB, 'B'),
            layDistricts(self, districtsC, 'C')
        }:await()

        self.graph = Graph(self)
    end)
end

function City:adjacentTo(district)
    local adjacent = {}
    for _, n in ipairs(self.graph:adjacentTo(district.index)) do
        table.insert(adjacent, self.districts[n])
    end
    return adjacent
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

