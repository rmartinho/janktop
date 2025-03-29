local Obj = require 'tts/obj'
local Track = require 'tts/track'
local Tracker = require 'tts/tracker'

return function(load)
    load.morale = function(data)
        local titles = {'Timid', 'Alert', 'Bold', 'Brutal', 'Deadly'}
        local steps = {1, 2, 2, 2, 3}

        local morale
        if data then
            morale = Tracker.load(data)
        else
            morale = Tracker {
                marker = Obj.get {tag = 'Police Morale'},
                track = Track {base = board, snapTag = 'Police Morale'}
            }
        end

        function morale:steps() return steps[self:index()] end

        function morale:onStep(i)
            broadcastToAll('Police Morale is now ' .. titles[i] .. ' (' ..
                               steps[i] .. ')')
            self.marker.setDescription('Police Morale: ' .. titles[i] .. '\n' ..
                                           'Ops cards per turn: ' .. steps[i] ..
                                           '\n' .. 'Countdown steps per round: ' ..
                                           steps[i])
        end

        return morale
    end
end
