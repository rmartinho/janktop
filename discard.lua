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
        self.deck = Snap.load(params.load.deck)
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
        self.deck = iter.find(snaps, function(s) return s:hasTag('Draw') end)
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
        deck = self.deck:save(),
        discard = self.discard:save(),
        flip = self.flip,
        refreshes = self.refreshes,
        locks = self.locks
    }
end

function Discard:load(data) return self {load = data} end

function Discard:deal(n)
    n = n or 1
    async(function()
        for i = 1, n do
            self:deal1()
            async.pause()
        end
    end)
end

function Discard:deal1()
    local deck = self.deck.zone.getObjects()[1]
    local discard = self.discard.zone.getObjects()[1]
    local dropPos = discard and Obj.use(discard):deckDropPosition() or
                        self.discard.position
    async(function()
        if not deck and self.refreshes then
            self:refresh()
            self:deal1()
        elseif deck.type == 'Card' then
            if self.locks then deck.setLock(false) end
            if self.flip then deck.flip() end
            Obj.use(deck):snapTo{position = dropPos}
            self:unlock()
            async.wait.rest(deck)
            self:lock()
        else
            local card = deck.takeObject({
                position = dropPos,
                rotation = self.discard.rotation,
                flip = self.flip
            })
            self:unlock()
            async.wait.rest(card)
            self:lock()
        end
    end)
end

function Discard:refresh()
    local deck = self.discard.zone.getObjects()[1]
    if not deck then return end
    async(function()
        if self.flip then deck.flip() end
        Obj.use(deck):snapTo(self.deck)
        deck.shuffle()
        async.wait.rest(deck)
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
            local deck = Obj.get {tag = self.tag}
            deck:snapTo(self.deck)
            async.wait.rest(deck)
        end
    end)
end

return Discard
