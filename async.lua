local Object = require 'tts/classic'

local Waiter = Object:extend('Waiter')

function Waiter:new(resume) self.resume = resume end

function Waiter:wait(f)
    f = f or 1
    if type(f) == 'number' then
        Wait.frames(function() self.resume() end, f)
    else
        Wait.condition(function() self.resume() end, f)
    end
    coroutine.yield()
end

function Waiter:rest(o)
    if o.resting then self:wait() end
    return self:wait(function() return o.resting == true end)
end

function async(f)
    local coro = {}
    coro[1] = coroutine.wrap(function() f(Waiter(coro[1])) end)
    coro[1]()
end

return async
