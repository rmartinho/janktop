local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.meeting = function(data)
        local meeting = {}

        function meeting:setup()
            return async(function()
                self.layout = Layout {
                    zone = Obj {tag = 'Meeting'},
                    pattern = Pattern.fromSnaps(Snap.get {
                        base = Obj {tags = {'Condition', 'Deck'}},
                        tag = 'Meeting'
                    })
                }
            end)
        end

        function meeting:resolve()
            -- TODO
        end

        return meeting
    end
end
