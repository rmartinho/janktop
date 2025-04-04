local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.dice = function()
        local dice = {}

        function dice:setup()
            local layout = Layout {
                zone = Obj {tag = 'Dice Area'},
                patterns = {
                    ['Active Die'] = Pattern.columns {
                        corner = Snap.get{base = board, tag = 'Active Die'}[1],
                        height = 5,
                        spread = -1.7
                    },
                    [''] = Pattern.pile {
                        point = Snap.get{base = board, tag = 'Bonus Die'}[1],
                        height = 1.7
                    }
                },
                preserveRotationValue = true
            }
            return layout:insert(getObjectsWithTag('Die'))
        end

        function dice:roll()
            local n = 3
            local faction = factions[turns:current()]
            local blocZone = factionZones[faction]
            local blocsLeft = iter.count(blocZone.getObjects(), function(b)
                return b.hasTag('Bloc')
            end)
            if blocsLeft < 6 then n = n + 1 end
            if blocsLeft < 2 then n = n + 1 end
            local zone = Obj {tag = 'Dice Area'}
            local dies = zone.getObjects()
            local toRoll = {}
            for i = 1, n do
                table.insert(toRoll, dies[i])
                dies[i].addTag('Active Die')
            end
            for i = n + 1, 5 do dies[i].removeTag('Active Die') end
            return async(function()
                Layout.of(zone):layout():await()
                async.par(iter.map(toRoll, function(d)
                    return async(function()
                        d.randomize()
                        async.rest(d):await()
                    end)
                end)):await()
                local rolls = ''
                for _, d in pairs(toRoll) do
                    if #rolls == 0 then
                        rolls = tostring(d.getValue())
                    else
                        rolls = rolls .. ' | ' .. d.getValue()
                    end
                end
                broadcastToAll('Action dice: ' .. rolls, turns:current())
            end)
        end

        return dice
    end
end
