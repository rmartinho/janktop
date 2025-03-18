local iter = {}

function iter.filter(t, f)
    local r = {}
    for _, v in ipairs(t) do if f(v) then table.insert(r, v) end end
    return r
end

function iter.count(t, f)
    local c = 0
    for _, v in ipairs(t) do if f(v) then c = c + 1 end end
    return c
end

function iter.find(t, f) for _, v in ipairs(t) do if f(v) then return v end end end

function iter.map(t, f)
    local r = {}
    for _, v in ipairs(t) do table.insert(r, f(v)) end
    return r
end

function iter.has(t, c) return iter.find(t, function(x) return x == c end) end

function iter.all(t, f)
    f = f or function(x) return x end
    local c = iter.count(t, f)
    return c == #t
end

function iter.hasAll(t, ...)
    return iter.all({...}, function(x) return iter.has(t, x) end)
end

return iter
