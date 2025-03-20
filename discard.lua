local Object = require 'tts/classic'
local iter = require 'tts/iter'

local CardDiscard = Object:extend('CardDiscard')

function CardDiscard:new(params)
    self.deck = params.deck
    self.discard = snap.zoned(params.discard, snap.zoned)
    self.flip = params.flip ~= false
    self.pile = params.pile == true
end