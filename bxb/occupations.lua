local Obj = require 'tts/obj'
local Layout = require 'tts/layout'
local async = require 'tts/async'
local iter = require 'tts/iter'

return function(load)
    load.occupations = function(data)
        local occupations = {}

        local initialBlocs = {3, 3, 2, 1}

        local function form(occup, n)
            return async(function()
                n = n or 1
                local zone = occup.getZones()[1]
                local layout = Layout.of(zone)
                local blocZone = Obj {guid = occup.memo}
                local blocs = iter.filterTag(blocZone.getObjects(), 'Bloc')
                if #blocs > 0 and zone.guid ~= occup.memo then
                    n = math.min(n, #blocs)
                    local deployed = {}
                    for i = 1, n do
                        table.insert(deployed, table.remove(blocs))
                    end
                    layout:insert(deployed):await()
                end
            end)
        end

        function occupations:setup()
            local formations = {}
            for _, f in pairs(factions) do
                local starter = Obj {tags = {'Faction Start', f}}
                table.insert(formations,
                             form(starter, initialBlocs[#getSeatedPlayers()]))
                local district = city:districtOf(starter)
                for _, d in pairs(city:adjacentTo(district)) do
                    if d.terrain.hasTag('State') then
                        table.insert(formations, barricades:install(
                                         district.index, d.index, 3))
                    end
                end
            end
            return async.par(formations)
        end

        function occupations:activate(o)
            return async(function()
                if o.hasTag('Faction Start') then
                    -- TODO 
                elseif o.hasTag('Meeting Hall') then
                    -- TODO 
                elseif o.hasTag('Mutual Aid') then
                    -- TODO 
                end
            end)
        end

        return occupations
    end
end
