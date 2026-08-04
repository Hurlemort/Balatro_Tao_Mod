-- just the hook wrappers, each one decides whether to pass through to the original or dispatch into SANS.hooks
SANS = SANS or {}
SANS.hooks = SANS.hooks or {}

if SANS._engineHooksInstalled then return end
SANS._engineHooksInstalled = true

-- Update hook (once the fight ends, SANS.heartDeath keeps ticking through the shatter fade alongside the real game)
local update_hook = Game.update
local function update(self, dt)
    if SANS.state then
        -- new_round() is still mid-setup when the blind hook freezes us, so let it finish behind the cutscene
        -- instead of leaving its blocking delays and hand draw queued up to fire after the fight
        if SANS.awaitingRoundSetup then
            update_hook(self, dt)
            SANS.roundSetupTimer = (SANS.roundSetupTimer or 0) + dt
            if G.STATE == G.STATES.SELECTING_HAND or SANS.roundSetupTimer > 8 then
                SANS.awaitingRoundSetup = false
            end
        end
        SANS.hooks.Update(dt)
    else
        update_hook(self, dt)
        if SANS.heartDeath then SANS.UpdateHeartDeath(dt) end
    end
end
Game.update = update

-- Draw hook (same handoff as Update; the fade overlay draws on top of the real game underneath)
local draw_hook = love.draw or function() end
local function draw()
    if SANS.state then
        SANS.hooks.Draw()
    else
        draw_hook()
        if SANS.heartDeath then SANS.hooks.DrawDeathFade() end
    end
end
love.draw = draw

-- Load hook (no condition : needs to be loaded from the start))
local load_hook = love.load or function() end
local function load()
    load_hook()
    SANS.hooks.Load()
end
love.load = load

-- the fight only ever starts via actually selecting the Sans blind
local keypressed_hook = love.keypressed
local function keypressed(key, scancode, isrepeat)
    if not SANS.state then
        keypressed_hook(key, scancode, isrepeat)
    else
        SANS.hooks.Keypressed(key, scancode, isrepeat)
    end
end
love.keypressed = keypressed
