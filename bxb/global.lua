local Obj = require 'tts/obj'
local Layout = require 'tts/layout'
local async = require 'tts/async'

local saver = {}
local loader = {}

require("tts/bxb/setup_ui")(loader)
require("tts/bxb/board")(loader)
require("tts/bxb/factions")(loader)
require("tts/bxb/morale")(loader)
require("tts/bxb/countdown")(loader)
require("tts/bxb/flame")(loader)
require("tts/bxb/turns")(loader)
require("tts/bxb/phase")(loader)
require("tts/bxb/reaction")(loader)
require("tts/bxb/ops")(loader)
require("tts/bxb/conditions")(loader)
require("tts/bxb/loot")(loader)
require("tts/bxb/city")(loader)
require("tts/bxb/agendas")(loader)
require("tts/bxb/playerBoards")(loader)
require("tts/bxb/meeting")(loader)
require("tts/bxb/barricades")(loader)
require("tts/bxb/staging")(loader)
require("tts/bxb/dice")(loader)
require("tts/bxb/vans")(loader)

function doCountdown()
    countdown:advance()
    return true
end

function onLoad(saveData)
    local saved = JSON.decode(saveData) or {}
    for k, f in pairs(loader) do
        _G[k] = f(saved[k])
        saver[k] = _G[k]
    end
end

function onSave()
    local toSave = {}
    for k, v in pairs(saver) do if v.save then toSave[k] = v:save() end end
    return JSON.encode(toSave)
end

function setup()
    UI.setAttribute('setupPanel', 'active', 'false')
    async(function()
        board:setup()
        turns:setup()
        async.pause()
        async.fork(function()
            async(function()
                city:setup()
                async.wait(function() return city.built == 25 end)
                vans:setup()
            end)
            morale:setup()
            countdown:setup()
            flame:setup()
            phase:setup()
        end)
        async.pause()
        async.fork(function()
            reaction:setup()
            ops:setup()
            conditions:setup()
            loot:setup()
            graffiti:setup()
            agendas:setup()
            meeting:setup()
        end)
        async.pause()
        async.fork(function()
            barricades:setup()
            staging:setup()
            dice:setup()
        end)
        async.pause()
        async.fork(function() playerBoards:setup() end)
        async.wait(120)
        broadcastToAll('You may now place Faction Start occupations')
    end)
end

function onObjectDrop(player, object) Layout.onDrop(player, object) end

function onObjectLeaveZone(zone, object) Layout.onLeave(zone, object) end
