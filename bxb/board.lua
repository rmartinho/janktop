local Obj = require 'tts/obj'

return function(load)
    load.board = function()
        local board = Obj {tag = 'Board'}

        function board:setup()
            local cover = Obj {tag = 'Cover'}
            return cover:leaveTowards{position = {0, 50, 0}}
        end

        return board
    end
end
