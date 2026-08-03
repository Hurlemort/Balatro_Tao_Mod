-- Cinematic reveal played on blind-select, self-contained in our own canvas, ends by calling SANS.BeginFight()

SANS.introAnim = SANS.introAnim or { active = false }

-- re-timed 2026-07-22 from the user's own frame-by-frame review of the real encounter transition (Warning -> +0.64s -> flash1 -> +0.14s -> flash2 -> +0.14s -> flash3 -> +0.07s -> battle)
local T_FLASH1 = 0.64
local T_FLASH2 = T_FLASH1 + 0.14
local T_FLASH3 = T_FLASH2 + 0.14
local T_BATTLE = T_FLASH3 + 0.07
local BATTLE_DURATION = 0.5 -- total time from Battle.ogg to BeginFight; lengthened 2026-07-22 per user request (was 0.325)
local HEART_ARRIVE_TIME = 0.5 -- heart reaches the FIGHTUI snap position this long after the slide starts, constant speed, then holds there for the rest of BATTLE_DURATION
local T_END = T_BATTLE + BATTLE_DURATION

local HEART_BLIP_TIME = 0.05

-- measured directly off a screenshot of the blind-select card icon (pixel bounding-box analysis)
local CHIP_POS = { x = 515, y = 243 }
local CHIP_SCALE = 2 -- kept as a clean integer per explicit request; a fractional scale (was 1.44) stretches pixels unevenly
local CHIP_FRAME_SIZE = 34

local function GetChipTexture()
    if not SANS.introAnim.chipTexture then
        -- blind_sans.png's atlas is registered at the Tao mod ROOT (items/blinds.lua), not under sans/; use Tao.path, not SANS.path
        local base = Tao.path or ""
        local last = base:sub(-1)
        if last ~= "/" and last ~= "\\" then base = base .. "/" end
        local file_data = NFS.newFileData(base .. "assets/1x/blind_sans.png")
        SANS.introAnim.chipTexture = love.graphics.newImage(love.image.newImageData(file_data))
    end
    return SANS.introAnim.chipTexture
end

-- heart.x/y is its top-left pivot not its center, so recenter it or it renders offset down-right of the chip
local function CenterHeartOnChip(heart)
    local offX, offY = SANS.GetPivotToCenterOffset(heart)
    heart.x, heart.y = CHIP_POS.x - offX, CHIP_POS.y - offY
end

-- called from items/blinds.lua's Blind:set_blind hook instead of SANS.hooks.ToggleState directly
function SANS.StartIntroAnim()
    if SANS.introAnim.active or SANS.state then return end

    SANS.state = true -- freezes the real game immediately (Game.update stops running, see globals.lua); we own the screen from here on
    SANS.suppressNextHandDraw = true -- new_round()'s stale draw-to-hand call gets suppressed once it fires, see hooks.lua
    love.thread.getChannel("sound_request"):push({ type = "stop" }) -- stop Balatro's music now too, not just at BeginFight
    love.graphics.setDefaultFilter("nearest", "nearest", 1)

    SANS.introAnim.active = true
    SANS.introAnim.timer = 0
    SANS.introAnim.chipVisible = true
    SANS.introAnim.flash1Fired = false
    SANS.introAnim.flash2Fired = false
    SANS.introAnim.flash3Fired = false
    SANS.introAnim.battleFired = false
    SANS.introAnim.heartBlipUntil = nil

    -- the heart blips/slides during this sequence exactly like the real fight's heart, so load it for real right away
    SANS.LoadImage("PlayerHeart", 0, 0, math.pi / 2, 1, 1, false, SANS.HEART_COLORS[0])
    CenterHeartOnChip(SANS.images.PlayerHeart)
    SANS.images.PlayerHeart.visible = false

    SANS.PlaySound("Warning", 1)
end

function SANS.UpdateIntroAnim(dt)
    local a = SANS.introAnim
    if not a.active then return end

    a.timer = a.timer + dt
    local heart = SANS.images.PlayerHeart

    if not a.flash1Fired and a.timer >= T_FLASH1 then
        a.flash1Fired = true
        SANS.PlaySound("Flash", 1)
        CenterHeartOnChip(heart)
        heart.visible = true
        a.heartBlipUntil = a.timer + HEART_BLIP_TIME
    end
    if not a.flash2Fired and a.timer >= T_FLASH2 then
        a.flash2Fired = true
        SANS.PlaySound("Flash", 1)
        CenterHeartOnChip(heart)
        heart.visible = true
        a.heartBlipUntil = a.timer + HEART_BLIP_TIME
    end
    if not a.flash3Fired and a.timer >= T_FLASH3 then
        a.flash3Fired = true
        SANS.PlaySound("Flash", 1)
        CenterHeartOnChip(heart)
        heart.visible = true
        a.heartBlipUntil = nil -- stays visible for good this time, no expiry
    end

    -- expires a flash1/flash2 blip once its 0.05s is up (flash3 never sets heartBlipUntil, so it never expires here)
    if heart.visible and a.heartBlipUntil and a.timer >= a.heartBlipUntil then
        heart.visible = false
        a.heartBlipUntil = nil
    end

    if a.flash3Fired and a.chipVisible and a.timer >= T_FLASH3 + HEART_BLIP_TIME then
        a.chipVisible = false -- gone for good
    end

    if not a.battleFired and a.timer >= T_BATTLE then
        a.battleFired = true
        SANS.PlaySound("Battle", 1)
        a.slideFromX, a.slideFromY = heart.x, heart.y
        -- the heart's actual resting spot on the UIFight icon, NOT SnapHeart(0,0) (that's the unrelated "* Sans"/"* Check"/
        -- "* Spare" substate text position); from menu.lua's LoadUI (UIFight at {28,437}) + UpdateHighlight(1)'s {+25,+13}
        a.slideToX, a.slideToY = 53, 450
    end

    if a.battleFired and a.timer < T_END then
        local t = math.min((a.timer - T_BATTLE) / HEART_ARRIVE_TIME, 1) -- clamped at 1: reaches the target at HEART_ARRIVE_TIME and just holds there until T_END
        heart.x = a.slideFromX + (a.slideToX - a.slideFromX) * t
        heart.y = a.slideFromY + (a.slideToY - a.slideFromY) * t
    end

    if a.timer >= T_END then
        a.active = false
        heart.visible = false
        SANS.BeginFight()
    end
end

function SANS.DrawIntroAnim()
    local a = SANS.introAnim
    love.graphics.setColor(1, 1, 1, 1)

    if a.chipVisible then
        local chipTex = GetChipTexture()
        -- always frame 1 (index 0), frozen for the whole sequence
        local quad = love.graphics.newQuad(0, 0, CHIP_FRAME_SIZE, CHIP_FRAME_SIZE, chipTex:getWidth(), chipTex:getHeight())
        love.graphics.draw(chipTex, quad,
            CHIP_POS.x - (CHIP_FRAME_SIZE * CHIP_SCALE) / 2,
            CHIP_POS.y - (CHIP_FRAME_SIZE * CHIP_SCALE) / 2,
            0, CHIP_SCALE, CHIP_SCALE)
    end

    local heart = SANS.images.PlayerHeart
    if heart and heart.visible then
        love.graphics.draw(heart.img, math.floor(heart.x), math.floor(heart.y), heart.rotation, heart.scaleX, heart.scaleY)
    end
end
