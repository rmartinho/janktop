local Obj = require 'tts/obj'
local Track = require 'tts/track'
local Tracker = require 'tts/tracker'
local async = require 'tts/async'

return function(load)
  load.countdown = function(data)
      local countdown
      if data then
          countdown = Tracker.load(data)
      else
          countdown = Tracker {
              marker = Obj.get {tag = 'Countdown'},
              track = Track {base = board, snapTag = 'Countdown'}
          }
      end
      
      function countdown:onStep(i)
          local remain = #self.track - i
          local description = 'GAME OVER'
          if remain > 0 then
              description = remain .. ' night' .. (remain == 1 and '' or 's') ..
                                ' remaining'
          end
          self.marker.setDescription(description)
      end
  
      function countdown:advance()
          async(function()
              local steps = morale:steps()
              for i = 1, steps do Tracker.advance(self) end
          end)
      end
      
      return countdown
  end
end