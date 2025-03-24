local Obj = require 'tts/obj'
local Discard = require 'tts/discard'
local Snap = require 'tts/snap'

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
    load.graffiti = function(data)
        local graffiti
        if data then
            graffiti = Discard.load(data)
        else
            graffiti = Discard {
                base = board,
                snapTag = 'Graffiti',
                locks = true
            }
        end
        return graffiti
    end
end
