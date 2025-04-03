local Turns = require 'tts/turns'
local async = require 'tts/async'

return function(load)
    load.turns = function(data)
        local turns
        if data then
            turns = Turns.load(data)
        else
            turns = Turns {random = true}
        end

        return turns
    end
end
