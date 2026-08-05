SANS.karma = SANS.karma or { km_t = 0 }

-- will be adjusted in the future
SANS.heartHurtboxSize = SANS.heartHurtboxSize or 4

-- "l" toggle: playtest invincibility, blocks HP loss in DamagePlayer but still plays the hit sound
if SANS.invincible == nil then SANS.invincible = false end

function SANS.GetHeartHurtbox()
    local heart = SANS.images.PlayerHeart
    if not heart then return nil end

    local minX, minY, maxX, maxY = SANS.GetImageBBox(heart)
    local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2
    local half = SANS.heartHurtboxSize / 2

    return cx - half, cy - half, SANS.heartHurtboxSize, SANS.heartHurtboxSize
end

local function RectsOverlap(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and ax + aw > bx and ay < by + bh and ay + ah > by
end

-- function to know if a point is inside a rotated rectangle (used for gaster blast)
local function PointInBlast(px, py, ox, oy, rad, length, halfHeight, margin)
    local dx, dy = px - ox, py - oy
    local cosr, sinr = math.cos(-rad), math.sin(-rad)
    local localX = dx * cosr - dy * sinr
    local localY = dx * sinr + dy * cosr

    return localX >= -margin and localX <= length + margin
        and localY >= -(halfHeight + margin) and localY <= (halfHeight + margin)
end

-- function for direct damage
function SANS.DamagePlayer(amount)
    if SANS.heartDeath or SANS.player.hp <= 0 then return end

    if SANS.invincible then
        SANS.PlaySound("PlayerDamaged", 1) -- still audible feedback that a hit landed, just no HP cost
        return
    end

    SANS.player.hp = math.max(0, SANS.player.hp - amount)
    SANS.PlaySound("PlayerDamaged", 1)

    if SANS.player.hp <= 0 then
        SANS.TriggerHeartDeath()
    end
end

-- for blue attacks
local function IsHeartMoving(heart)
    if love.keyboard.isDown("left") or love.keyboard.isDown("right") then
        return true
    end

    if SANS.heartMode == 1 then
        return (heart.vx or 0) ~= 0 or (heart.vy or 0) ~= 0 or not heart.grounded
    else
        return love.keyboard.isDown("up") or love.keyboard.isDown("down")
    end
end

-- resolves one entity's contact this tick without touching player hp/kr directly, karma degrades to 2 permanently after the first hit
local function ResolveBulletContact(entity, touching)
    if not touching then return 0, false end

    local karma = entity.karma
    if entity.karma >= 3 then
        entity.karma = 2
    end
    return karma, true
end

local CONTACT_TICK = 1 / 30
SANS.karma.contactTimer = SANS.karma.contactTimer or 0

-- updates karma
function SANS.UpdateKarma(dt)
    SANS.karma.contactTimer = SANS.karma.contactTimer + dt
    if SANS.karma.contactTimer < CONTACT_TICK then return end
    SANS.karma.contactTimer = SANS.karma.contactTimer - CONTACT_TICK

    local heart = SANS.images.PlayerHeart
    local hx, hy, hw, hh = SANS.GetHeartHurtbox()
    if not hx then return end
    local hcx, hcy = hx + hw / 2, hy + hh / 2
    local heartMoving = heart and IsHeartMoving(heart)

    -- worst single hazard this tick is the cap, otherwise overlapping bones stack damage way too fast
    local bestKarma, dealsDamage = 0, false

    for _, img in pairs(SANS.images) do
        if img.isAttack and img.karma then
            local touching

            if img.isGasterBlaster then
                -- fading beam stops hurting once its opacity drops to 80 or below
                if img.beamVisible and (img.beamOpacity or 100) > 80 then
                    local rad = img.ang * math.pi / 180
                    local scale = img.heightScale / 2
                    local segX = img.x + math.cos(rad) * 70 * scale
                    local segY = img.y + math.sin(rad) * 70 * scale
                    -- real hitbox is its own object (BaseSize*3/4, no sine wobble), not the same size as the visual beam
                    local halfHeight = img.beamBaseSize * 3 / 4 / 2
                    local margin = math.max(hw, hh) / 2

                    touching = PointInBlast(hcx, hcy, segX, segY, rad, 1000, halfHeight, margin)
                else
                    touching = false
                end
            elseif img.isBoneStab then
                local bx, by, bw, bh = SANS.GetBoneStabRect(img)
                touching = RectsOverlap(hx, hy, hw, hh, bx, by, bw, bh)
            else
                touching = RectsOverlap(hx, hy, hw, hh, img.x, img.y, img.width or 0, img.height or 0)
            end

            -- blue bones don't hurt at all while the heart's holding still
            if touching and img.color and not heartMoving then
                touching = false
            end

            local karma, damage = ResolveBulletContact(img, touching)
            if karma > bestKarma then bestKarma = karma end
            if damage then dealsDamage = true end
        end
    end

    if bestKarma > 0 then
        SANS.player.kr = math.min(SANS.player.max_kr, SANS.player.kr + bestKarma)
    end
    if dealsDamage then
        SANS.DamagePlayer(1)
    end
end

-- main karma event : poison effect, drains 1 hp per tier-based interval while kr>0 and hp>1, never kills outright
function SANS.UpdateKarmaDrain(dt)
    local p = SANS.player
    local k = SANS.karma

    p.kr = math.min(p.kr, p.max_kr)
    if p.kr >= p.hp then
        p.kr = math.max(0, p.hp - 1) -- the max() keeps kr from going to -1 when hp hits 0 at death
    end

    if p.kr > 0 and p.hp > 1 then
        k.km_t = k.km_t + 1

        local drained = false

        if not drained and k.km_t >= 1 and p.kr >= 40 then
            k.km_t, p.hp, p.kr, drained = 0, p.hp - 1, p.kr - 1, true
        end
        if not drained and k.km_t >= 2 and p.kr >= 30 then
            k.km_t, p.hp, p.kr, drained = 0, p.hp - 1, p.kr - 1, true
        end
        if not drained and k.km_t >= 5 and p.kr >= 20 then
            k.km_t, p.hp, p.kr, drained = 0, p.hp - 1, p.kr - 1, true
        end
        if not drained and k.km_t >= 15 and p.kr >= 10 then
            k.km_t, p.hp, p.kr, drained = 0, p.hp - 1, p.kr - 1, true
        end
        if not drained and k.km_t >= 30 then
            k.km_t, p.hp, p.kr = 0, p.hp - 1, p.kr - 1
        end
    else
        k.km_t = 0
    end
end

-- Heart break/shatter death sequence: black screen+red heart, splits, shatters, then fades out over Balatro
local HEART_ALONE_TIME = 20 / 30 -- seconds showing just the (now-red) heart before it cracks
local HEART_SPLIT_TIME = 40 / 30 -- seconds showing the cracked-heart sprite before it shatters
local SHATTER_FADE_HOLD = 0.5 -- seconds the shards stay fully opaque after shattering
local SHATTER_FADE_OUT = 1.5 -- seconds spent fading to transparent after the hold

local SHARD_GRAVITY = 300
local SHARD_SPEED = 180

-- HeartShard1..4 are the 4 tumble-animation frames, not 4 distinct shard shapes
local SHARD_NAMES = { "HeartShard1", "HeartShard2", "HeartShard3", "HeartShard4" }
local SHARD_FRAME_COUNT = #SHARD_NAMES
local SHARD_ANIM_FPS = 15
local SHARD_FRAME_INTERVAL = 1 / SHARD_ANIM_FPS

SANS.heartDeath = SANS.heartDeath or nil

-- spawns the 4 shards flying outward, each staggered one tumble frame apart so they don't animate in lockstep
local function SpawnHeartShards(death)
    death.shards = {}

    -- loads the 4 tumble frames once, shared by every shard since they all cycle through the same set
    local frameImgs = {}
    for i, name in ipairs(SHARD_NAMES) do
        local key = SANS.LoadImage(name, 0, 0, death.rotation, death.scaleX, death.scaleY, false, death.color)
        frameImgs[i] = SANS.images[key].img
    end
    death.shardFrames = frameImgs

    for i, name in ipairs(SHARD_NAMES) do
        local shard = SANS.images[name]
        shard.visible = false -- never drawn generically; DrawHeartDeath draws it explicitly instead
        shard.frameIndex = i
        shard.frameTimer = 0
        shard.img = frameImgs[i]

        local minX, minY, maxX, maxY = SANS.GetImageBBox(shard)
        shard.x = death.centerX - (minX + maxX) / 2
        shard.y = death.centerY - (minY + maxY) / 2

        local angle = love.math.random() * 2 * math.pi
        shard.vx = math.cos(angle) * SHARD_SPEED
        shard.vy = math.sin(angle) * SHARD_SPEED

        table.insert(death.shards, name)
    end
end

-- triggers once when hp first reaches 0, heart turns red and sits alone on black before it actually cracks
function SANS.TriggerHeartDeath()
    if SANS.heartDeath then return end
    local heart = SANS.images.PlayerHeart
    if not heart then return end

    SANS.StopMusic()
    SANS.StopAllSounds() -- silence every ongoing one-shot too (e.g. a Gaster Blaster's firing sound mid-blast)
    SANS.DestroyAllAttacks() -- Battle.xml destroys every AttackSprite/AttackTiled/Attack9Patch the instant death triggers

    if SANS.heartMode ~= 0 then
        SANS.heartMode = 0
        SANS.UpdateHeartColor()
        heart = SANS.images.PlayerHeart -- UpdateHeartColor swaps in a freshly-recolored image entry
    end

    local minX, minY, maxX, maxY = SANS.GetImageBBox(heart)

    SANS.heartDeath = {
        state = "alone",
        timer = HEART_ALONE_TIME,
        centerX = (minX + maxX) / 2,
        centerY = (minY + maxY) / 2,
        rotation = heart.rotation,
        scaleX = heart.scaleX,
        scaleY = heart.scaleY,
        color = SANS.HEART_COLORS[0], -- always red by now, regardless of the HeartMode at time of death
    }
end

-- resets hp/karma state, called both when death finishes and defensively on fight re-entry
function SANS.ResetPlayerState()
    local p = SANS.player
    p.hp = p.max_hp
    p.kr = 0

    SANS.karma.km_t = 0
    SANS.karma.contactTimer = 0
end

-- clears the heart-death shard/crack images; deferred until the shatter fade finishes, or immediate on fight re-entry
function SANS.ClearHeartDeath()
    local death = SANS.heartDeath
    if not death then return end

    if death.shards then
        for _, key in ipairs(death.shards) do
            SANS.images[key] = nil
        end
    end
    if death.splitKey then
        SANS.images[death.splitKey] = nil
    end
    SANS.heartDeath = nil
end

-- 1 while the shards are fully opaque, fading to 0 over the back half of the shatter phase
function SANS.GetHeartDeathFadeAlpha()
    local death = SANS.heartDeath
    if not death or death.state ~= "shatter" then return 1 end
    if death.timer <= SHATTER_FADE_HOLD then return 1 end
    return math.max(0, 1 - (death.timer - SHATTER_FADE_HOLD) / SHATTER_FADE_OUT)
end

-- dying to Sans loses the run outright, same as running out of hands/discards against any other blind
function SANS.EndHeartDeath()
    if SANS.state then
        SANS.hooks.ToggleState()
    end
    SANS.ResetPlayerState()

    if G.STAGE == G.STAGES.RUN then
        G.STATE = G.STATES.GAME_OVER
        G.STATE_COMPLETE = false
    end
end

-- beats the boss blind outright; forces G.STATE to HAND_PLAYED before end_round(), same trick as DebugPlus's win cheat
function SANS.WinFight()
    if not (G.GAME and G.GAME.blind) then return end

    SANS.state = false -- hand control back unconditionally (no toggle; a toggle could flip the wrong way and restart the fight)
    SANS.StopMusic()

    G.GAME.chips = G.GAME.blind.chips
    G.STATE = G.STATES.HAND_PLAYED
    G.STATE_COMPLETE = true
    end_round()
    -- the badge waits out the round teardown so it lands on a settled screen
    G.E_MANAGER:add_event(Event({
        trigger = 'after',
        delay = 0.7,
        blocking = false,
        func = function()
            check_for_unlock({ type = "ach_tao_beat_sans" })
            return true
        end
    }))
end

-- what actually cracks the heart, once the "alone" hold finishes
local function StartHeartSplit(death)
    local heart = SANS.images.PlayerHeart
    if not heart then return end

    -- always red by now regardless of what heart mode the player was in
    local color = SANS.HEART_COLORS[0]

    local minX, minY, maxX, maxY = SANS.GetImageBBox(heart)
    local cx, cy = (minX + maxX) / 2, (minY + maxY) / 2

    heart.visible = false

    local key = SANS.LoadImage("PlayerHeart_Split", 0, 0, heart.rotation, heart.scaleX, heart.scaleY, false, color)
    local split = SANS.images[key]
    local sMinX, sMinY, sMaxX, sMaxY = SANS.GetImageBBox(split)
    split.x = cx - (sMinX + sMaxX) / 2
    split.y = cy - (sMinY + sMaxY) / 2

    SANS.PlaySound("HeartSplit", 1)

    death.state = "split"
    death.timer = HEART_SPLIT_TIME
    death.centerX = cx
    death.centerY = cy
    death.rotation = heart.rotation
    death.scaleX = heart.scaleX
    death.scaleY = heart.scaleY
    death.color = color
    death.splitKey = key
end

-- called every fixed tick regardless of menu state, alongside UpdateKarmaDrain
function SANS.UpdateHeartDeath(dt)
    local death = SANS.heartDeath
    if not death then return end

    if death.shards then
        for _, key in ipairs(death.shards) do
            local shard = SANS.images[key]
            if shard then
                shard.vy = shard.vy + SHARD_GRAVITY * dt
                shard.x = shard.x + shard.vx * dt
                shard.y = shard.y + shard.vy * dt

                -- cycle through the 4 tumble frames at a fixed 15fps, wrapping around, independent of dt granularity
                shard.frameTimer = shard.frameTimer + dt
                while shard.frameTimer >= SHARD_FRAME_INTERVAL do
                    shard.frameTimer = shard.frameTimer - SHARD_FRAME_INTERVAL
                    shard.frameIndex = shard.frameIndex % SHARD_FRAME_COUNT + 1
                    shard.img = death.shardFrames[shard.frameIndex]
                end
            end
        end
    end

    if death.state == "alone" then
        death.timer = death.timer - dt
        if death.timer <= 0 then
            StartHeartSplit(death)
        end
    elseif death.state == "split" then
        death.timer = death.timer - dt
        if death.timer <= 0 then
            SANS.PlaySound("HeartShatter", 1)
            SpawnHeartShards(death)
            death.state = "shatter"
            death.timer = 0
            SANS.EndHeartDeath() -- hands control back now; the fade overlay keeps drawing on top until SHATTER_FADE_HOLD+SHATTER_FADE_OUT elapses
        end
    elseif death.state == "shatter" then
        death.timer = death.timer + dt
        if death.timer >= SHATTER_FADE_HOLD + SHATTER_FADE_OUT then
            SANS.ClearHeartDeath()
        end
    end
end

-- draws just the heart/crack/shards, positions floored to avoid distortion; caller decides whether/how it's composited
function SANS.DrawHeartDeath()
    local death = SANS.heartDeath
    if not death then return end

    love.graphics.setColor(1, 1, 1, 1)
    if death.state == "alone" then
        local heart = SANS.images.PlayerHeart
        if heart then
            love.graphics.draw(heart.img, math.floor(heart.x), math.floor(heart.y), heart.rotation, heart.scaleX, heart.scaleY)
        end
    elseif death.state == "split" then
        local split = SANS.images[death.splitKey]
        if split then
            love.graphics.draw(split.img, math.floor(split.x), math.floor(split.y), split.rotation, split.scaleX, split.scaleY)
        end
    elseif death.state == "shatter" then
        for _, key in ipairs(death.shards) do
            local shard = SANS.images[key]
            if shard then
                love.graphics.draw(shard.img, math.floor(shard.x), math.floor(shard.y), shard.rotation, shard.scaleX, shard.scaleY)
            end
        end
    end
end
