local Object = require 'tts/classic'

local Thread = Object:extend('Thread')

function Thread:new(f)
    self.coro = coroutine.create(function(...) return pcall(f, ...) end)
end

function Thread.wait(f)
    assert(Thread.active, 'Thread.wait called outside of Thread')
    f = f or 1
    local t = Thread.active
    local callback = function() t:resume() end
    if type(f) == 'number' then
        Wait.frames(callback, f)
    else
        Wait.condition(callback, f)
    end
    coroutine.yield(true)
end

function Thread:resume(...)
    local oldActive = Thread.active
    Thread.active = self
    local cont, ok, err = coroutine.resume(self.coro, ...)
    Thread.active = oldActive
    return ok, err
end

Thread.yield = coroutine.yield

function Thread.run(f, ...)
    local thread = Thread(f)
    return thread:resume(...)
end

return Thread
