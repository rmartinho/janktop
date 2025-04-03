local iter = require 'tts/iter'
local async = require 'tts/async'

local Ready = {}

Ready.visibility = {}

local function updateVisibility()
    UI.setAttribute('readyPanel', 'active', 'false')
    local visibilityString = ''
    for c, visible in pairs(Ready.visibility) do
        if visible then
            UI.setAttribute('readyPanel', 'active', 'true')
            if #visibilityString == 0 then
                visibilityString = c
            else
                visibilityString = visibilityString .. '|' .. c
            end
        end
    end
end

function Ready.all()
    return Ready.some(iter.map(Player.getPlayers(), function(p) return p.color end))
end

function Ready.some(colors)
    return async(function()
        Ready.visibility = {}
        for _, c in pairs(colors) do Ready.visibility[c] = true end
        Ready.counter = #colors
        updateVisibility()
        async.condition(function() return Ready.counter == 0 end):await()
    end)
end

function Ready:onReady(player)
    Ready.visibility[player.color] = nil
    Ready.counter = Ready.counter - 1
    updateVisibility()
end

setmetatable(Ready, {__call = Ready.onReady})

return Ready
