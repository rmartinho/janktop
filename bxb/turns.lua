local Turns = require("tts/turns")

return function(load)
    load.turns = function(data)
      local turns
      if data then
        turns = Turns.load(data)
      else
        turns = Turns {colors = {'Yellow', 'Orange', 'Green', 'Purple'}}
      end
      
      return turns
    end
end