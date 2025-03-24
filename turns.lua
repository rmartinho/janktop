local Object = require 'tts/classic'

local Turns = Object:extend('Turns')

function Turns:new(params)
    params = params or {}
    if params.load then
        self.players = params.load.players
        self.i = params.load.i
    else
      params = params or {}
      params.colors = params.colors or getSeatedPlayers()
      params.n = params.n or #params.colors
      self.players = {} --TODO move this to setup
      for i = 1, params.n do
          table.insert(self.players,
                       table.remove(params.colors, math.random(#params.colors)))
      end
      self.i = 1
    end
end

function Turns:current() return self.players[self.i] end

function Turns:pass()
    self.i = (self.i % #self.players) + 1
    return self:current()
end

function Turns:save()
    return {players = self.players, i = self.i}
end

function Turns.load(data) return Turns {load = data} end

return Turns
