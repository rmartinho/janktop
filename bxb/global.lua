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

local function broadcastGameMode()
    local difficultyNames = {'Easy', 'Medium', 'Hard', 'Expert'}
    broadcastToAll(difficultyNames[difficulty] .. ' mode (' .. difficulty ..
                       ' Heavy Reinforcements)')
    if gameMode == 'conflict' then
        broadcastToAll('Conflict agendas: at least one player wins alone')
    end
    if gameMode == 'cooperation' then
        broadcastToAll('Cooperation agendas: everyone wins together')
    else
        broadcastToAll(
            'Standard agendas: maybe some players win alone')
    end
end

function setup()
    UI.setAttribute('setupPanel', 'active', 'false')
    broadcastGameMode()
    async(function()
        board:setup()
        turns:setup()
        agendas:setup()
        async.fork(function() playerBoards:setup() end)
        barricades:setup()
        staging:setup()
        dice:setup()
        city:setup()
        async.wait(function() return city.built == 25 end)
        vans:setup()
        async.fork(function()
            loot:setup()
            graffiti:setup()
        end)
        reaction:setup()
        ops:setup()
        conditions:setup()
        meeting:setup()
        morale:setup()
        countdown:setup()
        flame:setup()
        phase:setup()
        broadcastToAll('Place your Start occupation in one of your districts', 'Pink')
        Ready.waitAll()
        ops:deal()
        phase:advance()
    end)
end

function onObjectDrop(player, object) Layout.onDrop(player, object) end

function onObjectLeaveZone(zone, object) Layout.onLeave(zone, object) end
