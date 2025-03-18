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
    local pxy = {}
    setmetatable(pxy, metaProxy(obj))
    return pxy
end

function Proxy.retarget(pxy, obj)
    local meta = getmetatable(pxy)
    assert(meta and meta.__proxy, 'cannot retarget non-proxy')
    setmetatable(pxy, metaProxy(obj))
    return pxy
end

function Proxy.unwrap(pxy)
    local meta = getmetatable(pxy) or {}
    return meta.__proxy or pxy
end

function Proxy.lazy(fn)
    local obj = {}
    local pxy = Proxy.create(obj)
    setmetatable(pxy, {
        __index = function(t, k)
            Proxy.retarget(t, fn())
            return t[k]
        end,
        __newindex = function(t, k, v)
            Proxy.retarget(t, fn())
            t[k] = v
        end,
        __proxy = obj
    })
    return pxy
end

setmetatable(Proxy, {__call = function(self, ...) return Proxy.create(...) end})

return Proxy
