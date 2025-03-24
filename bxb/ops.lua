local Discard = require 'tts/discard'

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

        return ops
    end
end
