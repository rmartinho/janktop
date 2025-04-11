local Obj = require 'tts/obj'
local Discard = require 'tts/discard'
local Layout = require 'tts/layout'
local iter = require 'tts/iter'
local async = require 'tts/async'
local Ready = require 'tts/ready'

local function highestOf(candidates)
    local best = {props = {priority = 0}}
    for _, c in ipairs(candidates) do
        if c.props.priority > best.props.priority then best = c end
    end
    return best.index and best or nil
end

local function lowestOf(candidates)
    local best = {props = {priority = 1000}}
    for _, c in ipairs(candidates) do
        if c.props.priority < best.props.priority then best = c end
    end
    return best.index and best or nil
end

local function squadsIn(zone)
    return iter.filter(zone.getObjects(),
                       function(o) return o.hasTag('Squad') end)
end

local function vanIn(zone)
    return iter.find(zone.getObjects(), function(o) return o.hasTag('Van') end)
end

local function advanceSquadsTo(tag)
    return Ready.all()
end

local function XXXadvanceSquadsToXXX(tag)
    local criteria = (tag == 'highest' or reaction.priority == 'H') and
                         highestOf or lowestOf

    local movements = {}
    local dismantles = {}
    for _, source in ipairs(city.districts) do
        local squads = squadsIn(source.zone)
        local hasOccupation = iter.find(source.zone.getObjects(), function(o)
            return o.hasTag('Occupation')
        end)
        if #squads > 1 and not hasOccupation then
            local target = criteria(iter.filter(city:adjacentTo(source),
                                                function(d)
                if tag == 'highest' then
                    return true
                elseif tag == 'blocs' then
                    return iter.find(d.zone.getObjects(),
                                     function(o)
                        return o.hasTag('Bloc')
                    end)
                elseif tag == 'occupations' then
                    return iter.find(d.zone.getObjects(), function(o)
                        return o.hasTag('Occupation')
                    end)
                else
                    return d.terrain.hasTag(tag)
                end
            end))
            if target then
                local b = barricades:between(source.index, target.index)
                local movingSquads = {table.unpack(squads)}
                table.remove(movingSquads)
                local blocked = math.min(b >= 3 and 999 or b, #movingSquads)
                local dismantled = math.min(blocked, 3)
                for i = 1, blocked do table.remove(movingSquads) end
                dismantles[source.index] = {to = target.index, n = dismantled}
                movements[source.index] = {
                    to = target.index,
                    squads = movingSquads,
                    barricades = dismantled
                }
            end
        end
    end

    return async(function()
        for from, m in pairs(movements) do
            local d = dismantles[from]
            local layout = Layout.of(city.districts[m.to].zone)
            async.par {
                barricades:remove(from, d.to, d.n), layout:insert(m.squads)
            }:await()
        end
    end)
end

local function rotateSquads()
    local moves = {}
    for i = 1, 25 do
        local d = city.districts[i]
        local squads = squadsIn(d.zone)
        for i = 6, #squads do
            table.insert(moves, Layout.remove(squads[i]))
        end
    end
    return async.par(moves)
end

local function deployInZone(zone, obj)
    return async(function()
        local l = Layout.of(zone)
        l:insert{obj}:await()
    end)
end

local function reinforce()
    local staging = Obj {tag = 'Staging Area'}
    local squads = squadsIn(staging)
    return async.par(iter.filterMap(city.districts, function(d)
        local van = vanIn(d.zone)
        if van then return deployInZone(d.zone, table.remove(squads)) end
    end))
end

local function replaceVan()
    return async(function()
        local staging = Obj {tag = 'Staging Area'}
        local newVan = vanIn(staging)
        if not newVan then return end
        local district = highestOf(iter.filter(city.districts, function(d)
            return not vanIn(d.zone) and #squadsIn(d.zone) > 0
        end))
        if district then deployInZone(district.zone, newVan):await() end
    end)
end

local cardActions = {
    ['Advance to State Districts'] = function()
        return advanceSquadsTo('State')
    end,
    ['Advance to Commercial Districts'] = function()
        return advanceSquadsTo('Commercial')
    end,
    ['Advance to Public Districts'] = function()
        return advanceSquadsTo('Public')
    end,
    ['Advance to Neighbors Districts'] = function()
        return advanceSquadsTo('Neighbors')
    end,
    ['Advance to Workers Districts'] = function()
        return advanceSquadsTo('Workers')
    end,
    ['Advance to Students Districts'] = function()
        return advanceSquadsTo('Students')
    end,
    ['Advance to Prisoners Districts'] = function()
        return advanceSquadsTo('Prisoners')
    end,
    ['District Patrols'] = function() return advanceSquadsTo('highest') end,
    ['Snatch Squads'] = function()
        return async(function()
            morale:advance():await()
            advanceSquadsTo('blocs'):await()
        end)
    end,
    ['Paramilitary Raids'] = function()
        return async(function()
            morale:advance():await()
            advanceSquadsTo('occupations'):await()
        end)
    end,
    ['Strategic Rotation'] = function() return rotateSquads() end,
    ['Light Reinforcements'] = function()
        return async(function()
            morale:advance():await()
            reinforce():await()
        end)
    end,
    ['Heavy Reinforcements'] = function()
        return async(function()
            morale:advance():await()
            reinforce():await()
            replaceVan():await()
        end)
    end
}

return function(load)
    load.ops = function(data)
        local ops
        if data then
            ops = Discard.load(data)
        else
            ops = Discard {
                base = board,
                snapTag = 'Police Ops',
                flip = true,
                refresh = true,
                locks = true
            }
        end

        function ops:setup()
            return async(function()
                local difficultyNames = {'Easy', 'Medium', 'Hard', 'Expert'}
                broadcastToAll(difficultyNames[difficulty] .. ' mode (' ..
                                   difficulty .. ' Heavy Reinforcements)')

                local expectedTag = {
                    Easy = difficulty == 1,
                    Medium = difficulty == 2,
                    Hard = difficulty == 3,
                    Expert = difficulty == 4
                }

                local deck = Obj {tags = {'Police Ops', 'Deck'}}
                deck:removeObjectsIf({-60, 30, 0}, function(card)
                    return not iter.any(card.tags,
                                        function(t)
                        return expectedTag[t]
                    end)
                end):await()
                Discard.setup(self):await()
            end)
        end

        function ops:onDeal(card)
            return async(function()
                broadcastToAll('Police Ops: ' .. card.getName())
                local f = cardActions[card.getName()]
                f():await()
                -- Ready.all():await()
            end)
        end

        return ops
    end
end
