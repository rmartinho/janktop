local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Promise = require 'tts/promise'
local iter = require 'tts/iter'
local async = require 'tts/async'

local Discard = Object:extend('Discard')

function Discard:new(params)
    params = params or {}
    if params.load then
        self.tag = params.load.tag
        self.name = params.load.name
        self.description = params.load.description
        self.draw = Snap.load(params.load.draw)
        self.discard = Snap.load(params.load.discard)
        self.flip = params.load.flip
        self.refreshes = params.load.refreshes
        self.locks = params.load.locks
    else
        self.tag = params.snapTag
        local snaps = Snap.get {
            base = params.base,
            tag = params.snapTag,
            zoned = true
        }
        self.draw = iter.find(snaps, function(s) return s:hasTag('Draw') end)
        self.discard = iter.find(snaps,
                                 function(s) return s:hasTag('Discard') end)
        self.flip = params.flip ~= false
        self.refreshes = params.refresh ~= false
        self.locks = params.locks == true
    end
end

function Discard:save()
    return {
        tag = self.tag,
        name = self.name,
        description = self.description,
        draw = self.draw:save(),
        discard = self.discard:save(),
        flip = self.flip,
        refreshes = self.refreshes,
        locks = self.locks
    }
end

function Discard.load(data) return Discard {load = data} end

function Discard:deal(n)
    return async(function()
        n = n or 1
        for i = 1, n do
            self:deal1():await()
            async.apause():await()
        end
    end)
end

local dropOffset = Vector(0, 0.5, 0)

function Discard:deal1()
    local draw = self:drawPile()
    local discard = self:discardPile()
    local dropPos = discard and discard:deckDropPosition() or
                        self.discard.position
    return async(function()
        if not draw and self.refreshes then
            self:refresh():await()
            self:deal1():await()
        elseif draw.type == 'Card' then
            if self.locks then draw.setLock(false) end
            if self.flip then draw.flip() end
            self:unlock()
            draw:snapTo({position = dropPos}, dropOffset):await()
            self:lock()
            if self.onDeal then self:onDeal(draw):await() end
            if self.onTopChanged then self:onTopChanged():await() end
        else
            self:unlock()
            local card = draw.takeObject {
                position = Vector(dropPos) + dropOffset,
                rotation = self.discard.rotation,
                flip = self.flip
            }
            async.rest(card):await()
            self:lock()
            if self.onDeal then self:onDeal(card):await() end
            if self.onTopChanged then self:onTopChanged():await() end
        end
    end)
end

function Discard:drawPile() return Obj.use(self.draw.zone.getObjects()[1]) end

function Discard:discardPile() return Obj.use(self.discard.zone.getObjects()[1]) end

function Discard:topOfDraw()
    local deck = self:drawPile()
    if deck then
        if deck.type == 'Card' then
            return deck
        else
            return deck.getObjects()[1]
        end
    end
end

function Discard:topOfDiscard()
    local deck = self:discardPile()
    if deck then
        if deck.type == 'Card' then
            return deck
        else
            return deck.getObjects()[1]
        end
    end
end

function Discard:refresh()
    return async(function()
        local deck = self.discard.zone.getObjects()[1]
        if not deck then return end
        if self.flip then deck.flip() end
        Obj.use(deck):snapTo(self.draw, dropOffset):await()
        deck.shuffle()
        if deck.type == 'Deck' then
            deck.setName(self.name)
            deck.setDescription(self.description)
        end
        if self.onRefresh then self:onRefresh():await() end
    end)
end

function Discard:lock()
    if not self.locks then return end
    local discard = self.discard.zone.getObjects()[1]
    if discard then discard.setLock(true) end
end

function Discard:unlock()
    if not self.locks then return end
    local discard = self.discard.zone.getObjects()[1]
    if discard then discard.setLock(false) end
end

function Discard:setup()
    return async(function()
        if self.tag then
            local deck = Obj {tags = {self.tag, 'Deck'}}
            deck.shuffle()
            deck:snapTo(self.draw, dropOffset):await()
            deck.setLock(self.locks)
            if self.onTopChanged then
                self:onTopChanged():await()
            end
        end
        self.name = self:drawPile().getName()
        self.description = self:drawPile().getDescription()
    end)
end

return Discard
