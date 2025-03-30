local Obj = require 'tts/obj'
local Discard = require 'tts/discard'
local Layout = require 'tts/layout'
local iter = require 'tts/iter'
local async = require 'tts/async'

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
    local criteria = (tag == 'highest' or reaction.priority == 'H') and
                         highestOf or lowestOf

    local movements = {}
    for _, source in ipairs(city.districts) do
        local squads = squadsIn(source.zone)
        if #squads > 1 then
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
                local movingSquads = {table.unpack(squads)}
                table.remove(movingSquads)
                movements[target.index] = movements[target.index] or {}
                for _, s in ipairs(movingSquads) do
                    table.insert(movements[target.index], s)
                end
            end
        end
    end

    async(function()
        for i, squads in pairs(movements) do
            async.fork(function()
                Layout.of(city.districts[i].zone):insert(squads)
            end)
            async.wait()
            async.wait(function()
                return iter.all(squads, function(s)
                    return s.resting
                end)
            end)
        end
    end)
end

local function rotateSquads()
    for i = 1, 25 do
        local d = city.districts[i]
        local squads = squadsIn(d.zone)
        for i = 6, #squads do Layout.remove(squads[i]) end
    end
end

local function deployInZone(zone, obj)
    local l = Layout.of(zone)
    Wait.frames(function() l:insert({obj}) end)
end

local function reinforce()
    local staging = Obj.get {tag = 'Staging Area'}
    local squads = squadsIn(staging)
    for _, d in ipairs(city.districts) do
        local van = vanIn(d.zone)
        if van then deployInZone(d.zone, table.remove(squads)) end
    end
end

local function replaceVan()
    local staging = Obj.get {tag = 'Staging Area'}
    local newVan = vanIn(staging)
    if not newVan then return end
    local district = highestOf(iter.filter(city.districts, function(d)
        return not vanIn(d.zone) and #squadsIn(d.zone) == 0
    end))
    deployInZone(district.zone, newVan)
end

local cardActions = {
    ['Advance to State Districts'] = function() advanceSquadsTo('State') end,
    ['Advance to Commercial Districts'] = function()
        advanceSquadsTo('Commercial')
    end,
    ['Advance to Public Districts'] = function() advanceSquadsTo('Public') end,
    ['Advance to Neighbors Districts'] = function()
        advanceSquadsTo('Neighbors')
    end,
    ['Advance to Workers Districts'] = function() advanceSquadsTo('Workers') end,
    ['Advance to Students Districts'] = function()
        advanceSquadsTo('Students')
    end,
    ['Advance to Prisoners Districts'] = function()
        advanceSquadsTo('Prisoners')
    end,
    ['District Patrols'] = function() advanceSquadsTo('highest') end,
    ['Snatch Squads'] = function()
        morale:advance()
        advanceSquadsTo('blocs')
    end,
    ['Paramilitary Raids'] = function()
        morale:advance()
        advanceSquadsTo('occupations')
    end,
    ['Strategic Rotation'] = function() rotateSquads() end,
    ['Light Reinforcements'] = function()
        morale:advance()
        reinforce()
    end,
    ['Heavy Reinforcements'] = function()
        morale:advance()
        reinforce()
        replaceVan()
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
            local expectedTag = {
                Easy = difficulty == 1,
                Medium = difficulty == 2,
                Hard = difficulty == 3,
                Expert = difficulty == 4
            }

            Obj.get {tags = {'Police Ops', 'Deck'}}:removeObjectsIf(
                self.discard.position, function(card)
                    return not iter.any(card.tags,
                                        function(t)
                        return expectedTag[t]
                    end)
                end)
            Discard.setup(self)
        end

        function ops:onTopChanged()
            local card = self:topOfDiscard()
            if card then
                broadcastToAll('Resolving Police Ops: ' .. card.getName())
                local f = cardActions[card.getName()]
                f()
            end
        end

        return ops
    end
end
