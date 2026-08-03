SANS.animations = SANS.animations or {}
SANS.attackloader = SANS.attackloader or {}

local SCALE = 2

-- loaded once, reused
local TEXTURE_CACHE = {}

local function GetTexture(name)
    if not TEXTURE_CACHE[name] then
        local base = SANS.path or ""
        local last = base:sub(-1)
        if last ~= "/" and last ~= "\\" then
            base = base .. "/"
        end

        local ok, file_data = pcall(NFS.newFileData, base .. "textures/" .. name .. ".png")
        if not ok or not file_data then
            print("[SANS][ANIM] Could not find texture: " .. name)
            return nil
        end

        local tex = love.graphics.newImage(love.image.newImageData(file_data))
        tex:setFilter("nearest", "nearest")
        TEXTURE_CACHE[name] = tex
    end
    return TEXTURE_CACHE[name]
end

local function DrawAnchored(tex, x, y, hx, hy)
    if not tex then return end
    love.graphics.draw(tex, x, y, 0, SCALE, SCALE, tex:getWidth() * hx, tex:getHeight() * hy)
end

local LEGS_HOTSPOT = { x = 0.477273, y = 1 }
local TORSO_HOTSPOT = { x = 0.5, y = 1 } -- same for Default and Shrug
local HEAD_HOTSPOT = { x = 0.5, y = 1 } -- same for every head animation
local SWEAT_HOTSPOT = { x = 0.5, y = 0 } -- Sweat is TOP-anchored, not bottom

local TORSO_OFFSET = { x = 0, y = -46 } -- from Legs' hotspot


local HEAD_OFFSET_NORMAL = { x = 0, y = -38 } -- from Torso's hotspot

local BODY_HOTSPOT = {
    HandDown = { x = 0.46875, y = 1 },
    HandUp = { x = 0.46875, y = 1 },
    HandLeft = { x = 0.34375, y = 1 },
    HandRight = { x = 0.34375, y = 1 },
}

-- offests
local HEAD_OFFSET_BODY = {
    HandDown = {
        { x = 0, y = -84 },
        { x = 0, y = -86 },
        { x = 0, y = -80 },
        { x = 0, y = -78 },
    },
    HandUp = {
        { x = 0, y = -80 },
        { x = 0, y = -78 },
        { x = 0, y = -84 },
        { x = 0, y = -86 },
        { x = 0, y = -84 },
    },
    HandRight = {
        { x = 0, y = -84 },
        { x = -4, y = -84 },
        { x = -6, y = -84 },
        { x = 6, y = -84 },
        { x = 2, y = -84 },
    },
    HandLeft = {
        { x = 2, y = -84 },
        { x = 6, y = -84 },
        { x = -6, y = -84 },
        { x = -4, y = -84 },
        { x = 0, y = -84 },
    },
}

local BODY_FRAME_COUNT = {
    HandDown = #HEAD_OFFSET_BODY.HandDown,
    HandUp = #HEAD_OFFSET_BODY.HandUp,
    HandLeft = #HEAD_OFFSET_BODY.HandLeft,
    HandRight = #HEAD_OFFSET_BODY.HandRight,
}
local BODY_FRAME_TIME = 1 / 15 -- matches the .caproj's animation speed="15" (fps)

local HEAD_TEXTURES = {
    Default = "SansHead",
    LookLeft = "SansHead_LookLeft",
    Wink = "SansHead_Wink",
    ClosedEyes = "SansHead_ClosedEyes",
    NoEyes = "SansHead_NoEyes",
    Tired1 = "SansHead_Tired1",
    Tired2 = "SansHead_Tired2",
}

local BLINK_FRAME_TIME = 0.5

local function GetHeadTexture()
    local anim = SANS.animations.headAnim or "Default"
    if anim == "BlueEye" then
        return GetTexture("SansHead_BlueEye" .. SANS.animations.blinkFrame)
    end
    return GetTexture(HEAD_TEXTURES[anim] or "SansHead")
end

function SANS.InitSansAnimations()
    SANS.animations.legs = { x = 320, y = SANS.target_combatZone.top - 16, xSpeed = 0 }
    SANS.animations.mode = "normal" -- "normal" (Legs+Torso) or "body" (SansBody pose)
    SANS.animations.type = "Idle" -- Idle/HeadBob/Tired/nil
    SANS.animations.speedModifier = 0
    SANS.animations.torsoAnim = "Default" -- Default/Shrug
    SANS.animations.headAnim = "Default"
    SANS.animations.bodyAnim = nil -- HandUp/HandDown/HandLeft/HandRight
    SANS.animations.bodyFrame = 1
    SANS.animations.bodyFrameTimer = 0
    SANS.animations.blinkFrame = 1
    SANS.animations.blinkTimer = 0
    SANS.animations.sweatLevel = 0
    SANS.animations.torsoOffset = { x = 0, y = 0 }
    SANS.animations.headOffset = { x = 0, y = 0 }
    SANS.animations.text = nil
    SANS.animations.textRevealed = 0
    SANS.animations.textColorRanges = nil
end

-- SansAnimation(AnimationName): Idle/HeadBob/Tired
function SANS.attackloader.SansAnimation(AnimationName)
    SANS.animations.mode = "normal"
    SANS.animations.type = AnimationName
end

-- SansBody(AnimationName): HandUp/HandDown/HandLeft/HandRight (ides Legs+Torso)
function SANS.attackloader.SansBody(AnimationName)
    SANS.animations.mode = "body"
    SANS.animations.type = nil
    SANS.animations.bodyAnim = AnimationName
    SANS.animations.bodyFrame = 1
    SANS.animations.bodyFrameTimer = 0
end

-- SansTorso(AnimationName): Default/Shrug (switches back to normal but bob timer still runs)
function SANS.attackloader.SansTorso(AnimationName)
    SANS.animations.mode = "normal"
    SANS.animations.torsoAnim = AnimationName
end

function SANS.attackloader.SansHead(AnimationName)
    SANS.animations.headAnim = AnimationName
    SANS.animations.blinkFrame = 1
    SANS.animations.blinkTimer = 0
end

function SANS.attackloader.SansSweat(SweatLevel)
    SANS.animations.sweatLevel = math.max(0, math.min(3, math.floor(tonumber(SweatLevel) or 0)))
end

function SANS.attackloader.SansX(XPosition)
    SANS.animations.legs.x = tonumber(XPosition) or SANS.animations.legs.x
end

function SANS.attackloader.SansRepeat()
    SANS.animations.legs.xSpeed = -900
end

function SANS.attackloader.SansEndRepeat()
    SANS.animations.legs.xSpeed = 0
end

-- CSV: SansText(Text); typewriter reveal one char per tick with a blip, pulls out any <red> tags first
function SANS.attackloader.SansText(Text)
    local plain, ranges = SANS.ParseColorTags(Text)
    SANS.animations.text = plain
    SANS.animations.textRevealed = 0
    SANS.animations.textColorRanges = ranges
end

-- Called every fixed tick (see Game:update in globals.lua)
function SANS.animations.setOffsets(dt)
    local legs = SANS.animations.legs

    -- Repeat-scroll
    if legs.xSpeed ~= 0 then
        legs.y = SANS.combatZone.top - 16
        legs.x = legs.x + legs.xSpeed * dt
        legs.xSpeed = math.min(0, legs.xSpeed + 45 * dt)

        if legs.x < -100 then
            legs.x = 740
            local heads = { "Default", "LookLeft", "Wink", "ClosedEyes", "NoEyes" }
            local torsos = { "Default", "Default", "Default", "Shrug" }
            SANS.animations.headAnim = heads[love.math.random(#heads)]
            SANS.animations.torsoAnim = torsos[love.math.random(#torsos)]
        end
    else
        legs.y = SANS.target_combatZone.top - 16
    end

    -- Idle/HeadBob/Tired bob timer
    if SANS.animations.type then
        SANS.animations.speedModifier = SANS.animations.speedModifier + dt
    else
        SANS.animations.speedModifier = 0
    end

    local torsoOffset = SANS.animations.torsoOffset
    local headOffset = SANS.animations.headOffset
    torsoOffset.x, torsoOffset.y = 0, 0
    headOffset.x, headOffset.y = 0, 0

    if SANS.animations.type == "Idle" then
        if SANS.animations.speedModifier > 1.2 then
            SANS.animations.speedModifier = SANS.animations.speedModifier - 1.2
        end

        local sm = SANS.animations.speedModifier
        torsoOffset.x = math.sin(sm * 2 * math.pi / 1.2)
        torsoOffset.y = math.sin(sm * 4 * math.pi / 1.2)
        headOffset.y = -0.4 * math.sin(sm * 4 * math.pi / 1.2)
    elseif SANS.animations.type == "HeadBob" then
        if SANS.animations.speedModifier > 1.1 then
            SANS.animations.speedModifier = SANS.animations.speedModifier - 1.1
        end

        local sm = SANS.animations.speedModifier
        headOffset.x = math.sin(sm * 2 * math.pi / 1.1)
        headOffset.y = math.sin(sm * 4 * math.pi / 1.1)
    elseif SANS.animations.type == "Tired" then
        if SANS.animations.speedModifier > 3.8 then
            SANS.animations.speedModifier = SANS.animations.speedModifier - 3.8
        end

        local sm = SANS.animations.speedModifier
        torsoOffset.y = math.sin(sm * 2 * math.pi / 3.8)
        headOffset.y = math.sin(sm * 2 * math.pi / 3.8)
    end

    if SANS.animations.mode == "body" and SANS.animations.bodyAnim then
        local count = BODY_FRAME_COUNT[SANS.animations.bodyAnim] or 1
        if SANS.animations.bodyFrame < count then
            SANS.animations.bodyFrameTimer = SANS.animations.bodyFrameTimer + dt
            if SANS.animations.bodyFrameTimer >= BODY_FRAME_TIME then
                SANS.animations.bodyFrameTimer = SANS.animations.bodyFrameTimer - BODY_FRAME_TIME
                SANS.animations.bodyFrame = SANS.animations.bodyFrame + 1
            end
        end
    end

    -- BlueEye blink loop
    if SANS.animations.headAnim == "BlueEye" then
        SANS.animations.blinkTimer = SANS.animations.blinkTimer + dt
        if SANS.animations.blinkTimer >= BLINK_FRAME_TIME then
            SANS.animations.blinkTimer = SANS.animations.blinkTimer - BLINK_FRAME_TIME
            SANS.animations.blinkFrame = (SANS.animations.blinkFrame == 1) and 2 or 1
        end
    end

    -- reveals one more char of the text per tick
    if SANS.animations.text and SANS.animations.textRevealed < #SANS.animations.text then
        SANS.animations.textRevealed = SANS.animations.textRevealed + 1
        local revealedChar = SANS.animations.text:sub(SANS.animations.textRevealed, SANS.animations.textRevealed)
        if not SANS.IsSilentChar(revealedChar) then
            SANS.PlaySound("SansSpeak", 1)
        end
    end
end

local function DrawSansText()
    local legs = SANS.animations.legs
    local bx, by = legs.x + 64, legs.y - 128

    local bubbleTex = GetTexture("SpeechBubble")
    if bubbleTex then
        love.graphics.draw(bubbleTex, bx, by)
    end

    local revealed = SANS.animations.text:sub(1, SANS.animations.textRevealed)
    SANS.DrawText("SansFont", revealed, bx + 32, by + 16, 5, 1, 1, SANS.animations.textColorRanges)
end

-- Draws everything directly sans-related
function SANS.DrawSans()
    local legs = SANS.animations.legs
    if not legs then return end

    local headX, headY
    love.graphics.setColor(1, 1, 1, 1)

    if SANS.animations.mode == "body" and SANS.animations.bodyAnim then
        local pose = SANS.animations.bodyAnim
        local bodyTex = GetTexture("SansBody_" .. pose .. SANS.animations.bodyFrame)
        local bodyHotspot = BODY_HOTSPOT[pose] or BODY_HOTSPOT.HandDown
        DrawAnchored(bodyTex, legs.x, legs.y, bodyHotspot.x, bodyHotspot.y)

        local frames = HEAD_OFFSET_BODY[pose] or HEAD_OFFSET_BODY.HandDown
        local headOff = frames[SANS.animations.bodyFrame] or frames[#frames]
        headX, headY = legs.x + headOff.x, legs.y + headOff.y
    else
        DrawAnchored(GetTexture("SansLegs"), legs.x, legs.y, LEGS_HOTSPOT.x, LEGS_HOTSPOT.y)

        local torsoTex = GetTexture(SANS.animations.torsoAnim == "Shrug" and "SansTorso_Shrug" or "SansTorso")
        local torsoOffset = SANS.animations.torsoOffset
        local torsoX = legs.x + TORSO_OFFSET.x + torsoOffset.x
        local torsoY = legs.y + TORSO_OFFSET.y + torsoOffset.y
        DrawAnchored(torsoTex, torsoX, torsoY, TORSO_HOTSPOT.x, TORSO_HOTSPOT.y)

        local headOffset = SANS.animations.headOffset
        headX = torsoX + HEAD_OFFSET_NORMAL.x + headOffset.x
        headY = torsoY + HEAD_OFFSET_NORMAL.y + headOffset.y
    end

    local headTex = GetHeadTexture()
    DrawAnchored(headTex, headX, headY, HEAD_HOTSPOT.x, HEAD_HOTSPOT.y)

    if SANS.animations.sweatLevel > 0 and headTex then
        local sweatTex = GetTexture("SansSweat_Sweat" .. SANS.animations.sweatLevel)
        -- Sweat's image point is the head texture's top-center (0.5,0) on every single .caproj frame, so derive it from the actual head texture instead of a guessed constant
        DrawAnchored(sweatTex, headX, headY - headTex:getHeight() * SCALE, SWEAT_HOTSPOT.x, SWEAT_HOTSPOT.y)
    end

    if SANS.animations.text then
        DrawSansText()
    end
end
