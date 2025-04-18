local Obj = require 'tts/obj'
local Snap = require 'tts/snap'
local Layout = require 'tts/layout'
local Pattern = require 'tts/pattern'
local async = require 'tts/async'

return function(load)
    load.staging = function()
        local staging = {}

        function staging:setup()
            return async(function()
                local layout = Layout {
                    zone = Obj.get {tag = 'Staging Area'},
                    patterns = {
                        ['Squad'] = Pattern.columns {
                            corner = Snap.get{
                                base = board,
                                tags = {'Squad', 'Staging Area'}
                            }[1],
                            height = 3,
                            spreadH = -0.6,
                            spreadV = 0.6
                        },
                        ['Van'] = Pattern.columns {
                            corner = Snap.get{
                                base = board,
                                tags = {'Van', 'Staging Area'}
                            }[1],
                            height = 2,
                            spreadH = 2.5,
                            spreadV = -1.1
                        }
                    },
                    sticky = true
                }
                async.par {
                    layout:insert(getObjectsWithTag('Squad')),
                    layout:insert(getObjectsWithTag('Van'))
                }:await()
            end)
        end

        return staging
    end
end
