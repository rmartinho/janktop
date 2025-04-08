local Obj = require 'tts/obj'
local Track = require 'tts/track'
local Tracker = require 'tts/tracker'
local async = require 'tts/async'

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
        end

        function flame:setup()
            return async(function()
                Tracker.setup(self, turns.i):await()
                for i = #turns.players + 1, #self.track do
                    table.remove(self.track.points)
                end
            end)
        end

        function flame:color() return turns.players[self:index()] end

        function flame:onStep(i)
            broadcastToAll('First faction is ' .. factions[turns:current()],
                           Color.fromString(factions[turns:current()]))
            self.marker.setDescription('First Faction: ' ..
                                           factions[turns:current()])
        end

        return flame
    end
end
