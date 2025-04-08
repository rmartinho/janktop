local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local iter = require 'tts/iter'
local async = require 'tts/async'

local Display = Object:extend('Display')

function Display:new(params)
    params = params or {}
    if params.load then
        self.tag = params.load.tag
        self.draw = Snap.load(params.load.draw)
        self.displays = iter.map(params.load.displays, Snap.load)
        self.locks = params.load.locks
    else
        self.tag = params.snapTag
        local snaps = Snap.get {
            base = params.base,
            tag = params.snapTag,
            zoned = true
        }
        self.draw = iter.find(snaps, function(s) return s:hasTag('Draw') end)
        self.displays = iter.filter(snaps,
                                    function(s)
            return s:hasTag('Display')
        end)
        self.locks = params.locks == true
    end
end

function Display:save()
    return {
        tag = self.tag,
        draw = self.draw:save(),
        displays = iter.map(self.displays, Snap.save),
        locks = self.locks
    }
end

function Display.load(data) return Display {load = data} end

function Display:deal(n)
    return async(function()
        n = n or 1
        for i = 1, n do
            self:deal1():await()
            async.apause():await()
        end
    end)
end

local dropOffset = Vector(0, 0.5, 0)

function Display:deal1()
    return async(function()
        local draw = self:drawPile()
        local snap = iter.find(self.displays,
                               function(d)
            return #d.zone.getObjects() == 0
        end)
        if snap then
            local card = draw.takeObject {
                position = Vector(snap.position) + dropOffset,
                rotation = snap.rotation,
                flip = true
            }
            async.rest(card):await()
            if self.locks then card.setLock(true) end
            if self.onDeal then self:onDeal(card):await() end
            if self.onTopChanged then self:onTopChanged():await() end
            return card
        else
            draw.flip()
            async.rest(draw):await()
            if self.locks then draw.setLock(true) end
            if self.onDeal then self:onDeal(draw):await() end
            if self.onTopChanged then self:onTopChanged():await() end
            return draw
        end
    end)
end

function Display:drawPile() return Obj.use(self.draw.zone.getObjects()[1]) end

function Display:topOfDraw()
    local deck = self:drawPile()
    if deck then
        if deck.type == 'Card' then
            return deck
        else
            return deck.getObjects()[1]
        end
    end
end

function Display:count()
    return iter.count(self.displays, function(d)
        return #d.zone.getObjects() > 0
    end)
    -- TODO flipped self state (maybe just an extra snappy)
end

function Display:setup()
    return async(function()
        if self.tag then
            local deck = Obj.get {tags = {self.tag, 'Deck'}}
            deck.shuffle()
            deck:snapTo(self.draw, dropOffset):await()
            deck.setLock(self.locks)
            if self.onTopChanged then self:onTopChanged():await() end
        end
    end)
end

return Display
