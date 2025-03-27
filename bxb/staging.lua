local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.staging = function()
        local staging = {}

        function staging:setup()
            local layout = Layout {
                zone = Obj.get {tag = 'Staging Area'},
                patterns = {
                    ['Squad'] = Pattern.columns {
                        corner = Snap.get{base = board, tag = 'Squad'}[1],
                        height = 3,
                        spreadH = -0.6,
                        spreadV = 0.6
                    },
                    ['Van'] = Pattern.columns {
                        corner = Snap.get{base = board, tag = 'Van'}[1],
                        height = 2,
                        spreadH = 2.5,
                        spreadV = -1.1
                    }
                },
                sticky = true
            }
            async.fork(function()
                layout:put(getObjectsWithTag('Squad'))
                layout:put(getObjectsWithTag('Van'))
            end)
        end

        return staging
    end
end
