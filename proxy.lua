local Proxy = {}

local function metaProxy(obj)
    local meta = getmetatable(obj) or {}
    local m = {}
    for k, v in pairs(meta) do if k:find('__') == 1 then m[k] = v end end
    m.__index = obj
    m.__newindex = obj
    m.__proxy = obj
    return m
end

function Proxy.create(obj)
    obj = Proxy.unwrap(obj)
    local pxy = {}
    setmetatable(pxy, metaProxy(obj))
    return pxy
end

function Proxy.retarget(pxy, obj)
    local meta = getmetatable(pxy)
    assert(meta and meta.__proxy, 'can only retarget proxies')
    setmetatable(pxy, metaProxy(obj))
    return pxy
end

function Proxy.unwrap(pxy)
    Proxy.resolve(pxy)
    local meta = getmetatable(pxy)
    return meta and meta.__proxy or pxy
end

function Proxy.lazy(fn)
    local pxy = {}
    setmetatable(pxy, {
        __index = function(t, k)
            Proxy.retarget(t, fn())
            return t[k]
        end,
        __newindex = function(t, k, v)
            Proxy.retarget(t, fn())
            t[k] = v
        end,
        __lazy = fn,
        __proxy = {}
    })
    return pxy
end

function Proxy.resolve(o)
    if Proxy.isLazy(o) then
        local meta = getmetatable(o)
        Proxy.retarget(o, meta.__lazy())
    end
    return o
end

function Proxy.isProxy(o)
    if type(o) ~= 'table' then return false end
    local meta = getmetatable(o)
    return meta and meta.__proxy and true or false
end

function Proxy.isLazy(o)
    if type(o) ~= 'table' then return false end
    local meta = getmetatable(o)
    return meta and meta.__proxy and meta.__lazy and true or false
end

setmetatable(Proxy, {__call = function(self, ...) return Proxy.create(...) end})

return Proxy
