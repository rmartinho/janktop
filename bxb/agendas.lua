local Obj = require 'tts/obj'
local async = require 'tts/async'
local iter = require 'tts/iter'

local discardPosition = {-50, 30, 0}

return function(load)
    load.agendas = function(data)
        local agendas = {}

        function agendas:setup()
            return async(function()
                if gameMode == 'conflict' then
                    broadcastToAll(
                        'Conflict agendas: at least one player wins alone')
                elseif gameMode == 'cooperation' then
                    broadcastToAll('Cooperation agendas: everyone wins together')
                else
                    broadcastToAll(
                        'Standard agendas: maybe some players win alone')
                end

                local deck = Obj {tags = {'Agendas', 'Deck'}}
                if gameMode == 'conflict' then
                    deck:removeObjectsIf(discardPosition, function(card)
                        return not iter.has(card.tags, 'Conflict')
                    end):await()
                end
                if gameMode == 'cooperation' then
                    deck:leaveTowards{position = discardPosition}:await()
                else
                    deck.shuffle()
                    async.apause():await()
                    local cardColors = {
                        ['Vanguardist'] = Color(92 / 255, 176 / 255, 193 / 255),
                        ['Sectarian'] = Color(163 / 255, 99 / 255, 219 / 255),
                        ['Social'] = Color(251 / 255, 62 / 255, 86 / 255)
                    }
                    for _, player in pairs(getSeatedPlayers()) do
                        local card = deck.getObjects()[1]
                        deck.deal(1, player)
                        broadcastToColor(
                            'You have a ' .. card.name .. ' agenda', player,
                            cardColors[card.name])
                    end
                    deck = Obj.use(deck.remainder) or deck
                    deck:leaveTowards{position = discardPosition}:await()
                end
            end)
        end

        return agendas
    end
end
