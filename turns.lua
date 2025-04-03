local Object = require 'tts/classic'
local Promise = require 'tts/promise'
local iter = require 'tts/iter'

local Turns = Object:extend('Turns')

function Turns:new(params)
    params = params or {}
    if params.load then
        self.players = params.load.players
        self.i = params.load.i
        self.colors = params.load.colors
        self.random = params.load.random
    else
        params = params or {}
        params.colors = params.colors or Player.getAvailableColors()
        self.random = params.random == true
        self.colors = params.colors
    end
end

function Turns:current() return self.players[self.i] end

function Turns:pass()
    self.i = (self.i % #self.players) + 1
    return self:current()
end

function Turns:save()
    return {
        players = self.players,
        i = self.i,
        colors = self.colors,
        random = self.random
    }
end

function Turns.load(data) return Turns {load = data} end

function Turns:setup()
    local free = {}
    local colors = Player.getColors()
    for _, c in pairs(colors) do
        free[c] = c ~= 'Grey' and not Player[c].seated
    end
    local freeColor = function()
        for c, ok in pairs(free) do if ok then return c end end
    end
    local hands = Hands.getHands()
    local function handWithIndex(i)
        return iter.find(hands, function(h) return h.hasTag('n' .. i) end)
    end
    if self.random then
        self.players = {}
        local players = Player.getPlayers()
        local oldPlayerOrder = {}
        for i = 1, #players do
            local h = handWithIndex(i)
            local color = table.remove(self.colors, math.random(#self.colors))
            table.insert(self.players, color)
            table.insert(oldPlayerOrder, players[i])
            h.setValue(color)
            free[players[i].color] = false
        end
        for i = 1, #self.players do
            local player = oldPlayerOrder[i]
            local color = self.players[i]
            if color ~= player.color then
                if Player[color] then
                    local fc = freeColor()
                    free[fc] = false
                    Player[color].changeColor(fc)
                end
                free[player.color] = true
                free[color] = false
                player.changeColor(color)
            end
        end
    end
    for i = #self.players + 1, #hands do
        local h = handWithIndex(i)
        h.destroy()
    end

    self.i = math.random(#self.players)
    return Promise.ok()
end

return Turns
