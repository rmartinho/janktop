local iter = require 'iter'

local snap = {}

function snap.filterTag(o, tag)
    return iter.filter(o.getSnapPoints(),
                  function(s) return iter.has(s.tags, tag) end)
end

function snap.filterTagOrdered(o, tag)
    local snaps = o.getSnapPoints()
    local f = iter.count(snaps, function(s) return iter.has(s.tags, tag) end)
    local r = {}
    for i = 1, f do
        local s = iter.find(snaps, function(s)
            return iter.hasAll(s.tags, tag, 'n' .. tostring(i))
        end)
        table.insert(r, s)
    end
    return r
end

function snap.findTag(o, tag)
    return iter.find(o.getSnapPoints(), function(t) return t == tag end)
end

return snap
