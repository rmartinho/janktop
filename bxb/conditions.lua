local Obj = require 'tts/obj'
local Display = require 'tts/display'
local Snap = require 'tts/snap'
local async = require 'tts/async'

local colors = {
    ['Communard: 2 Adjacent Districts Liberated'] = 'Communard',
    ['Autonomous: 2 of Your Own Districts Liberated'] = 'Autonomous',
    ['Popular: 2 Public Districts Liberated'] = 'Public',
    ['International Airport Liberated'] = 'State',
    ['Financial District Liberated'] = 'State',
    ['Telecom Network Hub Liberated'] = 'State',
    ['Interior Ministry Liberated'] = 'State',
    ['Privatized University Liberated'] = 'Students',
    ['Gentrifying Residential Zone Liberated'] = 'Neighbors',
    ['Global Shipping & Receiving Center Liberated'] = 'Workers',
    ['Supermax Prison Liberated'] = 'Prisoners',
}

return function(load)
    load.conditions = function(data)
        local conditions
        if data then
            conditions = Display.load(data)
        else
            conditions = Display {
                base = board,
                snapTag = 'Condition',
                locks = true
            }
        end

        function conditions:onDeal(card)
            return async(function()
                broadcastToAll('New condition: ' .. card.getName(), Color.fromString(colors[card.getName()]))
                Snap.get {base = card, tag = 'Flag', zoned = true}
            end)
        end

        function conditions:setup()
            return async(function()
                -- TODO remove unwanted conditions
                Display.setup(self):await()
                self:deal():await()
            end)
        end

        return conditions
    end

    load.conditionColors = function()
        Color.Add('State', Color(1, 1, 1))
        Color.Add('Public', Color(231 / 255, 131 / 255, 161 / 255))
        Color.Add('Communard', Color(238 / 255, 48 / 255, 73 / 255))
        Color.Add('Autonomous', Color(184 / 255, 177 / 255, 147 / 255))
    end
end
