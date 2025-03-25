local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local async = require 'tts/async'

return function(load)
    load.playerBoards = function()
        local playerBoards = {}

        function playerBoards:setup()
            local delivered = {}
            for i = 1, #turns.players do
                local faction = factions[turns.players[i]]
                local board = Obj.get {tags = {'Player Board', faction}}
                local snap = Snap.get {tags = {'Player Board', 'n' .. i}}
                board:snapTo(snap[1])
                delivered[faction] = true
            end

            for _, f in pairs(factions) do
                if not delivered[f] then
                    async(function()
                        local board = Obj.get {tags = {'Player Board', f}}
                        board:snapTo({position = {60, 50, 0}})
                        async.pause()
                        board.destroy()
                    end)
                end
            end
        end

        return playerBoards
    end
end
