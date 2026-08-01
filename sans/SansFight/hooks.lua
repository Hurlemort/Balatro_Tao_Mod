-- hooks for every hook needed : load, graphics, keypressed and game:update
SANS = SANS or {}
SANS.hooks = SANS.hooks or {}

local CHANNEL = love.thread.getChannel("sound_request")

-- Sound system
SANS.sound = SANS.sound or {}
SANS.sound.dataCache = SANS.sound.dataCache or {} -- decoded SoundData, cached per name
SANS.sound.sourcePools = SANS.sound.sourcePools or {} -- makes a few sources so that multiplesound can play at the same time

local function GetSoundData(name)
    if not SANS.sound.dataCache[name] then
        local base = SANS.path or ""
        local last = base:sub(-1)
        if last ~= "/" and last ~= "\\" then
            base = base .. "/"
        end

        local ok, file_data = pcall(NFS.newFileData, base .. "sounds/" .. name .. ".ogg")
        if not ok or not file_data then
            print("[SANS][SOUND] Could not find sound file: " .. name .. ".ogg")
            return nil
        end

        SANS.sound.dataCache[name] = love.sound.newSoundData(file_data)
    end
    return SANS.sound.dataCache[name]
end

-- all one-shot SFX get quieted down to this, no exceptions (SansSpeak included) - music (SANS.PlayMusic) has its own separate playback path, untouched
SANS.SFX_VOLUME = 0.5

-- only suppresses truly-simultaneous same-tick starts of a sound (e.g. 4 GasterBlasters at once) - reset every tick
SANS.sound.playedThisTick = SANS.sound.playedThisTick or {}

-- Plays a named sound. Optional volumeMult (0-1) scales SANS.SFX_VOLUME down further for this one play, e.g. the
-- spare ending's "NO WAIT THAT'S THE WRONG ONE" text getting quieter as the screen fades to black (dialogue.lua).
function SANS.PlaySound(name, pitch, volumeMult)
    if SANS.sound.playedThisTick[name] then return end

    local data = GetSoundData(name)
    if not data then return end

    SANS.sound.playedThisTick[name] = true

    local pool = SANS.sound.sourcePools[name]
    if not pool then
        pool = {}
        SANS.sound.sourcePools[name] = pool
    end

    local source
    for _, s in ipairs(pool) do
        if not s:isPlaying() then
            source = s
            break
        end
    end

    if not source then
        source = love.audio.newSource(data, "static")
        table.insert(pool, source)
    end

    source:setPitch(pitch or 1)
    source:setVolume(SANS.SFX_VOLUME * (volumeMult or 1))
    love.audio.play(source)
end

-- CSV: Sound(SoundName, Pitch)
function SANS.attackloader.Sound(SoundName, Pitch)
    SANS.PlaySound(SoundName, tonumber(Pitch) or 1)
end

-- Plays a named track (megalovania or spare music)
SANS.sound.music = SANS.sound.music or nil
SANS.musicPaused = SANS.musicPaused or false -- see SANS.SetMusicPaused (pauses the track during sans_multiX's BlackScreen flashes)

-- per-track volume overrides, default 1 if not listed here
local MUSIC_VOLUMES = {
    mus_zz_megalovania = 0.7,
}

function SANS.PlayMusic(name, pitch)
    if SANS.sound.music then
        SANS.sound.music:stop()
    end

    local data = GetSoundData(name)
    if not data then return end

    local source = love.audio.newSource(data, "static")
    source:setLooping(true)
    source:setPitch(pitch or 1)
    source:setVolume(MUSIC_VOLUMES[name] or 1)
    love.audio.play(source)
    SANS.sound.music = source
    SANS.musicPaused = false
end

function SANS.StopMusic()
    if SANS.sound.music then
        SANS.sound.music:stop()
        SANS.sound.music = nil
    end
end

-- pauses/resumes the music track in place, used by attackloader.BlackScreen
function SANS.SetMusicPaused(paused)
    SANS.musicPaused = paused
    if SANS.sound.music then
        if paused then
            SANS.sound.music:pause()
        else
            SANS.sound.music:play() -- resumes from the paused position, doesn't restart the track
        end
    end
end

-- stops every currently playing one-shot sound, used by the death sequence so nothing keeps ringing over the black screen
function SANS.StopAllSounds()
    for _, pool in pairs(SANS.sound.sourcePools) do
        for _, source in ipairs(pool) do
            source:stop()
        end
    end
end

-- Combat zone specs
SANS.combatZone = { left = 33, top = 251, right = 608, bottom = 391 } -- current
SANS.target_combatZone = { left = 33, top = 251, right = 608, bottom = 391 } -- destination
SANS.combatZoneResizeSpeed = 480 -- px/s each edge moves toward its target (see CombatZoneSpeed csv function)
SANS.combatZoneFinishAction = nil -- csv function name to call once the combat zone resize finishes

-- the 5px border sits INSIDE the combat zone rect, so csv coords address the outer rect but anything touching the walls uses the interior below
SANS.combatZoneBorder = 5
function SANS.GetCombatZoneInterior()
    local cz, b = SANS.combatZone, SANS.combatZoneBorder
    return cz.left + b, cz.top + b, cz.right - b, cz.bottom - b
end
SANS.heartMode = SANS.heartMode or 0 -- 0 red, 1 blue
SANS.blackScreen = false -- covers the whole 640x480 framebuffer in black while true (see BlackScreen csv function)

-- blue mode settings, values straight from Battle.xml
SANS.BlueHeart = SANS.BlueHeart or {
    jumpSpeed = 180,      -- in px/s upward speed applied once on the jump keypress
    jumpHoldCutoff = 30,  -- upward speed cap when jump is released
    maxFallSpeed = 750,   -- in px/s terminal falling speed (only reachable via slams - normal gravity cuts out at 240, see getBlueGravity)
    jumpBufferTime = 0.1, -- seconds a fresh "up" press is remembered before landing (see UpdateBlueHeartJump) - not a source value, added so precise jump-then-land-then-jump attacks work
}

-- Platform rectangle specs (see attackloader.Platform)
SANS.PlatformConfig = SANS.PlatformConfig or {
    height = 5,           -- thickness of both the white collision and green trigger rectangles
    triggerOffsetY = -3,  -- green sits this far above the collision rectangle's top (height - 3 = 2px overlap)
    triggerOffsetX = 1,   -- green is shifted this far right...
    triggerWidthTrim = 2, -- ...and this much narrower, so it ends up centered (1px inset per side)
}

-- Tint applied to the heart texture per HeartMode
SANS.HEART_COLORS = {
    [0] = { r = 1, g = 0, b = 0 },      -- red (Battle.xml Tint 100/0/0)
    [1] = { r = 0, g = 0.2353, b = 1 }, -- blue - #003CFF, the actual Undertale/C2 soul blue (Battle.xml Tint 0/23.53/100), not pure #0000FF
}
SANS.player = {max_hp = 92, max_kr = 40, hp = 92, kr = 0}

-- Images n animations table : useful for hiding
SANS.images = SANS.images or {}
SANS.attacksCount = SANS.attacksCount or {}

-- Moving platform rectangles (see attackloader.Platform)
SANS.platforms = SANS.platforms or {}

SANS.fonts = SANS.fonts or {}
SANS.player.name = "TAO"

-- hide all the images on screen except for the ones in the blacklist (must be loaded beforehand)
function SANS.HideAllImages(blacklist)
    for key, img in pairs(SANS.images) do
        if not blacklist[key] then
            SANS.images[key].visible = false
        end
    end
end

-- function made at the end of the attacks : remove all the images that are for attacks in SANS.images
function SANS.DestroyAllAttacks()
    for key, img in pairs(SANS.images) do
        if img and img.isAttack == true then
            SANS.images[key] = nil
        end
    end
    SANS.attacksCount = {}
    SANS.platforms = {}
    if SANS.animations then
        SANS.animations.text = nil
    end
end

-- moves the moving attack images + removes them whe nneeded
local OFFSCREEN_MARGIN = 64
function SANS.UpdateAttackImages(dt)
    for key, img in pairs(SANS.images) do
        local vx, vy = img.vx or 0, img.vy or 0
        if img.isAttack and (vx ~= 0 or vy ~= 0) then
            img.x = img.x + vx * dt
            img.y = img.y + vy * dt

            local exited = (vx > 0 and img.x > 640 + OFFSCREEN_MARGIN)
                or (vx < 0 and img.x < -OFFSCREEN_MARGIN)
                or (vy > 0 and img.y > 480 + OFFSCREEN_MARGIN)
                or (vy < 0 and img.y < -OFFSCREEN_MARGIN)

            if exited then
                SANS.images[key] = nil
            end
        end
    end
end

function SANS.IsImageInCombatZone(img)
    local combatZone = SANS.combatZone
    local w = img.width or (img.img and img.img:getWidth() * math.abs(img.scaleX or 1)) or 0
    local h = img.height or (img.img and img.img:getHeight() * math.abs(img.scaleY or 1)) or 0

    return img.x < combatZone.right and img.x + w > combatZone.left
        and img.y < combatZone.bottom and img.y + h > combatZone.top
end

-- rotation-aware bounding box (min_x, min_y, max_x, max_y), shared by the heart clamp and the platform trigger check
function SANS.GetImageBBox(img)
    local w, h = img.img:getWidth(), img.img:getHeight()
    local sx, sy = img.scaleX or 1, img.scaleY or 1
    local rot = img.rotation or 0

    local localCorners = {
        {0, 0},
        {w * sx, 0},
        {w * sx, h * sy},
        {0, h * sy},
    }

    local cosr, sinr = math.cos(rot), math.sin(rot)
    local min_x, max_x = math.huge, -math.huge
    local min_y, max_y = math.huge, -math.huge

    for i = 1, 4 do
        local cx, cy = localCorners[i][1], localCorners[i][2]
        local rx = img.x + cx * cosr - cy * sinr
        local ry = img.y + cx * sinr + cy * cosr
        if rx < min_x then min_x = rx end
        if rx > max_x then max_x = rx end
        if ry < min_y then min_y = ry end
        if ry > max_y then max_y = ry end
    end

    return min_x, min_y, max_x, max_y
end

-- vector from a sprite's pivot to its rotated visual center, since we store pivots but source coords are center-based
function SANS.GetPivotToCenterOffset(img)
    local w, h = img.img:getWidth(), img.img:getHeight()
    local sx, sy = img.scaleX or 1, img.scaleY or 1
    local halfW, halfH = w * sx / 2, h * sy / 2
    local rot = img.rotation or 0
    local cosr, sinr = math.cos(rot), math.sin(rot)
    return halfW * cosr - halfH * sinr, halfW * sinr + halfH * cosr
end

-- rotates the heart in place (keeps its visual center fixed) instead of letting it swing around its stale pivot
function SANS.SetHeartRotation(heart, newRotation)
    if not heart then return end
    if not heart.img then
        heart.rotation = newRotation
        return
    end

    local oldOffX, oldOffY = SANS.GetPivotToCenterOffset(heart)
    local centerX, centerY = heart.x + oldOffX, heart.y + oldOffY

    heart.rotation = newRotation

    local newOffX, newOffY = SANS.GetPivotToCenterOffset(heart)
    heart.x = centerX - newOffX
    heart.y = centerY - newOffY
end

-- unit gravity-direction vector from the heart's rotation, same 0=right/1=down/2=left/3=up convention as BONE_DIRECTIONS
function SANS.GetHeartGravityAxis(heart)
    local rot = (heart and heart.rotation) or (math.pi / 2)
    local step = math.floor(rot / (math.pi / 2) + 0.5) % 4
    local axes = { { 1, 0 }, { 0, 1 }, { -1, 0 }, { 0, -1 } }
    local a = axes[step + 1]
    return a[1], a[2]
end

-- green trigger rect sits above the white collision rect, a bit smaller
function SANS.GetPlatformTriggerRect(p)
    local cfg = SANS.PlatformConfig
    return p.x + cfg.triggerOffsetX, p.y + cfg.triggerOffsetY, p.width - cfg.triggerWidthTrim, p.height
end

-- moves and updates platforms
function SANS.UpdatePlatforms(dt)
    local combatZone = SANS.combatZone
    local heart = SANS.images.PlayerHeart

    for i = #SANS.platforms, 1, -1 do
        local p = SANS.platforms[i]

        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt

        if p.reverse then
            if p.vx > 0 and p.x + p.width > combatZone.right then
                p.x = combatZone.right - p.width
                p.vx = -p.vx
            elseif p.vx < 0 and p.x < combatZone.left then
                p.x = combatZone.left
                p.vx = -p.vx
            end

            if p.vy > 0 and p.y + p.height > combatZone.bottom then
                p.y = combatZone.bottom - p.height
                p.vy = -p.vy
            elseif p.vy < 0 and p.y < combatZone.top then
                p.y = combatZone.top
                p.vy = -p.vy
            end
        end

        if heart and heart.grounded then
            local tx, ty, tw, th = SANS.GetPlatformTriggerRect(p)
            local hx1, hy1, hx2, hy2 = SANS.GetImageBBox(heart)

            if hx1 < tx + tw and hx2 > tx and hy1 < ty + th and hy2 > ty then
                heart.x = heart.x + p.vx * dt
                heart.y = heart.y + p.vy * dt
            end
        end

        local exited = (p.vx > 0 and p.x > 640 + OFFSCREEN_MARGIN)
            or (p.vx < 0 and p.x + p.width < -OFFSCREEN_MARGIN)
            or (p.vy > 0 and p.y > 480 + OFFSCREEN_MARGIN)
            or (p.vy < 0 and p.y + p.height < -OFFSCREEN_MARGIN)

        if exited then
            table.remove(SANS.platforms, i)
        end
    end
end

local PLATFORM_REST_MARGIN = 1
function SANS.ResolvePlatformCollisions(heart, prevMaxY)
    local landed = false
    if SANS.heartMode ~= 1 then return landed end

    local minX, _, maxX, maxY = SANS.GetImageBBox(heart)

    for _, p in ipairs(SANS.platforms) do
        local restY = p.y - PLATFORM_REST_MARGIN
        local overlapsX = minX < p.x + p.width and maxX > p.x
        local wasAbove = prevMaxY <= restY + 0.5
        local nowAtOrBelowTop = maxY >= restY

        if overlapsX and wasAbove and nowAtOrBelowTop then
            heart.y = heart.y + (restY - maxY)
            maxY = restY
            landed = true
        end
    end

    if landed then
        heart.vy = 0
        heart.grounded = true
    end

    return landed
end

-- gravity changes depending of the fall speed (see jcw's original project)
local function getBlueGravity(vy)
    if vy > 15 and vy < 240 then
        return 540
    elseif vy <= 15 and vy > -30 then
        return 180
    elseif vy <= -30 and vy > -120 then
        return 450
    elseif vy <= -120 then
        return 180
    end
    return 0
end

local ARROW_KEYS = { "up", "down", "left", "right" }

-- maps a unit direction vector to the love.keyboard key name pointing that way (screen-space: 1,0=right / -1,0=left / 0,1=down / 0,-1=up)
local function KeyForDirection(x, y)
    if x > 0.5 then return "right"
    elseif x < -0.5 then return "left"
    elseif y > 0.5 then return "down"
    else return "up" end
end

-- jumping :DD - vector form so gravity/jump work along whichever axis SansSlam last rotated the heart to
function SANS.UpdateBlueHeartJump(heart, dt)
    local cfg = SANS.BlueHeart
    heart.vx = heart.vx or 0
    heart.vy = heart.vy or 0

    local downX, downY = SANS.GetHeartGravityAxis(heart)
    local alongSpeed = heart.vx * downX + heart.vy * downY
    local perpX = heart.vx - alongSpeed * downX
    local perpY = heart.vy - alongSpeed * downY

    -- jump key always points opposite gravity, so slammed right = jump on left arrow instead of up
    local jumpKey = KeyForDirection(-downX, -downY)

    -- each arrow key tracks its own held state, so a key already held before a slam rotation doesn't read as a fresh press
    heart.heldKeys = heart.heldKeys or {}
    local held = heart.heldKeys
    local upDown = love.keyboard.isDown(jumpKey)
    local upPressed = upDown and not held[jumpKey]
    for _, key in ipairs(ARROW_KEYS) do
        held[key] = love.keyboard.isDown(key)
    end

    -- jump buffer: remembers a fresh jump-key press for a bit so landing-then-jumping doesn't need frame-perfect timing
    if upPressed then
        heart.jumpBufferTimer = cfg.jumpBufferTime
    elseif heart.jumpBufferTimer and heart.jumpBufferTimer > 0 then
        heart.jumpBufferTimer = math.max(0, heart.jumpBufferTimer - dt)
    end

    if heart.grounded then
        alongSpeed = 0
        if heart.jumpBufferTimer and heart.jumpBufferTimer > 0 then
            alongSpeed = -cfg.jumpSpeed
            heart.grounded = false
            heart.jumpBufferTimer = 0
        end
    else
        if not upDown and alongSpeed < -cfg.jumpHoldCutoff then
            alongSpeed = -cfg.jumpHoldCutoff
        end

        local gravity = getBlueGravity(alongSpeed)
        alongSpeed = math.min(alongSpeed + gravity * dt, cfg.maxFallSpeed)
    end

    heart.vx = perpX + alongSpeed * downX
    heart.vy = perpY + alongSpeed * downY

    heart.x = heart.x + heart.vx * dt
    heart.y = heart.y + heart.vy * dt
end

-- Color the heart correctly (actually deletes you then replace you with a you from a different universe D:)
function SANS.UpdateHeartColor()
    local heart = SANS.images.PlayerHeart
    if not heart then return end

    local color = SANS.HEART_COLORS[SANS.heartMode] or SANS.HEART_COLORS[0]
    local key = SANS.LoadImage("PlayerHeart", heart.x, heart.y, heart.rotation, heart.scaleX, heart.scaleY, false, color)

    local newHeart = SANS.images[key]
    newHeart.vx = heart.vx
    newHeart.vy = heart.vy
    newHeart.grounded = heart.grounded
    newHeart.heldKeys = heart.heldKeys
    newHeart.jumpBufferTimer = heart.jumpBufferTimer
    newHeart.slammed = heart.slammed
end

-- draws text anywhere, "\n" wraps to a new line, optional redRanges (from SANS.ParseColorTags) makes it own its color
-- (black default, whichever tag colour - red/orange/... - in range) instead of inheriting the caller's
function SANS.DrawText(fontname, text, posX, posY, kerning, scaleX, scaleY, redRanges, paragraphBreaks)
    kerning = kerning or 0
    scaleX = scaleX or 1
    scaleY = scaleY or 1
    local x, y = posX, posY
    local fontTable = SANS.fonts[fontname]

    -- Fallback glyph (underscore)
    local underscore = fontTable[string.byte("_")]
    -- line gap is a flat 4px, added after scaling so it doesn't get doubled at fontScale=2
    local LINE_GAP = 4
    local lineHeight = underscore and (underscore.height * scaleY + LINE_GAP) or 0
    local PARAGRAPH_LINE_MULT = 1.5 -- was a flat 2x, brought down per explicit request

    local ownsColor = redRanges ~= nil
    if ownsColor then
        love.graphics.setColor(0, 0, 0, 1)
    end

    for i = 1, #text do
        local charCode = string.byte(text, i)

        if charCode == 10 then -- "\n"
            x = posX
            -- paragraphBreaks[i]==true means this \n is a real paragraph break (table-element boundary), not just a
            -- word-wrapped continuation line - gets the bigger gap, see dialogue.lua's BuildPageDisplay
            y = y + (paragraphBreaks and paragraphBreaks[i] and lineHeight * PARAGRAPH_LINE_MULT or lineHeight)
        else
            local glyph = fontTable[charCode]

            if not glyph or not glyph.img then
                glyph = underscore
            end

            if glyph and glyph.img then
                if ownsColor then
                    local color = nil
                    for _, r in ipairs(redRanges) do
                        if i >= r.from and i <= r.to then
                            color = r.color
                            break
                        end
                    end
                    if color then
                        love.graphics.setColor(color[1], color[2], color[3], color[4] or 1)
                    else
                        love.graphics.setColor(0, 0, 0, 1)
                    end
                end

                -- needed snapping cuz fractional pixels caused errors
                love.graphics.draw(glyph.img, math.floor(x), math.floor(y), 0, scaleX, scaleY)
                x = x + (glyph.width * scaleX) + kerning
            end
        end
    end

    if ownsColor then
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function SANS.UpdateHealth()
    local hb = SANS.healthbar
    local barW = hb.rectW
    local p = SANS.player

    local currentkrW = barW * p.kr / p.max_hp
    local krW = (SANS.player.kr == 0 and 1 or currentkrW)
    -- god im so good at programming for finding the (SANS.player.kr == 0 and 1 or currentkrW) expression :pray_emoji:
    local currenthpW = barW * math.max(p.hp - p.kr, 0) / p.max_hp
    local hpW = math.min(p.hp > 0 and math.max(currenthpW, 1) or 0, barW - krW)

    -- Lost hp (background - shows through wherever hp+karma don't cover)
    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.rectangle("fill", hb.rectX, hb.rectY, barW, hb.rectH)

    -- hp
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.rectangle("fill", hb.rectX, hb.rectY, hpW, hb.rectH)

    -- karma
    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.rectangle("fill", hb.rectX + hpW, hb.rectY, krW, hb.rectH)

    -- reset color
    love.graphics.setColor(1, 1, 1, 1)
end


-- All of the actual hooks (no helper functions)
local DTaccumulator = 0
local fixedDt = 1 / 30 -- 30fps

-- Game:update body
function SANS.hooks.Update(dt)
    -- don't tick G.E_MANAGER or clear_queue() here, both tried and reverted - see items/blinds.lua for the real fix

    DTaccumulator = DTaccumulator + dt

    while DTaccumulator >= fixedDt do
        DTaccumulator = DTaccumulator - fixedDt

        dt = fixedDt -- use fixed dt for consistent updates

        -- fresh per-tick, so SANS.PlaySound only dedupes sounds that start on this exact tick, not any later replay
        for k in pairs(SANS.sound.playedThisTick) do SANS.sound.playedThisTick[k] = nil end

        if SANS.introAnim.active then
            SANS.UpdateIntroAnim(dt)
            goto continueTick
        end

        do -- combat zone resize update
            local cz, tz = SANS.combatZone, SANS.target_combatZone
            local step = SANS.combatZoneResizeSpeed * dt
            local reachedTarget = true

            for _, edge in ipairs({ "left", "top", "right", "bottom" }) do
                local diff = tz[edge] - cz[edge]
                if diff ~= 0 then
                    cz[edge] = cz[edge] + math.min(step, math.abs(diff)) * (diff > 0 and 1 or -1)
                    if cz[edge] ~= tz[edge] then reachedTarget = false end
                end
            end

            if reachedTarget and SANS.combatZoneFinishAction then
                local finishAction = SANS.combatZoneFinishAction
                SANS.combatZoneFinishAction = nil
                SANS.attackrunner.Dispatch(SANS.attackrunner.active, { name = finishAction, args = {} })
            end
        end

        -- Attack timeline update
        if not SANS.MENU.state and not SANS.heartDeath then
            SANS.attackrunner.Update(dt)
            SANS.UpdateAttackImages(dt)
            SANS.UpdatePlatforms(dt)
            SANS.UpdateGasterBlasters(dt)
            SANS.UpdateBoneStabs(dt)
            SANS.UpdateKarma(dt)
        end

        -- polls for the watched attack finishing, no-op unless something's actually waiting on it
        SANS.dialogue.Update(dt)
        SANS.UpdateSpareSequence(dt) -- no-op unless the spare ending is actually running
        SANS.UpdateWinSequence(dt) -- no-op unless the win ending is actually running

        -- Karma (poison) drain, the heart-break/shatter sequence, and the fight
        SANS.UpdateKarmaDrain(dt)
        SANS.UpdateHeartDeath(dt)
        SANS.UpdateFightMinigame(dt)
        SANS.UpdateBattleText(dt) -- item-use/check flavor text typewriter (menu.lua) - no-op unless one is showing
        SANS.UpdateMenuTextReveal(dt) -- "* Sans"/"* Check"/"* Spare"/item names/top flavor line typewriter (menu.lua) - no-op unless one is showing
        SANS.UpdateMenuBones(dt) -- decorative menu bones (menu.lua) - no-op unless one is active

        -- heart movement + clamping for every rotation
        if SANS.images.PlayerHeart and not SANS.MENU.state and not SANS.heartDeath then
            local heart = SANS.images.PlayerHeart
            local baseSpd = SANS.heartSpeed or 150
            local spd = love.keyboard.isDown("x") and baseSpd / 2 or baseSpd

            local _, _, _, prevMaxY = SANS.GetImageBBox(heart)

            -- sliding is always perpendicular to gravity: left/right normally, up/down once slammed onto a side wall
            local downX, downY = SANS.GetHeartGravityAxis(heart)
            local gravityIsHorizontal = SANS.heartMode == 1 and math.abs(downY) < 0.5

            if not gravityIsHorizontal then
                if love.keyboard.isDown("left") then heart.x = heart.x - spd * dt end
                if love.keyboard.isDown("right") then heart.x = heart.x + spd * dt end
            end

            if SANS.heartMode ~= 1 or gravityIsHorizontal then
                if love.keyboard.isDown("up") then heart.y = heart.y - spd * dt end
                if love.keyboard.isDown("down") then heart.y = heart.y + spd * dt end
            end

            if SANS.heartMode == 1 then
                SANS.UpdateBlueHeartJump(heart, dt)
            end

            local landedOnPlatform = SANS.ResolvePlatformCollisions(heart, prevMaxY)

            -- clamp area (clampin' my shi')(tbh i don't understand fully the code bellow but it works), clamped to the interior not the outer rect
            local izLeft, izTop, izRight, izBottom = SANS.GetCombatZoneInterior()
            local min_x, min_y, max_x, max_y = SANS.GetImageBBox(heart)

            local eps,dx,dy = 0,0,0

            if min_x < izLeft then
                dx = izLeft - min_x
            elseif max_x > izRight - eps then
                dx = izRight - eps - max_x
            end

            if min_y < izTop then
                dy = izTop - min_y
            elseif max_y > izBottom - eps then
                dy = izBottom - eps - max_y
            end

            -- blue heart mode: grounded/ceiling-bonk generalized to whichever wall sits in the current gravity direction
            if SANS.heartMode == 1 then
                downX, downY = SANS.GetHeartGravityAxis(heart) -- re-read: UpdateBlueHeartJump may have just changed heart.grounded but not rotation
                local floorDist, ceilDist

                if downX > 0.5 then
                    floorDist, ceilDist = izRight - max_x, min_x - izLeft
                elseif downX < -0.5 then
                    floorDist, ceilDist = min_x - izLeft, izRight - max_x
                elseif downY > 0.5 then
                    floorDist, ceilDist = izBottom - max_y, min_y - izTop
                else
                    floorDist, ceilDist = min_y - izTop, izBottom - max_y
                end

                local alongSpeed = (heart.vx or 0) * downX + (heart.vy or 0) * downY
                local wasGrounded = heart.grounded

                -- 0.2px tolerance so a heart resting flush on the floor doesn't flicker airborne every other tick
                if floorDist <= 0.2 or (downY > 0.5 and landedOnPlatform) then
                    heart.grounded = true

                    -- Slammed is consumed on the very next landing regardless of speed - only a real SansSlam can ever trigger impact damage/sound, not an ordinary fast fall
                    if not wasGrounded and heart.slammed then
                        heart.slammed = false
                        if alongSpeed > 330 then
                            SANS.PlaySound("Slam", 1)
                            -- slams wear you down to 1 hp but never kill
                            if SANS.slam.damageEnabled and SANS.player.hp > 1 then
                                SANS.DamagePlayer(1)
                            else
                                SANS.PlaySound("PlayerDamaged", 1)
                            end
                        end
                    end

                    heart.vx = (heart.vx or 0) - alongSpeed * downX
                    heart.vy = (heart.vy or 0) - alongSpeed * downY
                else
                    heart.grounded = false
                end

                if ceilDist <= 0 and alongSpeed < 0 then
                    -- bonk the wall behind (the old "ceiling" case, generalized)
                    heart.vx = (heart.vx or 0) - alongSpeed * downX
                    heart.vy = (heart.vy or 0) - alongSpeed * downY
                end
            end

            -- apply translation to the heart draw position
            heart.x = heart.x + dx
            heart.y = heart.y + dy
        end

        -- runs regardless of MENU.state so dialogue bubbles still type out while the menu's technically open
        if SANS.images.PlayerHeart and not SANS.heartDeath then
            SANS.animations.setOffsets(dt)
        end

        ::continueTick::
    end
end

local framebuffer

-- love.load body
function SANS.hooks.Load()
    framebuffer = love.graphics.newCanvas(640, 480)
end

-- love.draw body
function SANS.hooks.Draw()
    -- the spare ending's final video deliberately bypasses the mod's usual 640x480 canvas entirely and draws at real
    -- native resolution - see SANS.DrawFinalSpareVideo (dialogue.lua)
    if SANS.spareSequence.active and SANS.spareSequence.phase == "finalVideo" then
        SANS.DrawFinalSpareVideo()
        return
    end

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()

    framebuffer = framebuffer or love.graphics.newCanvas(640, 480)

    -- scales while keeping whole numbers
    local scale = math.min(w / 640, h / 480)
    local scaled_w, scaled_h = 640 * scale, 480 * scale
    local offset_x = (w - scaled_w) / 2
    local offset_y = (h - scaled_h) / 2

    -- combat zone into framebuffer
    love.graphics.setCanvas(framebuffer)

    love.graphics.clear(0, 0, 0, 1) -- green bg (test only)
    love.graphics.setColor(1, 1, 1, 1)

    if SANS.introAnim.active then
        -- blind-select reveal cutscene, plays before the fight itself is ever set up (see introanim.lua)
        SANS.DrawIntroAnim()
    elseif SANS.heartDeath then
        -- Death sequence : red heart + music stop + remove everything into crack into shatter
        SANS.DrawHeartDeath()
    elseif SANS.spareSequence.active and SANS.spareSequence.phase ~= "dialogue" then
        -- spare ending, once the dialogue's dismissed: everything disappears, replaced by the video/white screen (dialogue.lua)
        SANS.DrawSpareSequence()
    elseif SANS.winSequence.active then
        -- win ending: survived sans_final's whole moveset - fade to white, text, fade to black, looping video (dialogue.lua)
        SANS.DrawWinSequence()
    else
    -- heart's hidden entirely whenever sans is talking (or about to - the 1s beat before "ready?" counts too), player's not in control during a bubble
    local dialogueActive = SANS.dialogue.active ~= nil or SANS.dialogue.introDelayTimer ~= nil

    -- the "ready?" bubble (and the silent beat before it) also hides the combat zone border, nothing's started yet so there's no zone to show
    local firstLineOnly = (SANS.dialogue.active and SANS.dialogue.active.bubbles == SANS.dialogue.blocks.intro.before) or SANS.dialogue.introDelayTimer ~= nil

    SANS.UpdateHealth() -- important

    SANS.DrawText("BattleFont", SANS.player.name .. "   LV 19", 32, 402, 1, 3, 3) -- BattleScreen.xml's "CHARA LV19" BattleFont instance, world (32,402)

    -- HP text turns purple (matching the health bar's karma segment color) while karma is pending
    if SANS.player.kr ~= 0 and SANS.player.hp > 1 then
        love.graphics.setColor(1, 0, 1, 1)
    end
    -- Battle.xml sources this at world (416,400), but that reads 2px higher than the name text right next to it on
    -- screen (confirmed by pixel-measuring a real screenshot) - bumped to y=402 to match SANS.player.name's row instead
    SANS.DrawText("BattleFont", string.format("%02d", SANS.player.hp) .. " / " .. tostring(SANS.player.max_hp), 416, 402, 1, 3, 3)
    love.graphics.setColor(1, 1, 1, 1)

    -- substate/fight minigame draws once, further down, after everything else below

    -- draw order mirrors source's real layer stack: Enemies(Sans) < Buttons(icons) < CombatZone(heart/BoneH/platforms/blasters/menubones) < CombatZoneClipped(BoneV/BoneStab)
    -- draws sans, plus the speech bubble/text whenever one's up
    SANS.DrawSans()

    -- menu icons only (HP/KR already drawn above via UpdateHealth, heart drawn separately below)
    for _, img in pairs(SANS.images) do
        if img.visible and not img.isAttack and img ~= SANS.images.PlayerHeart and img ~= SANS.images.HP and img ~= SANS.images.KR then
            love.graphics.draw(img.img, img.x, img.y, img.rotation, img.scaleX, img.scaleY)
        end
    end

    local heart = SANS.images.PlayerHeart
    if heart and heart.visible and not dialogueActive then
        -- floored so blue mode's fractional y positions don't corrupt the pixel art
        love.graphics.draw(heart.img, math.floor(heart.x), math.floor(heart.y), heart.rotation, heart.scaleX, heart.scaleY)
    end

    -- drawn above the heart (source explicitly "Move to top"s MenuBoneLeft on spawn)
    SANS.DrawMenuBones()

    SANS.DrawGasterBlasterBeams()

    -- CombatZone-tier attacks (BoneH, Platforms, GasterBlaster sprite, BoneStabWarn) - same tier as the heart, drawn above it
    for _, img in pairs(SANS.images) do
        if img.visible and img.isAttack and not img.clippedLayer and (not img.hideOutsideCombatZone or SANS.IsImageInCombatZone(img)) then
            if img.draw then
                img.draw(img)
            else
                love.graphics.draw(img.img, img.x, img.y, img.rotation, img.scaleX, img.scaleY)
            end
        end
    end

    -- CombatZoneClipped-tier attacks (BoneV, BoneStab) - source's layer above CombatZone, drawn last of the gameplay sprites
    for _, img in pairs(SANS.images) do
        if img.visible and img.isAttack and img.clippedLayer and (not img.hideOutsideCombatZone or SANS.IsImageInCombatZone(img)) then
            if img.draw then
                img.draw(img)
            else
                love.graphics.draw(img.img, img.x, img.y, img.rotation, img.scaleX, img.scaleY)
            end
        end
    end

    -- Platforms: white collision rectangle, green trigger rectangle inset inside it
    love.graphics.setLineWidth(1)
    for _, p in ipairs(SANS.platforms) do
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", p.x, p.y, p.width, p.height)

        local tx, ty, tw, th = SANS.GetPlatformTriggerRect(p)
        love.graphics.setColor(0, 1, 0, 1)
        love.graphics.rectangle("line", tx, ty, tw, th)
    end
    love.graphics.setColor(1, 1, 1, 1)

    if SANS.MENU.substate then
        SANS.DrawSubstate(SANS.MENU.substate)
    elseif SANS.MENU.state and SANS.MENU.flavorText and not SANS.dialogue.active then
        -- top-level flavor text, guarded separately since dialogue can start without clearing it
        SANS.DrawText("DefaultFont", SANS.RevealMenuText(SANS.MENU.flavorText), 48, 272, 2, SANS.MENU.fontScale, SANS.MENU.fontScale)
    end

    if not firstLineOnly then
        local border = SANS.combatZoneBorder
        love.graphics.setLineWidth(border)

        local halfborder = border/2
        local combatZone = SANS.combatZone
        local width = combatZone.right - combatZone.left
        local height = combatZone.bottom - combatZone.top

        -- inset by half the line width so the stroke sits inside the zone rect, drawn after the attack images so bones get covered by it
        love.graphics.rectangle("line", combatZone.left+halfborder, combatZone.top+halfborder, width-border, height-border)
    end

    if SANS.blackScreen then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1, 1, 1, 1)
    end
    end
    love.graphics.setCanvas()

    -- black bg + framebuffer
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(framebuffer, offset_x, offset_y, 0, scale, scale)
end

-- draws just the shatter/fade overlay on top of the real game, once control's already been handed back
function SANS.hooks.DrawDeathFade()
    local alpha = SANS.GetHeartDeathFadeAlpha()
    if alpha <= 0 then return end

    framebuffer = framebuffer or love.graphics.newCanvas(640, 480)

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local scale = math.min(w / 640, h / 480)
    local scaled_w, scaled_h = 640 * scale, 480 * scale
    local offset_x, offset_y = (w - scaled_w) / 2, (h - scaled_h) / 2

    love.graphics.setCanvas(framebuffer)
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    SANS.DrawHeartDeath()
    love.graphics.setCanvas()

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.draw(framebuffer, offset_x, offset_y, 0, scale, scale)
    love.graphics.setColor(1, 1, 1, 1)
end

-- everything needed to actually start the fight, once SANS.state is already true - shared by the intro-anim completion (see introanim.lua) and ToggleState's own on-branch
function SANS.BeginFight()
    print("Sans on")
    CHANNEL:push({ type = "stop" })  -- Stops all audio
    love.graphics.setDefaultFilter("nearest", "nearest", 1)
    SANS.LoadUI()
    SANS.LoadHealth()
    SANS.LoadFont("BattleFont", 32, 95)
    SANS.LoadFont("DamageFont", 32, 126)
    SANS.LoadFont("DefaultFont", 32, 126)
    SANS.LoadFont("SansFont", 32, 126)
    SANS.heartMode = 0
    SANS.LoadImage("PlayerHeart", 300, 200, math.pi / 2, 1, 1, false, SANS.HEART_COLORS[0])

    -- full reset so toggling off then back on always lands on a pristine fight
    SANS.DestroyAllAttacks() -- clears leftover bones/blasters/stabs/platforms/attacksCount from a fight that got interrupted mid-attack
    SANS.attackloader.CombatZoneResizeInstant(33, 251, 608, 391) -- combat zone could've been left mid-resize or a non-default size
    SANS.attackloader.ResetVars() -- resize speed, blue-heart max fall speed, slam damage flag, Sans's legs x/xSpeed
    SANS.blackScreen = false
    SANS.attackrunner.active = nil

    -- clears out stale menu state from leaving mid FIGHT-minigame or mid ACT/ITEM submenu
    SANS.CancelFightMinigame()
    SANS.dodge = nil
    SANS.MENU.substate = nil
    SANS.MENU.act = nil
    SANS.MENU.item_page = nil
    SANS.MENU.selected_item_index = nil
    SANS.items = copy_table(SANS.DEFAULT_ITEMS)
    SANS.battleText = nil -- leaving mid item-flavor-text would otherwise leave it swallowing all menu input next session
    SANS.MENU.flavorText = nil
    SANS.MENU.karmaSnapshot = 0
    SANS.checkCount = 0
    SANS.MENU.textReveal = { key = nil, revealed = 0 }
    SANS.menuBones = { left = nil, bottomActive = false, bottomTimer = 0, bottomAlternate = 0, bottom = {} }

    -- clears stale dialogue state too, otherwise leaving mid-intro can clobber the fresh "ready?" bubble or wedge EndAttack shut
    SANS.dialogue.active = nil
    SANS.dialogue.pendingAfterAttack = nil
    SANS.dialogue.deferEndAttackEntry = nil

    SANS.ResetPlayerState() -- defensive: guarantees a fresh hp/kr state even on a re-entry mid-death
    SANS.ClearHeartDeath()
    SANS.InitSansAnimations()
    SANS.attackrunner.ResetAttackSequence()
    SANS.heartSpeed = 150 -- matches the original's HEARTSPEED constant (used unnormalized on both axes, both heart modes)

    -- goes straight into the intro sequence instead of opening the menu directly
    SANS.MENU.icons.current_highlight_index = 1
    SANS.dialogue.PlayIntro()
end

-- flips SANS.state - the intro-anim completion (introanim.lua) sets SANS.state directly and calls BeginFight itself instead of going through here
function SANS.hooks.ToggleState()
    SANS.state = not SANS.state

    if SANS.state then
        SANS.BeginFight()
    else
        print("Sans off")
        SANS.StopMusic()
        CHANNEL:push({
            type = "restart_music",
            dt = 0,
            sound_settings = {
                volume = 100,
                music_volume = 100,
                game_sounds_volume = 100
            },
            desired_track = "",
            pitch_mod = 1,
            per = 1,
            vol = 1
        })
    end
end

-- suppresses just the one stale post-freeze hand-draw instead of nuking the whole event queue (that killed other stuck-pending UI too)
function SANS.hooks.DrawFromDeckToHand(e, original)
    if SANS.suppressNextHandDraw then
        SANS.suppressNextHandDraw = false
        e = 0
    end
    return original(e)
end

-- love.keypressed body, only reached while SANS.state is on
function SANS.hooks.Keypressed(key, scancode, isrepeat)
    -- Z confirms same as Enter (undertale's own confirm key) - normalized here so every "return" check below and in
    -- menu.lua gets it for free. Matches on both scancode and key so it works on azerty as well as qwerty.
    if scancode == "z" or key == "z" then scancode = "return" end

    if scancode == "l" and not isrepeat then
        -- playtest invincibility so you can watch a full runthrough without dying partway
        SANS.invincible = not SANS.invincible
        print("[TAO][SANS][CHEAT] Manual invicibility : " .. (SANS.invincible and "ON" or "OFF"))
    end

    -- a dialogue bubble owns Enter and swallows every other key too, so menu nav can't sneak through underneath it
    if SANS.dialogue.active then
        if scancode == "return" and not isrepeat then
            SANS.dialogue.HandleEnter()
        end
        return
    end

    -- once the intro dialogue's dismissed, the spare sequence owns the whole screen - no menu nav underneath it.
    -- "text" is the one phase that still wants Enter (1st press reveals, 2nd advances, same as every other typewriter)
    if SANS.spareSequence.active and SANS.spareSequence.phase ~= "dialogue" then
        if SANS.spareSequence.phase == "text" and scancode == "return" and not isrepeat then
            SANS.AdvanceSpareText()
        end
        return
    end

    -- win sequence owns the whole screen too - "text" wants Enter same as above, "video" only wants it once the
    -- video's completed at least one full loop (not before - see SANS.UpdateWinSequence)
    if SANS.winSequence.active then
        if scancode == "return" and not isrepeat then
            if SANS.winSequence.phase == "text" then
                SANS.AdvanceWinText()
            elseif SANS.winSequence.phase == "video" and SANS.winSequence.loops >= 1 then
                SANS.AdvanceWinSequence()
            end
        end
        return
    end

    SANS.HandleMenuKeypress(scancode, isrepeat)
end
