local Obj = require 'tts/obj'
local async = require 'tts/async'
local iter = require 'tts/iter'

return function(load)
    load.agendas = function(data)
        local agendas = {
            setup = function()
                local discardPosition = {-50, 30, 0}
                local deck = Obj.get {tags = {'Agendas', 'Deck'}}
                if gameMode =='conflict' then
                    broadcastToAll('Conflict mode agendas: at least one player wins alone')
                    deck:removeObjectsIf(discardPosition, function(card)
                        return not iter.has(card.tags, 'Conflict')
                    end)
                end
                if gameMode == 'cooperation' then
                    broadcastToAll('Cooperation mode agendas: everyone wins together')
                    async(function()
                        deck:snapTo{position = discardPosition}
                        async.pause()
                        deck.destroy()
                    end)
                else
                    broadcastToAll('Standard mode agendas: it is possible some players win alone')
                    async(function()
                    deck.shuffle()
                    async.wait()
                    deck.deal(1)
                    deck = Obj.use(deck.remainder) or deck
                    async.wait()
                    deck:snapTo(discardPosition)
                    async.pause()
                    end)
                end
            end
        }

        return agendas
    end
end
