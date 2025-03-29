local Discard = require 'tts/discard'
local iter = require 'tts/iter'
local async = require 'tts/async'

function advanceSquadsTo(tag) print('advancing to ', tag) end
function reduceSquadGroupsTo(n) print('reducing to ', n) end

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
        advanceSquadsTo('occupactions')
    end,
    ['Strategic Rotation'] = function() reduceSquadGroupsTo(5) end,
    ['Light Reinforcements'] = function()
        morale:advance()
        print('Light reinforcements')
    end,
    ['Heavy Reinforcements'] = function()
        morale:advance()
        print('heavy reinforcements')
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
            local difficultyNames = {'Easy', 'Medium', 'Hard', 'Expert'}
            broadcastToAll('Police difficulty set to ' ..
                               difficultyNames[difficulty] ..
                               ' (Heavy Reinforcements: ' .. difficulty .. ')')

            Obj.get {tags = {'Police Ops', 'Deck'}}:removeObjectsIf(
                self.discard.position, function(card)
                    return not iter.any(card.tags,
                                        function(t)
                        return expectedTag[t]
                    end)
                end)
            async(function() Discard.setup(self) end)
        end

        function ops:onTopChanged()
            local card = self:topOfDiscard()
            broadcastToAll('Resolving Police Ops: ' .. card.getName())
            local f = cardActions[card.getName()]
            f()
        end

        return ops
    end
end
