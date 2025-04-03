local Object = require 'tts/classic'
local Proxy = require 'tts/proxy'
local Thread = require 'tts/thread'

local Promise = Object:extend('Promise')

local PENDING = 0
local RESOLVING = 1
local REJECTING = 2
local RESOLVED = 3
local REJECTED = 4

local core = {}

local function finish(deferred, state)
    state = state or REJECTED
    for i, f in ipairs(deferred.queue) do
        if state == RESOLVED then
            core.resolve(f, deferred.value)
        else
            core.reject(f, deferred.value)
        end
    end
    deferred.state = state
end

local function isfunction(f)
    if type(f) == 'table' then
        local mt = getmetatable(f)
        return mt ~= nil and isfunction(mt.__call)
    end
    return type(f) == 'function'
end

local function promise(deferred, next, success, failure, nonpromisecb)
    if type(deferred) == 'table' and type(deferred.value) == 'table' and
        isfunction(next) then
        local called = false
        local ok, err = pcall(next, deferred.value, function(v)
            if called then return end
            called = true
            deferred.value = v
            success()
        end, function(v)
            if called then return end
            called = true
            deferred.value = v
            failure()
        end)
        if not ok and not called then
            deferred.value = err
            failure()
        end
    else
        nonpromisecb()
    end
end

local function fire(deferred)
    local next
    Proxy.resolve(deferred.value)
    if type(Proxy.unwrap(deferred.value)) == 'table' then
        next = deferred.value.next
    end
    promise(deferred, next, function()
        deferred.state = RESOLVING
        fire(deferred)
    end, function()
        deferred.state = REJECTING
        fire(deferred)
    end, function()
        local ok
        local v
        if deferred.state == RESOLVING and isfunction(deferred.success) then
            ok, v = pcall(deferred.success, deferred.value)
        elseif deferred.state == REJECTING and isfunction(deferred.failure) then
            ok, v = pcall(deferred.failure, deferred.value)
            if ok then deferred.state = RESOLVING end
        end

        if ok ~= nil then
            if ok then
                deferred.value = v
            else
                deferred.value = v
                return finish(deferred)
            end
        end

        if deferred.value == deferred then
            deferred.value = pcall(error, 'resolving deferred with itself')
            return finish(deferred)
        else
            promise(deferred, next, function()
                finish(deferred, RESOLVED)
            end, function(state) finish(deferred, state) end, function()
                finish(deferred, deferred.state == RESOLVING and RESOLVED)
            end)
        end
    end)
end

local function settle(deferred, state, value)
    if deferred.state == PENDING then
        deferred.value = value
        deferred.state = state
        fire(deferred)
    end
    return deferred
end

local function resolve(deferred, value) return
    settle(deferred, RESOLVING, value) end
core.resolve = resolve
local function reject(deferred, value) return settle(deferred, REJECTING, value) end
core.reject = reject

function Promise:next(success, failure)
    local n = Promise {success = success, failure = failure}
    if self.state == RESOLVED then
        resolve(n, self.value)
    elseif self.state == REJECTED then
        reject(n, self.value)
    else
        table.insert(self.queue, n)
    end
    return n
end

function Promise:new(options)
    if isfunction(options) then
        self:new()
        local ok, err = pcall(options, function(v) resolve(self, v) end,
                              function(e) reject(self, e) end)
        if not ok then reject(self, err) end
        return
    else
        options = options or {}
        self.state = PENDING
        self.queue = {}
        self.success = options.success
        self.failure = options.failure
        if isfunction(options.extend) then options.extend(self) end
    end
end

function Promise.ok(v)
    local p = Promise()
    resolve(p, v)
    return p
end

function Promise.fail(e)
    local p = Promise()
    reject(p, e)
    return p
end

function Promise.all(args)
    return Promise(function(res, rej)
        if #args == 0 then return res {} end
        local method = res
        local pending = #args
        local results = {}

        local function synchronizer(i, resolved)
            return function(value)
                results[i] = value
                if not resolved then method = rej end
                pending = pending - 1
                if pending == 0 then method(results) end
                return value
            end
        end

        for i = 1, pending do
            args[i]:next(synchronizer(i, true), synchronizer(i, false))
        end
    end)
end

function Promise.map(args, fn)
    local p = Promise()
    local results = {}
    local function donext(i)
        if i > #args then
            resolve(p, results)
        else
            fn(args[i]):next(function(val)
                table.insert(results, val)
                donext(i + 1)
            end, function(err) reject(p, err) end)
        end
    end
    donext(1)
    return p
end

function Promise.first(args)
    local p = Promise()
    local res = function(v) return resolve(p, v) end
    local rej = function(e) return reject(p, e) end
    for i, v in ipairs(args) do
        v:next(res, rej)
    end
    return p
end

function Promise:await()
    Thread.wait(function()
        return self.state == RESOLVED or self.state == REJECTED
    end)
    if self.state == RESOLVED then
        return self.value
    else
        error(self.value)
    end
end

return Promise
