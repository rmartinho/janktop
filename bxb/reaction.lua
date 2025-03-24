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
            if deck then
                deck.setDescription(self:topOfDraw().description)
            end
        end

        return reaction
    end
end
