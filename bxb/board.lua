local Obj = require 'tts/obj'

return
    function(load) load.board = function() return Obj.get {tag = 'Board'} end end
