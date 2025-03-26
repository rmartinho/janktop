local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.meeting = function(data)
        local meeting = {}

        function meeting:setup()
            self.layout = Layout {
                zone = Obj.get {tag = 'Meeting'},
                pattern = Pattern.fromSnaps(Snap.get {
                    base = Obj.get {tags = {'Condition', 'Deck'}},
                    tag = 'Meeting'
                })
            }
        end

        return meeting
    end
end
