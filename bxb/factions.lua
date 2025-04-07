return function(load)
    load.factions = function()
        return {
            Yellow = 'Workers',
            Orange = 'Prisoners',
            Green = 'Neighbors',
            Purple = 'Students',
        }
    end

    load.factionColors = function()
        Color.Add('Workers', Color(231 / 255, 229 / 255, 44 / 255))
        Color.Add('Prisoners', Color(238 / 255, 109 / 255, 55 / 255))
        Color.Add('Neighbors', Color(0, 151 / 255, 101 / 255))
        Color.Add('Students', Color(120 / 255, 76 / 255, 155 / 255))
    end
end
