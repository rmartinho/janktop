local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.dice = function()
        local dice = {}

        function dice:setup()
            local layout = Layout {
                zone = Obj.get {tag = 'Dice Area'},
                pattern = Pattern.columns {
                    corner = Snap.get{base = board, tag = 'Die'}[1],
                    height = 5,
                    spread = -1.7
                }, preserveRotationValue = true
            }
            async.fork(function()
                layout:insert(getObjectsWithTag('Die'))
            end)
        end

        return dice
    end
end
