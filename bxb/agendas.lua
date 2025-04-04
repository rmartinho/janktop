local Obj = require 'tts/obj'
local async = require 'tts/async'
local iter = require 'tts/iter'

local discardPosition = {-50, 30, 0}

return function(load)
    load.agendas = function(data)
        local agendas = {}

        function agendas:setup()
            if gameMode == 'conflict' then
                broadcastToAll(
                    'Conflict agendas: at least one player wins alone')
            elseif gameMode == 'cooperation' then
                broadcastToAll('Cooperation agendas: everyone wins together')
            else
                broadcastToAll('Standard agendas: maybe some players win alone')
            end

            local deck = Obj {tags = {'Agendas', 'Deck'}}
            if gameMode == 'conflict' then
                return deck:removeObjectsIf(discardPosition, function(card)
                    return not iter.has(card.tags, 'Conflict')
                end)
            end
            if gameMode == 'cooperation' then
                return deck:leaveTowards{position = discardPosition}
            else
                return async(function()
                    deck.shuffle()
                    deck.deal(1)
                    deck = Obj.use(deck.remainder) or deck
                    deck:leaveTowards{position = discardPosition}:await()
                end)
            end
        end

        return agendas
    end
end
