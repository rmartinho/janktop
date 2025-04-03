local Object = require 'tts/classic'
local Promise = require 'tts/promise'
local Thread = require 'tts/thread'

local async = {wait = {}}

function async.run(f)
    return Promise(function(res, rej)
        Thread.run(function()
            local ok, r = pcall(f)
            if ok then
                res(r)
            else
                rej(r)
            end
        end)
    end)
end

function async.frames(f)
    f = f or 1
    return Promise(function(res, rej) Wait.frames(res, f) end)
end

function async.condition(f)
    return Promise(function(res, rej) Wait.condition(res, f) end)
end

function async.rest(o, opts)
    local opts = opts or {}
    return async(function()
        if not opts.immediate then async.frames():await() end
        async.condition(function() return o.isDestroyed() or o.resting end):await()
        return o
    end)
end

async.race = Promise.first

async.par = Promise.all

function async.apause(n) return async.frames(n or async.pauseDuration or 1) end

--- BEGIN GARBAGE ---
async.wait = Thread.wait

function async.pause(n) return async.wait(n or async.pauseDuration or 1) end

function async.fork(f)
    local active = Thread.active
    Thread.active = nil
    local r = f()
    Thread.active = active
    return r
end

--- END GARBAGE ---

setmetatable(async, {__call = function(self, ...) return self.run(...) end})

return async
