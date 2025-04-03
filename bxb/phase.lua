local Obj = require 'tts/obj'
local Track = require 'tts/track'
local Tracker = require 'tts/tracker'
local async = require 'tts/async'

function doPoliceOps() return ops:deal() end

return function(load)
    load.phase = function(data)
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

        function phase:setup()
            return async(function()
                self.marker.setColorTint(turns:current())
                Tracker.setup(self):await()
                local phase = self:phase()
                if phase and phase.enter then
                    if phase:enter():await() then
                        self:advance():await()
                    end
                end
            end)
        end

        function phase:onStep(i)
            self.marker.setDescription(
                'Current Phase: ' .. self:phase(i).name .. '\n' ..
                    'Current Faction: ' .. factions[turns:current()])
        end

        function phase:onLoop()
            return async(function()
                local color = turns:pass()
                self.marker.setColorTint(color)
                if self:isNight() then
                    if flame:color() == color then
                        self:rebind(dayTrack):await()
                    else
                        self:reset(1):await()
                    end
                elseif self:isDay() then
                    flame:advance():await()
                    self:rebind(nightTrack):await()
                end
            end)
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
            return async(function()
                local i = self:index() or 0
                local phase = self:phase(i)
                if phase and phase.exit then phase:exit():await() end
                Tracker.advance(self):await()
                phase = self:phase()
                if phase and phase.enter then
                    if phase:enter():await() then
                        self:advance():await()
                    end
                end
            end)
        end

        return phase
    end
end
