local Obj = require 'tts/obj'
local Layout = require 'tts/layout'
local async = require 'tts/async'
Ready = require 'tts/ready'

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
require("tts/bxb/police")(loader)
require("tts/bxb/occupations")(loader)

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
    broadcastToAll('Setting up the game...')
    async.pauseDuration = 1
    async(function()
        board:setup():await()
        async.pause():await()

        async.par {
            city:setup(), staging:setup(), loot:setup(), barricades:setup(),
            graffiti:setup(), dice:setup()
        }:await()
        async.pause():await()

        countdown:setup():await()
        async.pause():await()

        async.par {ops:setup(), police:setup()}:await()
        morale:setup():await()
        async.pause():await()

        reaction:setup():await()
        async.pause():await()

        turns:setup():await()
        async.pause():await()

        playerBoards:setup():await()
        async.pause():await()

        conditions:setup():await()
        meeting:setup():await()
        async.pause():await()

        agendas:setup():await()
        async.pause():await()

        flame:setup():await()
        async.pause():await()

        occupations:setup()
        async.pause():await()

        broadcastToAll('Setup complete.')

        phase:setup()
    end):next(nil, print)
end

function onObjectDrop(player, object) Layout.onDrop(player, object) end

function onObjectLeaveZone(zone, object) Layout.onLeave(zone, object) end
