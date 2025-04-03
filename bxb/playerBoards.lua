local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'
local iter = require 'tts/iter'

local discardPosition = {-50, 30, 0}

return function(load)
    load.playerBoards = function()
        local playerBoards = {}

        function playerBoards:setup()
            local distribute = async(function()
                factionOrder = {}
                local delivered = {}
                for i = 1, #turns.players do
                    local color = turns.players[i]
                    local faction = factions[color]
                    broadcastToAll(
                        Player[color].steam_name .. ' will play the ' .. faction,
                        color)

                    local board = Obj {tags = {'Player Board', faction}}
                    local snap = Snap.get {tags = {'Player Board', 'n' .. i}}
                    delivered[faction] = true
                    factionOrder[faction] = i
                    board:snapTo(snap[1], {0, 0.5, 0}):await()
                    local layout = Layout {
                        zone = Obj {tags = {'Player Staging', 'n' .. i}},
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
                    async.par {
                        layout:insert(getObjectsWithAllTags {'Bloc', faction}),
                        layout:insert(getObjectsWithAllTags {'Flag', faction}),
                        layout:insert(
                            getObjectsWithAllTags {'Occupation', faction})
                    }:await()
                end
            end)
            local delivered = {}
            for _, color in pairs(turns.players) do
                delivered[color] = true
            end
            local function discard(o)
                return Obj.use(o):leaveTowards{position = discardPosition}
            end
            local actions = {distribute}
            for c, f in pairs(factions) do
                if not delivered[c] then
                    local board = Obj {tags = {'Player Board', f}}
                    table.insert(actions,
                                 board:leaveTowards{position = discardPosition})
                    table.insert(actions, async.par(
                                     iter.map(getObjectsWithAllTags {'Bloc', f},
                                              discard)))
                    table.insert(actions, async.par(
                                     iter.map(getObjectsWithAllTags {'Flag', f},
                                              discard)))
                    table.insert(actions, async.par(
                                     iter.map(
                                         getObjectsWithAllTags {'Occupation', f},
                                         discard)))
                end
            end
            return async.par(actions)
        end

        return playerBoards
    end
end
