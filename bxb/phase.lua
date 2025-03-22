local Obj = require("tts/obj")
local Track = require("tts/track")
local Tracker = require("tts/tracker")
local async = require("tts/async")

return function(load)
    load.phase = function(data)
        local factions = {
            Yellow = 'Workers',
            Orange = 'Prisoners',
            Green = 'Neighbors',
            Purple = 'Students'
        }
        local phases = {
            night = {
                {name = 'Police Ops', enter = doPoliceOps},
                {name = 'Dice Roll', enter = doDiceRoll}, {name = 'Action'}
            },
            day = {
                {name = 'Reaction', enter = startReaction, exit = endReaction},
                {
                    name = 'Liberation',
                    enter = startLiberation,
                    exit = endLiberation
                }, {name = 'Meeting', enter = startMeeting, exit = endMeeting},
                {name = 'Victory', enter = doVictory},
                {name = 'Countdown', enter = doCountdown}
            }
        }

        local dayTrack = Track {base = board, snapTag = 'Day'}
        local nightTrack = Track {base = board, snapTag = 'Night'}

        local phase
        if data then
            phase = Tracker.load(data)
        else
            phase = Tracker {
                marker = Obj.get {tag = 'Phase'},
                track = nightTrack
            }
        end

        phase.marker.setColorTint(turns:current())

        function phase:onStep(i)
            self.marker.setDescription(
                'Current Phase: ' .. self:phase(i).name .. '\n' ..
                    'Current Faction: ' .. factions[turns:current()])
        end

        function phase:onLoop()
            local color = turns:pass()
            if self:isNight() then
                if flame:color() == color then
                    self:rebind(dayTrack)
                else
                    self:reset(1)
                end
            elseif self:isDay() then
                flame:advance()
                self:rebind(nightTrack)
            end
            self.marker.setColorTint(color)
        end

        function phase:phase(i)
            local i = i or self:index()
            if i then
                return phases[self:isNight() and 'night' or 'day'][i]
            end
        end

        -- TODO robust checks
        function phase:isNight() return #self.track == #nightTrack end
        function phase:isDay() return #self.track == #dayTrack end

        function phase:advance()
            async(function()
                local i = self:index() or 0
                local phase = self:phase(i)
                if phase and phase.exit then phase:exit() end
                Tracker.advance(self)
                async.wait.rest(self.marker)
                phase = self:phase()
                if phase and phase.enter then
                    if phase:enter() then self:advance() end
                end
            end)
        end

        return phase
    end
end
