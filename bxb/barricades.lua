local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.barricades = function()
        local barricades = {}

        function barricades:setup()
            Snap.get {base = board, tags = {'Barricade', 'Spot'}, zoned = true}

            local layout = Layout {
                zone = Obj {tag = 'Barricade Area'},
                pattern = Pattern.rows {
                    corner = Snap.get{
                        base = board,
                        tags = {'Barricade', 'Barricade Area'}
                    }[1],
                    width = 8,
                    spreadH = 2.6,
                    spreadV = 1.76
                },
                sticky = true
            }
            return layout:insert(getObjectsWithTag('Barricade'))
        end

        return barricades
    end
end
