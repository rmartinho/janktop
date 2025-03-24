local Obj = require("tts/obj")
local Display = require("tts/display")

return function(load)
    load.conditions = function(data)
        local conditions
        if data then
            conditions = Display.load(data)
        else
            conditions = Display {
                base = board,
                snapTag = 'Condition',
                locks = true,
            }
        end

        return conditions
    end
end
