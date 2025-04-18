local Obj = require 'tts/obj'
local Track = require 'tts/track'
local Tracker = require 'tts/tracker'
local async = require 'tts/async'

return function(load)
    load.morale = function(data)
        local titles = {'Timid', 'Alert', 'Bold', 'Brutal', 'Deadly'}
        local steps = {1, 2, 2, 2, 3}

        local morale
        if data then
            morale = Tracker.load(data)
        else
            morale = Tracker {
                marker = Obj {tag = 'Police Morale'},
                track = Track {base = board, snapTag = 'Police Morale'}
            }
        end

        function morale:steps() return steps[self:index()] end

        function morale:onStep(i)
            return async(function()
                broadcastToAll('Police Morale is ' .. titles[i] .. ' (' ..
                                   steps[i] .. ')')
                self.marker.setDescription(
                    'Police Morale: ' .. titles[i] .. '\n' ..
                        'Ops cards per turn: ' .. steps[i] .. '\n' ..
                        'Countdown steps per round: ' .. steps[i])
            end)
        end

        return morale
    end
end
