local Object = require 'tts/classic'

local Graph = Object:extend('Graph')

function buildGraph(city)
    local adjs = {}
    for _, district in ipairs(city.districts) do
        -- TODO highways
        local baseAdj = district.props.adjacency
        local deltas = {
            {0, -1}, {1, 0}, {0, 1}, {-1, 0}, {0, -1}, {1, 0}, {0, 1}, {-1, 0}
        }
        local adj = {}
        local x = (district.index - 1) % 5 + 1
        local y = math.ceil(district.index / 5)
        for i = 1, 4 do
            if baseAdj[i] == 1 then
                local delta = deltas[4 - district.rotN + i]
                local pos = {x + delta[1], y + delta[2]}
                local ix = (pos[2] - 1) * 5 + pos[1]
                if pos[1] <= 5 and pos[1] >= 1 and pos[2] <= 5 and pos[2] >= 1 then
                    adj[ix] = true
                end
            end
        end
        table.insert(adjs, adj)
    end
    for i, adj in pairs(adjs) do
        for j, _ in pairs(adj) do
            if not adjs[j] or not adjs[j][i] then adjs[i][j] = nil end
        end
    end
    return adjs
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
