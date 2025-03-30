local Discard = require 'tts/discard'

return function(load)
    load.reaction = function(data)
        local reaction
        if data then
            reaction = Discard.load(data)
        else
            reaction = Discard {
                base = board,
                snapTag = 'Metro',
                flip = true,
                refresh = true,
                locks = true
            }
        end

        function reaction:onTopChanged()
            local deck = self:drawPile()
            local top = self:topOfDraw()
            self.metro = string.find(top.description, 'Metro Open')
            local _, e = string.find(top.description, 'Priority: ')
            self.priority = string.sub(top.description, e + 1, e + 1)
            broadcastToAll('The Metro is ' ..
                               (self.metro and 'open' or 'in lockdown'))
            if deck then deck.setDescription(top.description) end
        end

        return reaction
    end
end
