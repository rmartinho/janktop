local Obj = require 'tts/obj'
local async = require 'tts/async'

return function(load)
    load.board = function()
        local board = Obj.get {tag = 'Board'}

        function board:setup()
            async(function()
                local cover = Obj.get {tag = 'Cover'}
                cover.setPositionSmooth({0, 50, 0})
                async.pause()
                async.pause()
                cover.destroy()
            end)
        end
        return board
    end
end
