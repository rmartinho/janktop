local Obj = require 'tts/obj'
local async = require 'tts/async'

return function(load)
    load.board = function()
        local board = Obj.get {tag = 'Board'}

        function board:setup()
            async(function()
                board.setLock(false)
                board.flip()
                async.wait.rest(self)
                board.setLock(true)
                async.pause()
            end)
        end
        return board
    end
end
