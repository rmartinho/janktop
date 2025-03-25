local Discard = require 'tts/discard'
local iter = require 'tts/iter'
local async = require 'tts/async'

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
            async(function()
                Discard.setup(self)
                local expectedTag = {
                    Easy = difficulty == 1,
                    Medium = difficulty == 2,
                    Hard = difficulty == 3,
                    Expert = difficulty == 4
                }

                self:drawPile():removeObjectsIf(self.discard.position,
                                                function(card)
                    return not iter.any(card.tags,
                                        function(t)
                        return expectedTag[t]
                    end)
                end)
            end)
        end

        return ops
    end
end
