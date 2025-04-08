local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.meeting = function(data)
        local meeting = {}

        function meeting:setup()
            return async(function()
                self.layout = Layout {
                    zone = Obj {tag = 'Meeting'},
                    pattern = Pattern.fromSnaps(Snap.get {
                        base = Obj {tags = {'Condition', 'Deck'}},
                        tag = 'Meeting'
                    })
                }
                self.scrap = Layout {
                    zone = Obj {tag = 'Meeting Exit'},
                    pattern = Pattern.columns {
                        corner = Snap.get{base = board, tag = 'Meeting Exit'}[1],
                        height = 11,
                        spread = 0.41
                    }
                }
            end)
        end

        function meeting:conduct()
            return async(function()
                local attendants = self.layout.zone.getObjects()
                if #attendants == 0 then return end
                local attendingColors = {}
                for f, c in pairs(factions) do
                    for _, bloc in pairs(attendants) do
                        if bloc.hasTag(f) then
                            attendingColors[c] = true
                            break
                        end
                    end
                end
                while true do
                    local needs = conditions:count()
                    if needs > #attendants then break end
                    local removed = {}
                    for i = 1, needs do
                        table.insert(removed, table.remove(attendants))
                    end
                    async.par {self.scrap:insert(removed), conditions:deal()}:await()
                end
                self.scrap:insert(attendants):await()
                local players = {}
                for _, p in pairs(getSeatedPlayers()) do
                    if attendingColors[p] then
                        broadcastToColor(
                            'Return your meeting blocs to a district you occupy',
                            p, Color.fromString(factions[p]))
                        table.insert(players, p)
                    end
                end
                Ready.some(players):await()
            end)
        end

        return meeting
    end
end
