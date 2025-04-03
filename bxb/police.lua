local Obj = require 'tts/obj'
local Discard = require 'tts/discard'
local Layout = require 'tts/layout'
local iter = require 'tts/iter'
local async = require 'tts/async'

return function(load)
    load.police = function(data)
        local police = {}

        function police:setup()
            return async(function()
                local staging = Obj {tag = 'Staging Area'}
                local objects = staging.getObjects()
                local vans = iter.filter(objects,
                                         function(o)
                    return o.hasTag('Van')
                end)
                local squads = iter.filter(objects, function(o)
                    return o.hasTag('Squad')
                end)
                local moves = {}
                for i = 1, 25 do
                    local d = city.districts[i]
                    if d.terrain.hasTag('State') then
                        local layout = Layout.of(d.zone)
                        local van = table.remove(vans)
                        local newSquads = {van}
                        for i = 1, 3 do
                            table.insert(newSquads, table.remove(squads))
                        end
                        table.insert(moves, layout:insert(newSquads))
                    end
                end
                async.par(moves):await()
                Layout.of(staging):layout(true)
            end)
        end

        return police
    end
end
