local Object = require 'tts/classic'
local iter = require 'tts/iter'

local Graph = Object:extend('Graph')

local function fromIx(i)
    local x = (i - 1) % 5 + 1
    local y = math.ceil(i / 5)
    return x, y
end

local function toIx(p) return (p[2] - 1) * 5 + p[1] end

local function valid(p)
    return p[1] <= 5 and p[1] >= 1 and p[2] <= 5 and p[2] >= 1
end

local function connect(g, i, j, w)
    g[i] = g[i] or {}
    g[i][j] = w
end

local deltas = {
    {1, 0}, {0, 1}, {-1, 0}, {0, -1}, {1, 0}, {0, 1}, {-1, 0}, {0, -1}
}
local tos = {
    {4, 1, 0}, {1, 2, 0}, {2, 3, 0}, {3, 4, 0}, {4, 1, 0}, {1, 2, 0}, {2, 3, 0},
    {3, 4, 0}, {4, 1, 0}, {1, 2, 0}, {2, 3, 0}, {3, 4, 0}
}

local function applyDelta(ix, d)
    local x, y = fromIx(ix)
    local p = {x + d[1], y + d[2]}
    if valid(p) then return toIx(p) end
end

local function nodeIx(node, corner)
    corner = corner or 0
    return node * 10 + corner
end

local function districtIx(node) return math.floor(node / 10), node % 10 end

local function makeNode(city, district, g)
    local si = district.index
    local adj = district.props.adjacency
    for r = 1, 4 do
        if adj[r] == 1 then
            local di = applyDelta(si, deltas[district.rot + r])
            if di then
                local d = city.districts[di]
                local w = d.props.highway and 1 or 2
                local t = tos[district.rot + r]
                for _, x in pairs(t) do
                    connect(g, nodeIx(si), nodeIx(di, x), w)
                end
            end
        end
    end
end

local function makeHighwayNodes(city, district, g)
    local i = district.index
    for r = 1, 2 do
        local shift = district.rot % 2 + 2 * r - 1
        local i1 = applyDelta(i, deltas[shift])
        local i2 = applyDelta(i, deltas[shift + 1])
        if i1 and i2 then
            local x = tos[shift + 3][1]
            local d1 = city.districts[i1]
            local d2 = city.districts[i2]
            local w1 = d1.props.highway and 0 or 1
            local w2 = d2.props.highway and 0 or 1
            local t1 = tos[shift]
            local t2 = tos[shift + 1]
            for _, x1 in pairs(t1) do
                connect(g, nodeIx(i, x), nodeIx(i1, x1), w1)
            end
            for _, x2 in pairs(t2) do
                connect(g, nodeIx(i, x), nodeIx(i2, x2), w2)
            end
        end
    end
end

local function prune(g)
    for i, adj in pairs(g) do
        for j, _ in pairs(adj) do
            if g[j] == nil or g[j][i] == nil then g[i][j] = nil end
        end
    end
end

local function buildGraph(city)
    local g = {}
    for i, district in ipairs(city.districts) do
        if district.props.highway then
            makeHighwayNodes(city, district, g)
        else
            makeNode(city, district, g)
        end
    end
    prune(g)
    return g
end

function Graph:new(city)
    self.city = city
    self.adj = buildGraph(city)
end

local style = {[0] = 'dotted', 'dashed', 'solid'}

local function id(i)
    local d, c = districtIx(i)
    return d + c / 10
end

function Graph:todot(title)
    local s = 'strict graph "' .. title .. '" {\n'
    for i, adj in pairs(self.adj) do
        local ix = districtIx(i)
        if i % 10 == 0 then
            s = s .. '  ' .. id(i) .. ' [label=' .. ix .. ', style=solid];\n'
        else
            s = s .. '  ' .. id(i) .. ' [label=' .. ix .. ', style=dotted];\n'
        end
        for j, w in pairs(adj) do
            if w ~= nil then
                s = s .. '  ' .. id(i) .. ' -- ' .. id(j) .. ' [style="' ..
                        style[w] .. '"];\n'
            end
        end
    end
    s = s .. '}\n'
    return s
end

function pathsFrom(self, from)
    from = nodeIx(from)
    local distances = {}
    local result = {}
    local visited = {}
    local queue = {{path = {from}, dist = 0}}

    distances[from] = 0

    while #queue > 0 do
        table.sort(queue, function(a, b) return a.dist > b.dist end)
        local current = table.remove(queue)
        local path = current.path
        local node = path[#path]
        local dist = current.dist

        if not visited[node] then

            if dist == 2 then
                local p = iter.map(path, districtIx)
                table.insert(result, p)
            else
                visited[node] = true
                for neighbor, weight in pairs(self.adj[node] or {}) do
                    local newDist = dist + weight

                    if newDist <= 2 and
                        (not distances[neighbor] or newDist <=
                            distances[neighbor]) then
                        distances[neighbor] = newDist
                        local newPath = {table.unpack(path)}
                        table.insert(newPath, neighbor)
                        table.insert(queue, {path = newPath, dist = newDist})
                    end
                end
            end
        end
    end

    return result
end

function Graph:squadPaths(from, to)
    return
        iter.filter(pathsFrom(self, from), function(p) return p[#p] == to end)
end

function Graph:adjacentTo(from)
    return iter.map(pathsFrom(self, from), function(p) return p[#p] end)
end

function Graph:vanPath(from, to, priority)
    from = nodeIx(from)
    to = nodeIx(to)
    local queue = {{from}}
    local visited = {}
    local queued = {}

    while #queue > 0 do
        local path = table.remove(queue, 1)
        local node = path[#path]

        if node == to then return iter.map(path, districtIx) end

        if not visited[node] then
            visited[node] = true
            if self.adj[node] then
                local neighbors = {}
                for neighbor, _ in pairs(self.adj[node]) do
                    table.insert(neighbors, neighbor)
                end
                table.sort(neighbors, function(a, b)
                    return priority(districtIx(a), districtIx(b))
                end)

                for _, neighbor in ipairs(neighbors) do
                    if not queued[neighbor] then
                        local newPath = {table.unpack(path)}
                        table.insert(newPath, neighbor)
                        table.insert(queue, newPath)
                        queued[neighbor] = true
                    end
                end
            end
        end
    end
end

-- TEST DATA
local xing = {adjacency = {1, 1, 1, 1}}
local tee = {adjacency = {0, 1, 1, 1}}
local hi = {highway = true}
local city1 = {
    districts = {
        {index = 1, rot = 3, props = xing}, {index = 2, rot = 2, props = xing},
        {index = 3, rot = 3, props = hi}, {index = 4, rot = 0, props = xing},
        {index = 5, rot = 0, props = xing}, {index = 6, rot = 0, props = xing},
        {index = 7, rot = 2, props = tee}, {index = 8, rot = 2, props = xing},
        {index = 9, rot = 3, props = xing}, {index = 10, rot = 2, props = hi},
        {index = 11, rot = 3, props = xing}, {index = 12, rot = 3, props = tee},
        {index = 13, rot = 0, props = xing},
        {index = 14, rot = 2, props = xing}, {index = 15, rot = 1, props = tee},
        {index = 16, rot = 2, props = xing},
        {index = 17, rot = 0, props = xing}, {index = 18, rot = 2, props = tee},
        {index = 19, rot = 2, props = xing},
        {index = 20, rot = 3, props = xing}, {index = 21, rot = 3, props = tee},
        {index = 22, rot = 1, props = xing},
        {index = 23, rot = 0, props = xing}, {index = 24, rot = 0, props = hi},
        {index = 25, rot = 3, props = xing}
    }
}
local city2 = {
    districts = {
        {index = 1, rot = 3, props = xing}, {index = 2, rot = 2, props = xing},
        {index = 3, rot = 3, props = hi}, {index = 4, rot = 0, props = xing},
        {index = 5, rot = 0, props = xing}, {index = 6, rot = 0, props = xing},
        {index = 7, rot = 2, props = tee}, {index = 8, rot = 2, props = xing},
        {index = 9, rot = 3, props = xing}, {index = 10, rot = 0, props = xing},
        {index = 11, rot = 3, props = xing}, {index = 12, rot = 3, props = tee},
        {index = 13, rot = 2, props = hi}, {index = 14, rot = 2, props = xing},
        {index = 15, rot = 1, props = tee}, {index = 16, rot = 2, props = xing},
        {index = 17, rot = 0, props = xing}, {index = 18, rot = 2, props = tee},
        {index = 19, rot = 2, props = xing},
        {index = 20, rot = 3, props = xing}, {index = 21, rot = 3, props = tee},
        {index = 22, rot = 1, props = xing},
        {index = 23, rot = 0, props = xing}, {index = 24, rot = 0, props = hi},
        {index = 25, rot = 3, props = xing}
    }
}
local city3 = {
    districts = {
        {index = 1, rot = 3, props = xing}, {index = 2, rot = 2, props = xing},
        {index = 3, rot = 2, props = xing}, {index = 4, rot = 0, props = xing},
        {index = 5, rot = 0, props = xing}, {index = 6, rot = 0, props = xing},
        {index = 7, rot = 2, props = tee}, {index = 8, rot = 3, props = hi},
        {index = 9, rot = 3, props = xing}, {index = 10, rot = 0, props = xing},
        {index = 11, rot = 3, props = tee}, {index = 12, rot = 3, props = xing},
        {index = 13, rot = 2, props = hi}, {index = 14, rot = 2, props = xing},
        {index = 15, rot = 1, props = tee}, {index = 16, rot = 2, props = xing},
        {index = 17, rot = 0, props = xing}, {index = 18, rot = 2, props = tee},
        {index = 19, rot = 2, props = xing},
        {index = 20, rot = 3, props = xing}, {index = 21, rot = 3, props = tee},
        {index = 22, rot = 1, props = xing},
        {index = 23, rot = 0, props = xing}, {index = 24, rot = 0, props = hi},
        {index = 25, rot = 3, props = xing}
    }
}
local city4 = {
    districts = {
        {index = 1, rot = 3, props = xing}, {index = 2, rot = 2, props = xing},
        {index = 3, rot = 2, props = xing}, {index = 4, rot = 0, props = xing},
        {index = 5, rot = 0, props = xing}, {index = 6, rot = 0, props = xing},
        {index = 7, rot = 2, props = tee}, {index = 8, rot = 3, props = hi},
        {index = 9, rot = 3, props = xing}, {index = 10, rot = 0, props = xing},
        {index = 11, rot = 3, props = xing}, {index = 12, rot = 0, props = hi},
        {index = 13, rot = 2, props = hi}, {index = 14, rot = 2, props = xing},
        {index = 15, rot = 1, props = tee}, {index = 16, rot = 2, props = xing},
        {index = 17, rot = 0, props = xing}, {index = 18, rot = 2, props = tee},
        {index = 19, rot = 2, props = xing},
        {index = 20, rot = 3, props = xing}, {index = 21, rot = 3, props = tee},
        {index = 22, rot = 1, props = xing},
        {index = 23, rot = 0, props = xing}, {index = 24, rot = 3, props = tee},
        {index = 25, rot = 3, props = xing}
    }
}

-- local path = Graph(city1):vanPath(2, 15, function(a, b) return city1.districts[a].index > city1.districts[b].index end)
-- print('path is ', JSON.encode(path))
-- local path = Graph(city1):vanPath(2, 15, function(a, b) return city1.districts[a].index < city1.districts[b].index end)
-- print('path is ', JSON.encode(path))

return Graph
