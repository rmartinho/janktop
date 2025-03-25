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
                    deck:removeObjectsIf(discardPosition, function(card)
                        return not iter.has(card.tags, 'Conflict')
                    end)
                end
                if gameMode == 'cooperation' then
                    async(function()
                        deck:snapTo{position = discardPosition}
                        async.pause()
                        deck.destroy()
                    end)
                else
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
