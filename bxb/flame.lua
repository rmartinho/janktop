local Obj = require("tts/obj")
local Track = require("tts/track")
local Tracker = require("tts/tracker")

return function(load)
    load.flame = function(data)
        local flame
        if data then
            flame = Tracker.load(data)
        else
            flame = Tracker {
                marker = Obj.get {tag = 'Flame'},
                track = Track {snapTag = 'Flame', loop = true}
            }
            -- TODO trim track to player count 
        end

        function flame:color() return turns.players[self:index()] end

        function flame:onStep(i)
            self.marker.setDescription('First Faction: ' ..
                                           factions[turns:current()])
        end

        return flame
    end
end
