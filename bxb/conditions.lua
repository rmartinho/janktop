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

        function conditions:deal()
            async(function()
                local card = Display.deal1(self)
                async.wait.rest(card)
                Snap.get {base = card, tag = 'Flag', zoned = true}
            end)
        end

        function conditions:setup()
            async(function()
                Display.setup(self)
                self:deal()
            end)
        end

        return conditions
    end
end
