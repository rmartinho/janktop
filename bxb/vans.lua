local Obj = require 'tts/obj'
local Discard = require 'tts/discard'
local Layout = require 'tts/layout'
local iter = require 'tts/iter'
local async = require 'tts/async'

return function(load)
    load.vans = function(data)
        local vans = {}

        function vans:setup()
            local staging = Obj.get {tag = 'Staging Area'}

            local objects = staging.getObjects()
            local vans = iter.filter(objects,
                                     function(o)
                return o.hasTag('Van')
            end)
            local squads = iter.filter(objects,
                                       function(o)
                return o.hasTag('Squad')
            end)
            for i = 1, 25 do
                local d = city.districts[i]
                if d.terrain.hasTag('State') then
                    local layout = Layout.of(d.zone)
                    local van = table.remove(vans)
                    local newSquads = {van}
                    for i = 1, 3 do
                        table.insert(newSquads, table.remove(squads))
                    end
                    async.fork(function()
                        layout:insert(newSquads)
                    end)
                end
            end
            Wait.frames(function() Layout.of(staging):layout(true) end, 10)
        end

        return vans
    end
end
