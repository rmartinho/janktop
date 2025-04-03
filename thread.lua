local Object = require 'tts/classic'

local Thread = Object:extend('Thread')

function Thread:new(f) self.coro = coroutine.create(f) end

function Thread.wait(f)
    assert(Thread.active, 'Thread.wait called outside of Thread')
    f = f or 1
    local t = Thread.active
    if type(f) == 'number' then
        Wait.frames(function() t:resume() end, f)
    else
        Wait.condition(function() t:resume() end, f)
    end
    coroutine.yield()
end

function Thread:resume(...)
    local oldActive = Thread.active
    Thread.active = self
    coroutine.resume(self.coro, ...)
    Thread.active = oldActive
end

Thread.yield = coroutine.yield

function Thread.run(f, ...)
    local thread = Thread(f)
    thread:resume(...)
end

return Thread
