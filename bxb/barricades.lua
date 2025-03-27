local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.barricades = function()
        local barricades = {}

        function barricades:setup()
            local layout = Layout {
                zone = Obj.get {tag = 'Barricade Area'},
                pattern = Pattern.rows {
                    corner = Snap.get{base = board, tag = 'Barricade'}[1],
                    width = 8,
                    spreadH = 2.6,
                    spreadV = 1.76
                }
            }
            async.fork(function()
                layout:put(getObjectsWithTag('Barricade'))
            end)
        end

        return barricades
    end
end
