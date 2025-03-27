local Object = require 'tts/classic'

local Pattern = Object:extend('Pattern')

function Pattern:points() return {} end

Pattern.none = Pattern()

Pattern.fromSnaps = Pattern:extend()

function Pattern.fromSnaps:new(snaps) self.snaps = snaps end

function Pattern.fromSnaps:points() return self.snaps end

Pattern.pile = Pattern:extend()

function Pattern.pile:new(params)
    self.point = params.point
    self.height = params.height
end

function Pattern.pile:points(n)
    local pts = {}
    local pt = Vector(self.point.position)
    for i = 0, n - 1 do
        table.insert(pts, {
            position = pt + Vector(0, (self.height + 0.1) * i + 0.1, 0),
            rotation = self.point.rotation
        })
    end
    return pts
end

Pattern.squares = Pattern:extend()

function Pattern.squares:new(params)
    self.center = params.center
    self.spreadH = params.spread or params.spreadH
    self.spreadV = params.spread or params.spreadV
    self.rotation = params.rotation
end

local squarePatterns = {
    {{0, 0}}, {{-0.5, 0}, {0.5, 0}}, {{-1, 0}, {0, 0}, {1, 0}},
    {{-0.5, -0.5}, {0.5, -0.5}, {-0.5, 0.5}, {0.5, 0.5}},
    {{-1, -0.5}, {0, -0.5}, {1, -0.5}, {-0.5, 0.5}, {0.5, 0.5}},
    {{-1, -0.5}, {0, -0.5}, {1, -0.5}, {-1, 0.5}, {0, 0.5}, {1, 0.5}}, {
        {-1.5, -0.5}, {-0.5, -0.5}, {0.5, -0.5}, {1.5, -0.5}, {-1, 0.5},
        {0, 0.5}, {1, 0.5}
    }, {
        {-1.5, -0.5}, {-0.5, -0.5}, {0.5, -0.5}, {1.5, -0.5}, {-1.5, 0.5},
        {-0.5, 0.5}, {0.5, 0.5}, {1.5, 0.5}
    },
    {
        {-1, -1}, {0, -1}, {1, -1}, {-1, 0}, {0, 0}, {1, 0}, {-1, 1}, {0, 1},
        {1, 1}
    }, {
        {-1.5, -1}, {-0.5, -1}, {0.5, -1}, {1.5, -1}, {-1.5, 0}, {-0.5, 0},
        {0.5, 0}, {1.5, 0}, {-0.5, 1}, {0.5, 1}
    }, {
        {-1.5, -1}, {-0.5, -1}, {0.5, -1}, {1.5, -1}, {-1.5, 0}, {-0.5, 0},
        {0.5, 0}, {1.5, 0}, {-1, 1}, {0, 1}, {1, 1}
    }, {
        {-1.5, -1}, {-0.5, -1}, {0.5, -1}, {1.5, -1}, {-1.5, 0}, {-0.5, 0},
        {0.5, 0}, {1.5, 0}, {-1.5, 1}, {-0.5, 1}, {0.5, 1}, {1.5, 1}
    }, {
        {-1.5, -1.5}, {-0.5, -1.5}, {0.5, -1.5}, {1.5, -1.5}, {-1.5, -0.5},
        {-0.5, -0.5}, {0.5, -0.5}, {1.5, -0.5}, {-1.5, 0.5}, {-0.5, 0.5},
        {0.5, 0.5}, {1.5, 0.5}, {0, 1.5}
    }, {
        {-1.5, -1.5}, {-0.5, -1.5}, {0.5, -1.5}, {1.5, -1.5}, {-1.5, -0.5},
        {-0.5, -0.5}, {0.5, -0.5}, {1.5, -0.5}, {-1.5, 0.5}, {-0.5, 0.5},
        {0.5, 0.5}, {1.5, 0.5}, {-0.5, 1.5}, {0.5, 1.5}
    }, {
        {-1.5, -1.5}, {-0.5, -1.5}, {0.5, -1.5}, {1.5, -1.5}, {-1.5, -0.5},
        {-0.5, -0.5}, {0.5, -0.5}, {1.5, -0.5}, {-1.5, 0.5}, {-0.5, 0.5},
        {0.5, 0.5}, {1.5, 0.5}, {-1, 1.5}, {0, 1.5}, {1, 1.5}
    }, {
        {-1.5, -1.5}, {-0.5, -1.5}, {0.5, -1.5}, {1.5, -1.5}, {-1.5, -0.5},
        {-0.5, -0.5}, {0.5, -0.5}, {1.5, -0.5}, {-1.5, 0.5}, {-0.5, 0.5},
        {0.5, 0.5}, {1.5, 0.5}, {-1.5, 1.5}, {-0.5, 1.5}, {0.5, 1.5}, {1.5, 1.5}
    }
}

function Pattern.squares:points(n)
    if n == 0 then return {} end
    if n > #squarePatterns then return self:points(#squarePatterns) end
    local pts = {}
    local pt = Vector(self.center.position)
    local pattern = squarePatterns[n]
    for _, m in pairs(pattern) do
        table.insert(pts, {
            position = pt +
                Vector(m[1] * self.spreadH, 0, m[2] * self.spreadV):rotateOver(
                    'y', self.rotation),
            rotation = self.center.rotation
        })
    end
    return pts
end

Pattern.rows = Pattern:extend()

function Pattern.rows:new(params)
    self.corner = params.corner
    self.width = params.width
    self.spreadH = params.spread or params.spreadH
    self.spreadV = params.spread or params.spreadV
end

function Pattern.rows:points(n)
    local pts = {}
    local pt = Vector(self.corner.position)
    local r = 0
    local c = 0
    for i = 1, n do
        table.insert(pts, {
            position = pt + Vector(c * self.spreadH, 0, r * self.spreadV),
            rotation = self.corner.rotation
        })
        c = c + 1
        if c == self.width then
            r = r + 1
            c = 0
        end
    end
    return pts
end

Pattern.columns = Pattern:extend()

function Pattern.columns:new(params)
    self.corner = params.corner
    self.height = params.height
    self.spreadH = params.spread or params.spreadH
    self.spreadV = params.spread or params.spreadV
end

function Pattern.columns:points(n)
    local pts = {}
    local pt = Vector(self.corner.position)
    local r = 0
    local c = 0
    for i = 1, n do
        table.insert(pts, {
            position = pt + Vector(c * self.spreadH, 0, r * self.spreadV),
            rotation = self.corner.rotation
        })
        r = r + 1
        if r == self.height then
            r = 0
            c = c + 1
        end
    end
    return pts
end

return Pattern
