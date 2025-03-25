return function(load)
    load.setupDone = function(data)
        if data then
            UI.setAttribute('setupPanel', 'active', 'false')
        else
            difficulty = 1
            local difficultyNames = {'Easy', 'Medium', 'Hard', 'Expert'}
            function onDifficultyChanged(player, value)
                UI.setAttribute('difficultyText', 'text', 'Difficulty: ' ..
                                    difficultyNames[tonumber(value)])
                difficulty = tonumber(value)
            end

            gameMode = 'standard'
            function onSetAgendaCooperation()
                gameMode = 'cooperation'
            end
            function onSetAgendaStandard() gameMode = 'standard' end
            function onSetAgendaConflict() gameMode = 'conflict' end
        end
        local done = {save = function() return {} end}
        return done
    end
end
