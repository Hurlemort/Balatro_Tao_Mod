SANS.attackrunner = SANS.attackrunner or {}

local unpack = table.unpack or unpack


-- csv rows are: delay, function name, args... and a row starting with ":Name" declares a label


-- Splits a single csv line into raw string fields (no quoting in this format)
local function SplitCSVLine(line)
    local fields = {}
    for field in (line .. ","):gmatch("(.-),") do
        table.insert(fields, field)
    end
    return fields
end

-- Parses full csv content into a flat instruction list plus a label
function SANS.attackrunner.ParseAttack(content)
    local instructions = {}
    local labels = {}

    for rawLine in (content .. "\n"):gmatch("(.-)\r?\n") do
        if rawLine ~= "" then
            local fields = SplitCSVLine(rawLine)
            local delayField = fields[1] or "0"
            local second = fields[2] or ""
            local instruction = { delay = tonumber(delayField), delayRaw = delayField }

            if second:sub(1, 1) == ":" then
                instruction.label = second:sub(2)
            else
                instruction.name = second
                -- blank fields become positional nils; args.n tracks the real count
                local args = {}
                for i = 3, #fields do
                    args[i - 2] = fields[i] ~= "" and fields[i] or nil
                end
                args.n = #fields - 2
                instruction.args = args
            end

            table.insert(instructions, instruction)
            if instruction.label then
                labels[instruction.label] = #instructions
            end
        end
    end

    return instructions, labels
end


-- Dispatch

-- 2 types of commands : attacks (attackrunner) and operation (ops)

function SANS.attackrunner.Dispatch(active, line)
    local name = line.name
    local mathOp = SANS.attackmath.ops[name]
    if mathOp then
        return mathOp(active, line.args or {})
    end

    local fn = SANS.attackloader[name]
    if fn then
        local resolved = SANS.attackmath.ResolveArgs(active, line.args or {})
        fn(unpack(resolved, 1, resolved.n))
    else
        local args = line.args or {}
        local parts = {}
        for i = 1, args.n or #args do
            parts[i] = tostring(args[i])
        end
        print(string.format("[SANS][ATTACK] (unimplemented) %s(%s)", tostring(name), table.concat(parts, ", ")))
    end
end


-- Loading + sequencing

-- Reads and parses an attack file by name (without extension) from Sans/attacks
function SANS.attackrunner.LoadAttack(name)
    local base = SANS.path or ""
    local last = base:sub(-1)
    if last ~= "/" and last ~= "\\" then
        base = base .. "/"
    end

    local full_path = base .. "attacks/" .. name .. ".csv"

    local ok, file_data = pcall(NFS.newFileData, full_path)
    if not ok or not file_data then
        print("[SANS][ATTACK] Could not find attack file: " .. full_path)
        return nil
    end

    return SANS.attackrunner.ParseAttack(file_data:getString())
end

function SANS.attackrunner.StartAttack(name)
    SANS.MENU.state = false
    SANS.ClearHighlight()

    -- snapshot karma right here, at the moment the player commits to this round, not whatever it's drifted to once the attack ends
    SANS.MENU.karmaSnapshot = SANS.player.kr

    -- clean slate before this attack's own instructions run
    SANS.attackloader.ResetVars()
    SANS.MenuBonesOff() -- see menu.lua's MenuBones section - mirrors the source's "Call ResetVars, Call MenuBonesOff" pairing at StartAttack

    if not name then
        print("[SANS][ATTACK] StartAttack called without an attack name")
        return
    end

    local instructions, labels = SANS.attackrunner.LoadAttack(name)
    if not instructions then
        return
    end

    -- megalovania picks back up here after the mercy monologue swapped it to the chokedup track
    if name == "sans_multi1" then
        SANS.PlayMusic("mus_zz_megalovania")
    end

    SANS.attackrunner.active = {
        name = name,
        instructions = instructions,
        labels = labels,
        pc = 1,
        elapsed = 0,
        vars = { pi = math.pi }, -- $pi is read but never SET anywhere : manual setting
    }

    print("[SANS][ATTACK] Starting attack '" .. name .. "' (" .. #instructions .. " lines)")
end

-- panic button
local MAX_ITERATIONS_PER_UPDATE = 10000

-- Walks the active attack's timeline (called every fixed update tick while not in the menu)
function SANS.attackrunner.Update(dt)
    local active = SANS.attackrunner.active
    if not active or active.paused then return end

    active.elapsed = active.elapsed + dt
    local iterations = 0

    while active and not active.paused do
        local line = active.instructions[active.pc]
        if not line then
            print("[SANS][ATTACK] '" .. active.name .. "' ran out of lines without an EndAttack")
            SANS.attackrunner.active = nil
            return
        end

        local delay = line.delay
        if delay == nil then
            delay = tonumber(SANS.attackmath.Resolve(active, line.delayRaw)) or 0
        end

        if active.elapsed < delay then
            return
        end

        active.elapsed = active.elapsed - delay

        if line.label then
            active.pc = active.pc + 1
        else
            local newPc = SANS.attackrunner.Dispatch(active, line)
            active.pc = newPc or (active.pc + 1)
        end

        active = SANS.attackrunner.active -- Dispatch may have ended the attack (e.g. EndAttack)

        iterations = iterations + 1
        if iterations > MAX_ITERATIONS_PER_UPDATE then
            print(string.format("[SANS][ATTACK] '%s' exceeded %d instructions in a single Update - deferring to next frame",
                active and active.name or "?", MAX_ITERATIONS_PER_UPDATE))
            return
        end
    end
end

-- driven by hitAttempts: phase 1 below 13, sans_spare once at exactly 13, phase 2 for 14-22, sans_final from 23 on (sans_intro isn't in here, it launches separately on "u")
local PHASE1_SEQUENCE = {
    "sans_bonegap1",
    "sans_bluebone",
    "sans_bonegap2",
    "sans_platforms1",
    "sans_platforms2",
    "sans_platforms3",
    "sans_platforms4",
    "sans_platformblaster",
    "sans_platforms4hard",
    "sans_bonegap1fast",
    "sans_boneslideh",
    "sans_bonegap2",
    "sans_platformblasterfast",
}
local PHASE1_POOL = {
    "sans_bonegap1fast",
    "sans_bonegap2",
    "sans_boneslideh",
    "sans_platformblasterfast",
}

local PHASE2_SEQUENCE = {
    "sans_multi1",
    "sans_randomblaster1",
    "sans_multi2",
    "sans_bonestab1",
    "sans_bonestab2",
    "sans_randomblaster2",
    "sans_boneslidev",
    "sans_multi3",
    "sans_bonestab3",
}
local PHASE2_POOL = {
    "sans_bonestab3",
    "sans_multi3",
    "sans_randomblaster2",
}

SANS.attackrunner.nextAttackIndex = SANS.attackrunner.nextAttackIndex or 0 -- 0-based, matches the source's SansLegs.NextAttack

-- Picks the next attack per SANS.hitAttempts (see above), then starts it.
function SANS.attackrunner.RunNextAttack()
    local hits = SANS.hitAttempts
    local index = SANS.attackrunner.nextAttackIndex
    local name

    if hits < 13 then
        if index < #PHASE1_SEQUENCE then
            name = PHASE1_SEQUENCE[index + 1]
            SANS.attackrunner.nextAttackIndex = index + 1
        else
            name = PHASE1_POOL[love.math.random(#PHASE1_POOL)]
        end
    elseif hits == 13 and not SANS.attackrunner.sparePlayed then
        -- sparePlayed keeps sans_spare a genuine one-shot, otherwise a timeout would replay it forever
        name = "sans_spare"
        SANS.attackrunner.sparePlayed = true
        SANS.attackrunner.nextAttackIndex = 0
    elseif hits <= 22 then
        if index < #PHASE2_SEQUENCE then
            name = PHASE2_SEQUENCE[index + 1]
            SANS.attackrunner.nextAttackIndex = index + 1
        else
            name = PHASE2_POOL[love.math.random(#PHASE2_POOL)]
        end
    else -- hits > 22
        name = "sans_final"
    end

    SANS.attackrunner.StartAttack(name)
end

-- Rewinds back to the start of the sequence (e.g. for a fresh session)
function SANS.attackrunner.ResetAttackSequence()
    SANS.attackrunner.nextAttackIndex = 0
    SANS.hitAttempts = 0
    SANS.attackrunner.musicStarted = false
    SANS.attackrunner.sparePlayed = false
end
