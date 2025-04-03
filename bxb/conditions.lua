local Obj = require 'tts/obj'
local Display = require 'tts/display'
local Snap = require 'tts/snap'
local async = require 'tts/async'

return function(load)
    load.conditions = function(data)
        local conditions
        if data then
            conditions = Display.load(data)
        else
            conditions = Display {
                base = board,
                snapTag = 'Condition',
                locks = true
            }
        end

        function conditions:onDeal(card)
            return async(function()
                broadcastToAll('New condition: ' .. card.getName())
                Snap.get {base = card, tag = 'Flag', zoned = true}
            end)
        end

        function conditions:setup()
            return async(function()
                Display.setup(self):await()
                self:deal():await()
            end)
        end

        return conditions
    end
end
