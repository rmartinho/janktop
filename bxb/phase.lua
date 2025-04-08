local Obj = require 'tts/obj'
local Track = require 'tts/track'
local Tracker = require 'tts/tracker'
local async = require 'tts/async'

local function doPoliceOps()
    return async(function()
        local steps = morale:steps()
        ops:deal():await()
        for i=2,steps do
            async.apause():await()
            ops:deal():await()
        end
        return true
    end)
end

local function doDiceRoll()
    return async(function()
        for _, f in pairs(factions) do
            local starter = Obj {tags = {'Faction Start', f}}
            local zone = starter.getZones()[1]
            local layout = Layout.of(zone)
            local blocZone = Obj {guid = starter.memo}
            local blocs = iter.filterTag(blocZone.getObjects(), 'Bloc')
            if #blocs > 0 and zone.guid ~= starter.memo then
                local bloc = table.remove(blocs)
                layout:insert(bloc):await()
            end
        end
        dice:roll():await()
        return true
    end)
end

local function doAction()
    return async(function()
        broadcastToColor('Perform your actions', turns:current())
        Ready.some(turns:current()):await()
        return true
    end)
end

local function doReaction()
    return async(function()
        reaction:deal():await()
        Ready.all():await()
        return true
    end)
end

local function doLiberation()
    return async(function()
        -- TODO
        Ready.all():await()
        return true
    end)
end

local function doMeeting()
    return async(function()
        meeting:conduct():await()
        return true
    end)
end

local function doVictory()
    return async(function()
        -- TODO
        broadcastToAll('Check win conditions')
        Ready.all():await()
        return true
    end)
end

local function doCountdown()
    return async(function()
        local steps = morale:steps()
        countdown:advance(steps)
        return true
    end)
end

return function(load)
    load.phase = function(data)
        local phases = {
            night = {
                {name = 'Police Ops', enter = doPoliceOps},
                {name = 'Dice Roll', enter = doDiceRoll}, 
                {name = 'Action', enter = doAction}
            },
            day = {
                {name = 'Reaction', enter = doReaction},
                {name = 'Liberation', enter = doLiberation},
                {name = 'Meeting', enter = doMeeting},
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
                        async.apause():await()
                        self:advance():await()
                    end
                end
            end)
        end

        return phase
    end
end
