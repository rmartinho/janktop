local Object = require 'tts/classic'
local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
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
    n = n or 1
    async(function()
        for i = 1, n do
            self:deal1()
            async.pause()
        end
    end)
end

local dropOffset = Vector(0, 0.5, 0)

function Discard:deal1()
    local draw = self:drawPile()
    local discard = self:discardPile()
    local dropPos = discard and discard:deckDropPosition() or
                        self.discard.position
    async(function()
        if not draw and self.refreshes then
            self:refresh()
            self:deal1()
        elseif draw.type == 'Card' then
            if self.locks then draw.setLock(false) end
            if self.flip then draw.flip() end
            draw:snapTo({position = dropPos}, dropOffset)
            self:unlock()
            async.wait.rest(draw)
            self:lock()
            if self.onTopChanged then self:onTopChanged() end
        else
            local card = draw.takeObject {
                position = Vector(dropPos) + dropOffset,
                rotation = self.discard.rotation,
                flip = self.flip
            }
            self:unlock()
            async.wait.rest(card)
            self:lock()
            if self.onTopChanged then self:onTopChanged() end
        end
    end)
end

function Discard:drawPile() return Obj.use(self.draw.zone.getObjects()[1]) end

function Discard:discardPile() return Obj.use(self.discard.zone.getObjects()[1]) end

function Discard:topOfDraw()
    local deck = self:drawPile()
    if deck.type == 'Card' then
        return deck
    else
        return deck.getObjects()[1]
    end
end

function Discard:topOfDiscard()
    local deck = self:discardPile()
    if deck.type == 'Card' then
        return deck
    else
        return deck.getObjects()[1]
    end
end

function Discard:refresh()
    local deck = self.discard.zone.getObjects()[1]
    if not deck then return end
    async(function()
        if self.flip then deck.flip() end
        Obj.use(deck):snapTo(self.draw, dropOffset)
        deck.shuffle()
        async.wait.rest(deck)
        if deck.type == 'Deck' then
            deck.setName(self.name)
            deck.setDescription(self.description)
        end
        if self.onRefresh then self:onRefresh() end
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
    async(function()
        if self.tag then
            local deck = Obj.get {tags = {self.tag, 'Deck'}}
            deck.shuffle()
            deck:snapTo(self.draw, dropOffset)
            async.wait.rest(deck)
            deck.setLock(self.locks)
            if self.onTopChanged then self:onTopChanged() end
        end
        self.name = self:drawPile().getName()
        self.description = self:drawPile().getDescription()
    end)
end

return Discard
