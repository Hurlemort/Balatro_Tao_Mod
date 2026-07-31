SANS.attackloader = SANS.attackloader or {}

-- GB needed thei own file because they are a fucking hell

local DEG2RAD = math.pi / 180

local STATE_ENTER = 0
local STATE_WAIT = 1
local STATE_FIRE = 2
local STATE_LEAVE = 3

local FIRE_FRAME_TIME = 0.03 -- seconds per Fire animation frame

-- made so that the rotation pivot is at the center of the mouth
local BODY_HOTSPOT_X = 0.491228074
local BODY_HOTSPOT_Y = 0.5

-- raw GB texture : loaded once and reused for all GBs
local TEXTURE_CACHE = {}
local function GetTexture(name)
    if not TEXTURE_CACHE[name] then
        local base = SANS.path or ""
        local last = base:sub(-1)
        if last ~= "/" and last ~= "\\" then
            base = base .. "/"
        end

        local file_data = NFS.newFileData(base .. "textures/" .. name .. ".png")
        local image_data = love.image.newImageData(file_data)
        TEXTURE_CACHE[name] = love.graphics.newImage(image_data)
    end
    return TEXTURE_CACHE[name]
end

-- gaster blast drawing
local function DrawBeamLayer(b, rad, scale, offset, height, width, alpha)
    local segX = b.x + math.cos(rad) * offset * scale
    local segY = b.y + math.sin(rad) * offset * scale

    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.push()
    love.graphics.translate(segX, segY)
    love.graphics.rotate(rad)
    love.graphics.rectangle("fill", 0, -height / 2, width, height)
    love.graphics.pop()
end

-- gaster blaster drawing (not blast)
function SANS.DrawGasterBlaster(b)
    local rad = b.ang * DEG2RAD

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(b.bodyImg, b.x, b.y, rad, b.widthScale, b.heightScale, b.imgW * BODY_HOTSPOT_X, b.imgH * BODY_HOTSPOT_Y)
end

-- Draws every active blaster's beam
function SANS.DrawGasterBlasterBeams()
    for _, b in pairs(SANS.images) do
        if b.isGasterBlaster and b.visible and b.beamVisible then
            local rad = b.ang * DEG2RAD
            local scale = b.heightScale / 2
            local alpha = math.max(0, math.min(100, b.beamOpacity)) / 100

            local h1 = b.beamBaseSize + b.beamSineSize
            local h2 = b.beamBaseSize / 1.25 + b.beamSineSize
            local h3 = b.beamBaseSize / 2 + b.beamSineSize

            DrawBeamLayer(b, rad, scale, 70, h1, 1000, alpha)
            DrawBeamLayer(b, rad, scale, 60, h2, 10 * scale, alpha)
            DrawBeamLayer(b, rad, scale, 50, h3, 20 * scale, alpha)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

-- updates the gaster blasters
local function StepGasterBlaster(b, dt)
    if b.state == STATE_ENTER then
        if math.abs(b.x - b.endX) >= 3 then
            b.x = b.x + (b.endX - b.x) * dt * 10
        else
            b.x = b.endX
        end

        if math.abs(b.y - b.endY) >= 3 then
            b.y = b.y + (b.endY - b.y) * dt * 10
        else
            b.y = b.endY
        end

        if math.abs(b.ang - b.endAng) >= 3 then
            b.ang = b.ang + (b.endAng - b.ang) * dt * 10
        else
            b.ang = b.endAng
        end

        if b.x == b.endX and b.y == b.endY and b.ang == b.endAng then
            b.state = STATE_WAIT
        end
    end

    if b.state == STATE_WAIT or b.state == STATE_FIRE then
        b.timer = math.max(0, b.timer - dt)
    end

    if b.state == STATE_WAIT and b.timer <= 0 then
        b.state = STATE_FIRE
        b.timer = 0.1
        b.animFrame = 1
        b.animTimer = 0
        b.bodyImg = GetTexture("GasterBlaster_Fire1")
    end

    -- Fire animation keeps stepping through LEAVE too, until it reaches its last frame
    if b.animFrame > 0 and b.animFrame < 5 then
        b.animTimer = b.animTimer + dt
        if b.animTimer >= FIRE_FRAME_TIME then
            b.animTimer = b.animTimer - FIRE_FRAME_TIME
            b.animFrame = b.animFrame + 1
            b.bodyImg = GetTexture("GasterBlaster_Fire" .. b.animFrame)
        end
    end

    if b.state == STATE_FIRE and b.timer <= 0 then
        b.state = STATE_LEAVE
        b.beamVisible = true
        b.beamTimer = 0
        b.beamBaseSize = 0
        b.beamOpacity = 100
        b.leaveSpeed = 0

        SANS.PlaySound("GasterBlast", 1.2)
        SANS.PlaySound("GasterBlast2", 1.2)
    end

    if b.state == STATE_LEAVE then
        b.leaveSpeed = b.leaveSpeed + 30

        local rad = b.ang * DEG2RAD
        b.x = b.x - math.cos(rad) * dt * b.leaveSpeed
        b.y = b.y - math.sin(rad) * dt * b.leaveSpeed
    end

    if b.beamVisible then
        b.beamTimer = b.beamTimer + dt
        local target = 35 * b.heightScale

        if b.beamTimer < 4 / 30 then
            b.beamBaseSize = b.beamBaseSize + math.floor(target / 4)
        elseif b.beamTimer < 5 / 30 then
            b.beamBaseSize = target
        elseif b.beamTimer > 5 / 30 + b.blastTime then
            b.beamBaseSize = b.beamBaseSize * 0.8
            b.beamOpacity = 100 - ((b.beamTimer - b.blastTime) * 30 - 5) * 10

            if b.beamBaseSize <= 2 then
                b.destroyed = true
            end
        end

        b.beamSineSize = math.sin(b.beamTimer * 20) * b.beamBaseSize / 4
    end
end

-- Called every fixed tick from the main update loop, alongside UpdateAttackImages/UpdatePlatforms
function SANS.UpdateGasterBlasters(dt)
    for key, b in pairs(SANS.images) do
        if b.isGasterBlaster then
            StepGasterBlaster(b, dt)
            if b.destroyed then
                SANS.images[key] = nil
            end
        end
    end
end

-- Size: 0 (small/flat), 1 (medium), 2 (large) (according to JCW87's documentation)
function SANS.attackloader.GasterBlaster(Size, StartX, StartY, EndX, EndY, EndAngle, SpinTime, BlastTime)
    Size = tonumber(Size) or 0
    StartX = tonumber(StartX) or 0
    StartY = tonumber(StartY) or 0
    EndX = tonumber(EndX) or StartX
    EndY = tonumber(EndY) or StartY
    EndAngle = tonumber(EndAngle) or 0
    SpinTime = tonumber(SpinTime) or 0
    BlastTime = tonumber(BlastTime) or 0

    local bodyDefault = GetTexture("GasterBlaster")

    local widthScale, heightScale
    if Size <= 0 then
        widthScale, heightScale = 2, 1
    elseif Size == 1 then
        widthScale, heightScale = 2, 2
    else
        widthScale, heightScale = 3, 3
    end

    SANS.attacksCount.GasterBlaster = (SANS.attacksCount.GasterBlaster or 0) + 1
    local key = SANS.attacksCount.GasterBlaster > 1 and ("GasterBlaster" .. SANS.attacksCount.GasterBlaster) or "GasterBlaster"

    local b = {
        isAttack = true,
        isGasterBlaster = true,
        visible = true,
        draw = SANS.DrawGasterBlaster,
        karma = 10, -- obj_gasterblaster's innate_karma, see karma.lua

        x = StartX,
        y = StartY,
        endX = EndX,
        endY = EndY,
        ang = 90,
        endAng = EndAngle,
        state = STATE_ENTER,
        timer = SpinTime,
        blastTime = BlastTime,

        widthScale = widthScale,
        heightScale = heightScale,
        imgW = bodyDefault:getWidth(),
        imgH = bodyDefault:getHeight(),
        bodyImg = bodyDefault,
        animFrame = 0,
        animTimer = 0,

        leaveSpeed = 0,
        beamVisible = false,
        beamTimer = 0,
        beamBaseSize = 0,
        beamSineSize = 0,
        beamOpacity = 100,
    }

    -- Blasters that don't need to travel (Start == End) still snap their angle instantly
    if b.x == b.endX and b.y == b.endY then
        b.ang = b.endAng
    end

    SANS.PlaySound("GasterBlaster", 1.2)

    SANS.images[key] = b
end
