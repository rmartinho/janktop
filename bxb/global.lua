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
    async.pauseDuration = 10
    async(function()
        board:setup():await()
        async.apause():await()

        async.par {
            city:setup(), staging:setup(), loot:setup(), barricades:setup(),
            graffiti:setup(), dice:setup()
        }:await()
        async.apause():await()

        countdown:setup():await()
        async.apause():await()

        async.par {ops:setup(), police:setup()}:await()
        morale:setup():await()
        async.apause():await()

        reaction:setup():await()
        async.apause():await()

        conditions:setup():await()
        meeting:setup():await()
        async.apause():await()

        turns:setup():await()
        async.apause():await()

        playerBoards:setup():await()
        async.apause():await()

        agendas:setup():await()
        async.apause():await()

        flame:setup():await()
        async.apause():await()

        for _, p in pairs(getSeatedPlayers()) do
            broadcastToColor(
                'Place your Start occupation in one of your districts', p,
                Color.fromString(factions[p]))
        end
        Ready.all():await()

        occupations:setup()
        async.apause():await()

        broadcastToAll('Setup complete.')

        phase:setup()
    end)
end

function onObjectDrop(player, object) Layout.onDrop(player, object) end

function onObjectLeaveZone(zone, object) Layout.onLeave(zone, object) end
