local Object = require 'tts/classic'

local Turns = Object:extend('Turns')

function Turns:new(params)
  params = params or {}
  params.colors = params.colors or getSeatedPlayers()
  params.n = params.n or #params.colors
end

function Turns:current()
end

function Turns:next()
end