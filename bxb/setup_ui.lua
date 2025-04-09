return function(load)
    load.setupDone = function(data)
        if data then
            UI.setAttribute('setupPanel', 'active', 'false')
        else
            beginner = false
            difficulty = 2
            local oldDifficulty, oldMode
            local difficultyNames = {'Easy', 'Medium', 'Hard', 'Expert'}

            function onDifficultyChanged(player, value)
                UI.setAttributes('difficultyText', {
                    text = 'Difficulty: ' .. difficultyNames[tonumber(value)]
                })
                difficulty = tonumber(value)
            end

            function onBeginnerChanged(player, value)
                beginner = value == 'True'
                if beginner then
                    oldDifficulty = difficulty
                    oldMode = gameMode
                    onDifficultyChanged(player, 1)
                    onSetAgendaCooperation()
                else
                    onDifficultyChanged(player, oldDifficulty)
                    if oldMode == 'cooperation' then
                        onSetAgendaCooperation()
                    elseif oldMode == 'standard' then
                        onSetAgendaStandard()
                    elseif oldMode == 'conflict' then
                        onSetAgendaConflict()
                    end
                end
                UI.setAttributes('difficultySlider', {
                    value = difficulty,
                    interactable = not beginner
                })
                UI.setAttributes('cooperationToggle', {
                    isOn = gameMode == 'cooperation',
                    interactable = not beginner
                })
                UI.setAttributes('standardToggle', {
                    isOn = gameMode == 'standard',
                    interactable = not beginner
                })
                UI.setAttributes('conflictToggle', {
                    isOn = gameMode == 'conflict',
                    interactable = not beginner
                })
            end

            function onDifficultyChanged(player, value)
                UI.setAttributes('difficultyText', {
                    text = 'Difficulty: ' .. difficultyNames[tonumber(value)]
                })
                difficulty = tonumber(value)
            end
            onDifficultyChanged(nil, difficulty)

            gameMode = 'standard'
            function onSetAgendaCooperation()
                gameMode = 'cooperation'
            end
            function onSetAgendaStandard() gameMode = 'standard' end
            function onSetAgendaConflict() gameMode = 'conflict' end
            onSetAgendaStandard()
        end
        local done = {save = function() return {} end}
        return done
    end
end
