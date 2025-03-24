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
            graffiti = Obj.load(data)
        else
            graffiti = Obj.get {tag = 'Graffiti'}
            function graffiti:setup()
                local snap = Snap.get{base = board, tag = 'Graffiti'}[1]
                graffiti:snapTo(snap)
            end
        end
        return graffiti
    end
end
