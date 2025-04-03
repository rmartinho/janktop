local Object = require 'tts/classic'

local Graph = Object:extend('Graph')

function fromIx(i)
    local x = (i - 1) % 5 + 1
    local y = math.ceil(i / 5)
    return x, y
end

function toIx(p) return (p[2] - 1) * 5 + p[1] end

local function valid(p)
    return p[1] <= 5 and p[1] >= 1 and p[2] <= 5 and p[2] >= 1
end

local function connect(g, i, j)
    g[i] = g[i] or {}
    g[i][j] = true
end

function buildGraph(city)
    local g = {}
    for _, district in ipairs(city.districts) do
        local deltas = {
            {1, 0}, {0, 1}, {-1, 0}, {0, -1}, {1, 0}, {0, 1}, {-1, 0}, {0, -1}
        }
        local x, y = fromIx(district.index)
        if district.props.highway then
            for i = 1, 2 do
                local d1 = deltas[district.rot % 2 + 2 * i - 1]
                local d2 = deltas[district.rot % 2 + 2 * i]
                local p1 = {x + d1[1], y + d1[2]}
                local p2 = {x + d2[1], y + d2[2]}
                if valid(p1) and valid(p2) then
                    connect(g, toIx(p1), toIx(p2))
                    connect(g, toIx(p2), toIx(p1))
                end
            end
        else
            local baseAdj = district.props.adjacency
            for i = 1, 4 do
                if baseAdj[i] == 1 then
                    local d = deltas[district.rot + i]
                    local p = {x + d[1], y + d[2]}
                    if valid(p) then
                        connect(g, district.index, toIx(p))
                    end
                end
            end
        end
    end
    for i, a in pairs(g) do
        for j, _ in pairs(a) do
            if not g[j] or not g[j][i] then g[i][j] = nil end
        end
    end
    return g
end

function Graph:new(city)
    self.city = city
    self.adj = buildGraph(city)
end

function Graph:adjacentTo(node)
    local nodes = {}
    if self.adj[node] then
        for n, ok in pairs(self.adj[node]) do
            if ok then table.insert(nodes, n) end
        end
    end
    return nodes
end

function Graph:vanPath(from, to, priority)
    local queue = {{from}}
    local visited = {}
    local queued = {}

    while #queue > 0 do
        local path = table.remove(queue, 1)
        local node = path[#path]

        if node == to then return path end

        if not visited[node] then
            visited[node] = true
            if self.adj[node] then
                local neighbors = {}
                for neighbor, _ in pairs(self.adj[node]) do
                    table.insert(neighbors, neighbor)
                end
                table.sort(neighbors, priority)

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

return Graph
