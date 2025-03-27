local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

local function throwOff(o)
    async(function()
        o:snapTo({position = {60, 50, 0}})
        async.pause()
        o.destroy()
    end)
end

return function(load)
    load.playerBoards = function()
        local playerBoards = {}

        function playerBoards:setup()
            factionOrder = {}
            local delivered = {}
            for i = 1, #turns.players do
                local faction = factions[turns.players[i]]
                local board = Obj.get {tags = {'Player Board', faction}}
                local snap = Snap.get {tags = {'Player Board', 'n' .. i}}
                delivered[faction] = true
                factionOrder[faction] = i
                async(function()
                    board:snapTo(snap[1])
                    async.wait.rest(board)
                    local layout = Layout {
                        zone = Obj.get {tags = {'Player Staging', 'n' .. i}},
                        patterns = {
                            ['Bloc'] = Pattern.fromSnaps(Snap.get {
                                base = board,
                                tag = 'Bloc'
                            }),
                            ['Flag'] = Pattern.fromSnaps(Snap.get {
                                base = board,
                                tag = 'Flag'
                            }),
                            ['Faction Start'] = Pattern.fromSnaps(Snap.get {
                                base = board,
                                tag = 'Faction Start'
                            }),
                            ['Meeting Hall'] = Pattern.pile {
                                point = Snap.get{
                                    base = board,
                                    tag = 'Meeting Hall'
                                }[1],
                                height = 1
                            },
                            ['Mutual Aid'] = Pattern.pile {
                                point = Snap.get{
                                    base = board,
                                    tag = 'Mutual Aid'
                                }[1],
                                height = 1
                            }
                        },
                        sticky = true
                    }
                    async.fork(function()
                        layout:put(getObjectsWithAllTags({'Bloc', faction}))
                        layout:put(getObjectsWithAllTags({'Flag', faction}))
                        layout:put(
                            getObjectsWithAllTags({'Occupation', faction}))
                    end)
                end)
            end

            for _, f in pairs(factions) do
                if not delivered[f] then
                    async.fork(function()
                        local board = Obj.get {tags = {'Player Board', f}}
                        throwOff(board)
                        for _, o in pairs(getObjectsWithAllTags({'Bloc', f})) do
                            throwOff(Obj.use(o))
                        end
                        for _, o in pairs(getObjectsWithAllTags({'Flag', f})) do
                            throwOff(Obj.use(o))
                        end
                        for _, o in pairs(
                                        getObjectsWithAllTags({'Occupation', f})) do
                            throwOff(Obj.use(o))
                        end
                    end)

                end
            end
        end

        return playerBoards
    end
end
