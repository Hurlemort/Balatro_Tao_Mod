SANS.attackmath = SANS.attackmath or {}

-- Who loves maths?????

function SANS.attackmath.Resolve(active, raw)
    if raw == nil then return nil end
    if type(raw) == "string" and raw:sub(1, 1) == "$" then
        local name = raw:sub(2)
        local value = active.vars[name]
        if value == nil then
            print(string.format("[SANS][ATTACKmath] '%s' referenced undefined variable $%s", active.name, name))
            return 0
        end
        return value
    end
    return tonumber(raw) or raw
end

function SANS.attackmath.ResolveArgs(active, rawArgs)
    local out = {}
    local n = rawArgs.n or #rawArgs
    for i = 1, n do
        out[i] = SANS.attackmath.Resolve(active, rawArgs[i])
    end
    out.n = n
    return out
end

local function ResolveTarget(active, rawTarget)
    local target = SANS.attackmath.Resolve(active, rawTarget)
    return active.labels[target] or tonumber(target)
end

-- Operations need to be able to read/write so here is their little bedroom, aren't they cute?
SANS.attackmath.ops = {}
local ops = SANS.attackmath.ops
local Resolve = SANS.attackmath.Resolve

-- guards against a.vars[nil] crashing the game on a malformed attack csv row
local function SetVar(a, key, value)
    if key == nil then
        print(string.format("[SANS][ATTACKmath] '%s' is missing a destination variable name", a.name))
        return
    end
    a.vars[key] = value
end

ops.SET = function(a, args)
    SetVar(a, args[1], Resolve(a, args[2]))
end

ops.ADD = function(a, args)
    SetVar(a, args[1], (Resolve(a, args[2]) or 0) + (Resolve(a, args[3]) or 0))
end

ops.SUB = function(a, args)
    SetVar(a, args[1], (Resolve(a, args[2]) or 0) - (Resolve(a, args[3]) or 0))
end

ops.MUL = function(a, args)
    SetVar(a, args[1], (Resolve(a, args[2]) or 0) * (Resolve(a, args[3]) or 0))
end

ops.DIV = function(a, args)
    local x, y = Resolve(a, args[2]) or 0, Resolve(a, args[3]) or 0
    SetVar(a, args[1], (y ~= 0) and (x / y) or 0)
end

ops.MOD = function(a, args)
    local x, y = Resolve(a, args[2]) or 0, Resolve(a, args[3]) or 0
    SetVar(a, args[1], (y ~= 0) and (x % y) or 0)
end

ops.FLOOR = function(a, args)
    SetVar(a, args[1], math.floor(Resolve(a, args[2]) or 0))
end

ops.DEG = function(a, args)
    SetVar(a, args[1], math.deg(Resolve(a, args[2]) or 0))
end

ops.RAD = function(a, args)
    SetVar(a, args[1], math.rad(Resolve(a, args[2]) or 0))
end

ops.SIN = function(a, args)
    SetVar(a, args[1], math.sin(math.rad(Resolve(a, args[2]) or 0)))
end

ops.COS = function(a, args)
    SetVar(a, args[1], math.cos(math.rad(Resolve(a, args[2]) or 0)))
end

-- Funny because i need to take the raw degrees, convert to radians then re-convert to degrees for the futur math that will re-re-convert to radians lmao
ops.ANGLE = function(a, args)
    local x1, y1 = Resolve(a, args[2]) or 0, Resolve(a, args[3]) or 0
    local x2, y2 = Resolve(a, args[4]) or 0, Resolve(a, args[5]) or 0
    local deg = math.deg(math.atan2(y2 - y1, x2 - x1))
    if deg < 0 then deg = deg + 360 end
    SetVar(a, args[1], deg)
end

ops.RND = function(a, args)
    local n = math.max(0, math.floor(Resolve(a, args[2]) or 0) - 1)
    SetVar(a, args[1], love.math.random(0, n))
end

ops.GetHeartPos = function(a, args)
    local heart = SANS.images and SANS.images.PlayerHeart
    SetVar(a, args[1], heart and heart.x or 0)
    SetVar(a, args[2], heart and heart.y or 0)
end

ops.JMPABS = function(a, args)
    return ResolveTarget(a, args[1])
end

ops.JMPREL = function(a, args)
    return a.pc + (tonumber(Resolve(a, args[1])) or 0)
end

ops.JMPZ = function(a, args)
    if (Resolve(a, args[2]) or 0) == 0 then return ResolveTarget(a, args[1]) end
end

ops.JMPNZ = function(a, args)
    if (Resolve(a, args[2]) or 0) ~= 0 then return ResolveTarget(a, args[1]) end
end

ops.JMPE = function(a, args)
    if Resolve(a, args[2]) == Resolve(a, args[3]) then return ResolveTarget(a, args[1]) end
end

ops.JMPNE = function(a, args)
    if Resolve(a, args[2]) ~= Resolve(a, args[3]) then return ResolveTarget(a, args[1]) end
end

ops.JMPL = function(a, args)
    if (Resolve(a, args[2]) or 0) < (Resolve(a, args[3]) or 0) then return ResolveTarget(a, args[1]) end
end

ops.JMPNL = function(a, args)
    if (Resolve(a, args[2]) or 0) >= (Resolve(a, args[3]) or 0) then return ResolveTarget(a, args[1]) end
end

ops.JMPG = function(a, args)
    if (Resolve(a, args[2]) or 0) > (Resolve(a, args[3]) or 0) then return ResolveTarget(a, args[1]) end
end

ops.JMPNG = function(a, args)
    if (Resolve(a, args[2]) or 0) <= (Resolve(a, args[3]) or 0) then return ResolveTarget(a, args[1]) end
end
