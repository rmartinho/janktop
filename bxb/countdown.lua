local Obj = require 'tts/obj'
local Track = require 'tts/track'
local Tracker = require 'tts/tracker'
local async = require 'tts/async'

return function(load)
    load.countdown = function(data)
        local countdown
        if data then
            countdown = Tracker.load(data)
        else
            countdown = Tracker {
                marker = Obj {tag = 'Countdown'},
                track = Track {base = board, snapTag = 'Countdown'}
            }
        end

        local function announce(self)
            local remain = #self.track - self:index()
            local description = 'GAME OVER'
            if remain > 0 then
                description =
                    remain .. ' night' .. (remain == 1 and '' or 's') ..
                        ' remaining!'
            end
            broadcastToAll(description)
        end

        function countdown:onStep(i)
            self.marker.setDescription(description)
        end

        function countdown:setup()
            return async(function()
                Tracker.setup(self):await()
                announce(self)
            end)
        end

        function countdown:advance(n)
            return async(function()
                for i = 1, n do Tracker.advance(self):await() end
                announce(self)
            end)
        end

        return countdown
    end
end
