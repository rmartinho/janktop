local Object = require 'tts/classic'

local Turns = Object:extend('Turns')

function Turns:new(params)
    params = params or {}
    params.colors = params.colors or getSeatedPlayers()
    params.n = params.n or #params.colors
    self.players = {}
    for i = 1, params.n do
        table.insert(self.players,
                     table.remove(params.colors, math.random(#params.colors)))
    end
    self.i = 1
end

function Turns:current() return self.players[self.i] end

function Turns:pass()
    self.i = (self.i % #self.players) + 1
    return self:current()
end

return Turns
