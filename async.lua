local Object = require 'tts/classic'

local Thread = Object:extend('Thread')
local Waiter = Object:extend('Waiter')

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
function Thread.run(f, ...)
    local thread = Thread(f)
    thread:resume(...)
end

function Waiter:new(f, wait1)
    self.wait1 = wait1 == true
    self.f = f
end

function Waiter:wait()
    if self.wait1 then Thread.wait() end
    Thread.wait(self.f)
end

function Waiter.rest(o)
    return Waiter(function() return o.isDestroyed() or o.resting end, true)
end

local async = {Waiter = Waiter, wait = {}}
setmetatable(async, {
    __call = function(self, f)
        if Thread.active then
            f()
        else
            Thread.run(f)
        end
    end
})
setmetatable(async.wait, {
    __call = function(self, ...) return Thread.wait(...) end,
    __index = function(_, k)
        if k ~= 'wait' and not Object[k] and type(Waiter[k]) == 'function' then
            return function(...) return Waiter[k](...):wait() end
        end
    end
})

function async.pause() return async.wait(async.pauseDuration or 10) end

function async.fork(f)
    local active = Thread.active
    Thread.active = nil
    local r = f()
    Thread.active = active
    return r
end

return async
