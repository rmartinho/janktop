local Discard = require 'tts/discard'
local async = require 'tts/async'

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

        local colors = {
            [true] = Color(0, 160 / 255, 192 / 255),
            [false] = Color(238 / 255, 48 / 255, 73 / 255)
        }

        function reaction:onTopChanged()
            return async(function()
                local deck = self:drawPile()
                local top = self:topOfDraw()
                self.metro = string.find(top.description, 'Metro Open')
                local _, e = string.find(top.description, 'Priority: ')
                self.priority = string.sub(top.description, e + 1, e + 1)
                local color = colors[self.metro and true or false]
                broadcastToAll('The Metro is ' ..
                                   (self.metro and 'open' or 'in lockdown'),
                               color)
                for _, o in pairs(getObjectsWithTag('Metro Sign')) do
                    local otherState = o.getStates()[1]
                    if otherState.id == (self.metro and 1 or 2) then
                        o.setState(otherState.id)
                    end
                end
                if deck then deck.setDescription(top.description) end
            end)
        end

        return reaction
    end
end
