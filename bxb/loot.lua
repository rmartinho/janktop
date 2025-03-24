local Obj = require("tts/obj")
local Discard = require("tts/discard")

return function(load)
    load.loot = function(data)
        local loot
        if data then
            loot = Discard.load(data)
        else
            loot = Discard {
                base = board,
                snapTag = 'Loot',
                flip = true,
                refresh = true,
                locks = true
            }
        end

        return loot
    end
end
