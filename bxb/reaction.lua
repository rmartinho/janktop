local Discard = require 'tts/discard'
local async = require 'tts/async'

return function(load)
    load.reaction = function(data)
        Color.Add('Metro Open', Color(0, 160 / 255, 192 / 255))
        Color.Add('Metro Lockdown', Color(238 / 255, 48 / 255, 73 / 255))

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
            return async(function()
                local deck = self:drawPile()
                local top = self:topOfDraw()
                self.metro = string.find(top.description, 'Metro Open')
                local _, e = string.find(top.description, 'Priority: ')
                self.priority = string.sub(top.description, e + 1, e + 1)
                local color = Color.fromString(
                                  self.metro and 'Metro Open' or
                                      'Metro Lockdown')
                broadcastToAll('The Metro is ' ..
                                   (self.metro and 'open' or 'in lockdown'),
                               color)
                for _, o in pairs(getObjectsWithTag('Metro Sign')) do
                    local otherState = o.getStates()[1]
                    if otherState.id == (self.metro and 1 or 2) then
                        o.setState(otherState.id)
                    end
                    o.highlightOff()
                    o.highlightOn(color)
                end
                if deck then deck.setDescription(top.description) end
            end)
        end

        return reaction
    end
end
