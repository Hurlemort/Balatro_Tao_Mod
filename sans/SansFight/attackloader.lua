SANS.attackloader = SANS.attackloader or {}

-- CSV callable functions

function SANS.attackloader.CombatZoneResize(LeftPosition, TopPosition, RightPosition, BottomPosition, FinishAction)
    SANS.target_combatZone.left = tonumber(LeftPosition) or SANS.combatZone.left
    SANS.target_combatZone.top = tonumber(TopPosition) or SANS.combatZone.top
    SANS.target_combatZone.right = tonumber(RightPosition) or SANS.combatZone.right
    SANS.target_combatZone.bottom = tonumber(BottomPosition) or SANS.combatZone.bottom

    SANS.combatZoneFinishAction = FinishAction
end

function SANS.attackloader.CombatZoneResizeInstant(LeftPosition, TopPosition, RightPosition, BottomPosition)
    LeftPosition = tonumber(LeftPosition) or SANS.combatZone.left
    TopPosition = tonumber(TopPosition) or SANS.combatZone.top
    RightPosition = tonumber(RightPosition) or SANS.combatZone.right
    BottomPosition = tonumber(BottomPosition) or SANS.combatZone.bottom

    for _, z in ipairs({ SANS.combatZone, SANS.target_combatZone }) do
        z.left = LeftPosition
        z.top = TopPosition
        z.right = RightPosition
        z.bottom = BottomPosition
    end

    SANS.combatZoneFinishAction = nil
end

-- changes the speed at which the combat zone resizes (default 200 px/sec)
function SANS.attackloader.CombatZoneSpeed(Speed)
    SANS.combatZoneResizeSpeed = tonumber(Speed) or SANS.combatZoneResizeSpeed
end

-- attacks that pause the music while the screen is black (see SANS.attackrunner.RunNextAttack's PHASE2_SEQUENCE)
local MUSIC_PAUSE_ATTACKS = { sans_multi1 = true, sans_multi2 = true, sans_multi3 = true }

-- Also clears any bones/projectiles currently on screen
function SANS.attackloader.BlackScreen(BooleanEnabled)
    SANS.blackScreen = (tonumber(BooleanEnabled) or 0) ~= 0
    SANS.DestroyAllAttacks()

    local active = SANS.attackrunner.active
    if active and MUSIC_PAUSE_ATTACKS[active.name] then
        SANS.SetMusicPaused(SANS.blackScreen)
    end
end

-- resets everything an attack could leave dirty for the next one (fall speed, slam damage, sans position...), called from both EndAttack and StartAttack
function SANS.attackloader.ResetVars()
    SANS.combatZoneResizeSpeed = 480
    SANS.BlueHeart.maxFallSpeed = 750
    SANS.slam.damageEnabled = false
    SANS.SetMusicPaused(false) -- in case an attack ends mid-BlackScreen pause (see attackloader.BlackScreen), music must never stay paused into the next attack/menu

    -- a slam's rotation/velocity shouldn't leak into the next attack (or the menu, where PlayerHeart doubles as the cursor)
    local heart = SANS.images.PlayerHeart
    if heart then
        SANS.SetHeartRotation(heart, math.pi / 2)
        heart.vx, heart.vy = 0, 0
        heart.grounded = false
        heart.slammed = false
    end

    if SANS.animations and SANS.animations.legs then
        SANS.animations.legs.xSpeed = 0
        SANS.animations.legs.x = 320
    end

    -- sans's pose shouldn't carry over between attacks, sweat is the exception since it's meant to stick around
    if SANS.animations then
        SANS.animations.mode = "normal"
        SANS.animations.type = "Idle"
        SANS.animations.torsoAnim = "Default"
        SANS.animations.headAnim = "Default"
        SANS.animations.bodyAnim = nil
        SANS.animations.bodyFrame = 1
        SANS.animations.bodyFrameTimer = 0
    end
end

function SANS.attackloader.EndAttack()
    -- sans_final's own EndAttack call only gets reached if you survived his whole moveset, so that's our win condition
    if SANS.attackrunner.active and SANS.attackrunner.active.name == "sans_final" then
        SANS.attackrunner.active = nil
        SANS.DestroyAllAttacks()
        SANS.StartWinSequence()
        return
    end

    -- holds off opening the menu while "here we go." is still up after sans_intro, PlayIntro does it itself once dismissed
    local deferEntry = SANS.dialogue and SANS.dialogue.deferEndAttackEntry

    if not deferEntry then
        SANS.MENU.state = true
    end
    -- flavor text waits for the zone to finish resizing, ShowMenuFlavorText fires once it's done
    SANS.attackloader.CombatZoneResize(33, 251, 608, 391, not deferEntry and "ShowMenuFlavorText" or nil)
    SANS.attackloader.ResetVars()

    -- re-show the heart for the menu phase
    if SANS.images.PlayerHeart then
        SANS.images.PlayerHeart.visible = true
    end

    -- music starts once the menu after the 1st attack shows up, not before
    if not deferEntry and not SANS.attackrunner.musicStarted then
        SANS.attackrunner.musicStarted = true
        SANS.PlayMusic("mus_zz_megalovania")
    end

    -- -- Hide everything except not all of them lol
    -- SANS.attackloader.HideAllImages({ HP = true, KR = true, PlayerHeart = true })

    -- Stop whatever attack timeline is running
    SANS.attackrunner.active = nil

    -- Destroy all attacks
    SANS.DestroyAllAttacks()

    if not deferEntry then
        SANS.UpdateHighlight(SANS.MENU.icons.current_highlight_index or 1)
    end
end

-- CombatZoneResize's finish action for EndAttack's post-attack resize, see above
function SANS.attackloader.ShowMenuFlavorText()
    -- frozen once here so it doesn't change under the player's feet while they browse icons
    SANS.MENU.flavorText = SANS.ComputeFlavorText()
    SANS.SpawnMenuBonesForHits(SANS.hitAttempts) -- see menu.lua's MenuBones section
end

function SANS.attackloader.TLPause()
    local active = SANS.attackrunner.active
    if active then
        active.paused = true
    end
end

function SANS.attackloader.TLResume()
    local active = SANS.attackrunner.active
    if active then
        active.paused = false
    end
end

-- source coords are center-based, we store top-left, so convert
function SANS.attackloader.HeartTeleport(X, Y)
    local heart = SANS.images.PlayerHeart
    if not heart then return end

    X = tonumber(X)
    Y = tonumber(Y)

    if heart.img then
        local offX, offY = SANS.GetPivotToCenterOffset(heart)
        heart.x = (X or (heart.x + offX)) - offX
        heart.y = (Y or (heart.y + offY)) - offY
    else
        heart.x = X or heart.x
        heart.y = Y or heart.y
    end

    heart.visible = true -- matches source: HeartTeleport always re-shows the heart
end

-- Mode: 0 red , 1 blue (gravity + jump, see globals.lua)
function SANS.attackloader.HeartMode(Mode)
    SANS.heartMode = tonumber(Mode) or 0

    local heart = SANS.images.PlayerHeart

    -- every HeartMode call resets rotation upright, undoes any leftover slam rotation
    if heart then
        SANS.SetHeartRotation(heart, math.pi / 2)
        heart.vx, heart.vy = 0, 0
        heart.grounded = false
        heart.slammed = false
    end

    if SANS.heartMode == 1 and heart then
        local combatZone = SANS.combatZone

        heart.x, heart.y = 0, 0
        local minX, minY, maxX, maxY = SANS.GetImageBBox(heart)
        heart.x = (combatZone.left + combatZone.right) / 2 - (minX + maxX) / 2
        heart.y = combatZone.bottom - SANS.combatZoneBorder - maxY -- rest on the interior floor (border is inside the rect)

        -- seed all 4 keys so an already-held one doesn't look like a fresh jump press
        heart.heldKeys = {
            up = love.keyboard.isDown("up"),
            down = love.keyboard.isDown("down"),
            left = love.keyboard.isDown("left"),
            right = love.keyboard.isDown("right"),
        }
    end

    SANS.UpdateHeartColor()
end

-- Also doubles as the launch speed for SansSlam
function SANS.attackloader.HeartMaxFallSpeed(MaxSpeed)
    SANS.BlueHeart.maxFallSpeed = tonumber(MaxSpeed) or SANS.BlueHeart.maxFallSpeed
end

-- Direction: 0-3
local BONE_DIRECTIONS = {
    [0] = { x = 1, y = 0 },  -- right
    [1] = { x = 0, y = 1 },  -- down
    [2] = { x = -1, y = 0 }, -- left
    [3] = { x = 0, y = -1 }, -- up
}

-- Color: 0 white (default art, untinted), 1 blue
local BONE_COLORS = {
    [1] = { r = 0, g = 1, b = 252 / 255 }, -- rgb(0,255,252)
}

-- Bones are actually 3 parts : top/bottom and middle
local BONEV_BASE_HEIGHT = 24
local BONEV_TOP_HEIGHT = 6
local BONEV_BOTTOM_HEIGHT = 6
local BONEV_WIDTH = 10
local BONEV_MIDDLE_OFFSET_X = 2
local BONEV_MIDDLE_OFFSET_Y = 6

local function CreateBoneSegment(name, x, y, color)
    local key = SANS.LoadImage(name, x, y, 0, 1, 1, true, color)
    local segment = SANS.images[key]
    SANS.images[key] = nil
    return segment
end

function SANS.attackloader.BoneV(XPosition, YPosition, Height, Direction, Speed, Color)
    XPosition = tonumber(XPosition) or 0
    YPosition = tonumber(YPosition) or 0
    Height = tonumber(Height) or BONEV_BASE_HEIGHT
    Direction = tonumber(Direction) or 0
    Speed = tonumber(Speed) or 0
    Color = tonumber(Color) or 0

    local dir = BONE_DIRECTIONS[Direction] or BONE_DIRECTIONS[0]
    local middleHeight = math.max(0, Height - BONEV_TOP_HEIGHT - BONEV_BOTTOM_HEIGHT)
    local colorTable = BONE_COLORS[Color]

    local topSegment = CreateBoneSegment("BoneV_Top", XPosition, YPosition, colorTable)
    local bottomSegment = CreateBoneSegment("BoneV_Bottom", XPosition, YPosition + Height - BONEV_BOTTOM_HEIGHT, colorTable)

    SANS.attacksCount.BoneV = (SANS.attacksCount.BoneV or 0) + 1
    local key = SANS.attacksCount.BoneV > 1 and ("BoneV" .. SANS.attacksCount.BoneV) or "BoneV"

    SANS.images[key] = {
        img = nil,
        x = XPosition,
        y = YPosition,
        rotation = 0,
        scaleX = 1,
        scaleY = 1,
        visible = true,
        isAttack = true,
        hideOutsideCombatZone = true,
        clippedLayer = true, -- source's CombatZoneClipped layer sits above CombatZone (heart/BoneH/etc), drawn after them
        width = BONEV_WIDTH,
        height = Height,
        vx = dir.x * Speed,
        vy = dir.y * Speed,
        karma = 6, -- Battle.xml sets Karma=6 on BoneV creation (~line 4569), same as BoneH - the old 5 came from Undertale's obj_boneloop_v, not the C2 remake
        color = colorTable,
        topSegment = topSegment,
        bottomSegment = bottomSegment,
        middleHeight = middleHeight,
        draw = function(bone)
            -- clip anything poking past the zone edge instead of drawing over the border
            local cz = SANS.combatZone
            love.graphics.setScissor(cz.left, cz.top, cz.right - cz.left, cz.bottom - cz.top)

            love.graphics.setColor(1, 1, 1, 1)
            if bone.topSegment and bone.topSegment.img then
                love.graphics.draw(bone.topSegment.img, bone.x, bone.y)
            end

            if bone.middleHeight > 0 then
                local color = bone.color or { r = 1, g = 1, b = 1, a = 1 }
                love.graphics.setColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
                love.graphics.rectangle("fill", bone.x + BONEV_MIDDLE_OFFSET_X, bone.y + BONEV_MIDDLE_OFFSET_Y, BONEV_WIDTH - 4, bone.middleHeight)
            end

            love.graphics.setColor(1, 1, 1, 1)
            if bone.bottomSegment and bone.bottomSegment.img then
                love.graphics.draw(bone.bottomSegment.img, bone.x, bone.y + bone.height - BONEV_BOTTOM_HEIGHT)
            end

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setScissor()
        end,
    }
end

-- Self explanatory...
function SANS.attackloader.BoneVRepeat(StartX, StartY, Height, Direction, Speed, Count, Spacing)
    StartX = tonumber(StartX) or 0
    StartY = tonumber(StartY) or 0
    Count = tonumber(Count) or 0
    Spacing = tonumber(Spacing) or 0

    local dir = BONE_DIRECTIONS[tonumber(Direction) or 0] or BONE_DIRECTIONS[0]

    for i = 0, Count - 1 do
        local x = StartX - dir.x * Spacing * i
        local y = StartY - dir.y * Spacing * i
        SANS.attackloader.BoneV(x, y, Height, Direction, Speed)
    end
end


local BONEH_BASE_WIDTH = 24
local BONEH_HEIGHT = 10
local BONEH_LEFT_WIDTH = 6
local BONEH_RIGHT_WIDTH = 6
local BONEH_MIDDLE_OFFSET_X = 6
local BONEH_MIDDLE_OFFSET_Y = 2

function SANS.attackloader.BoneH(XPosition, YPosition, Width, Direction, Speed, Color)
    XPosition = tonumber(XPosition) or 0
    YPosition = tonumber(YPosition) or 0
    Width = tonumber(Width) or BONEH_BASE_WIDTH
    Direction = tonumber(Direction) or 0
    Speed = tonumber(Speed) or 0
    Color = tonumber(Color) or 0

    local dir = BONE_DIRECTIONS[Direction] or BONE_DIRECTIONS[0]
    local middleWidth = math.max(0, Width - BONEH_LEFT_WIDTH - BONEH_RIGHT_WIDTH)
    local colorTable = BONE_COLORS[Color]

    local leftSegment = CreateBoneSegment("BoneH_Left", XPosition, YPosition, colorTable)
    local rightSegment = CreateBoneSegment("BoneH_Right", XPosition + Width - BONEH_RIGHT_WIDTH, YPosition, colorTable)

    SANS.attacksCount.BoneH = (SANS.attacksCount.BoneH or 0) + 1
    local key = SANS.attacksCount.BoneH > 1 and ("BoneH" .. SANS.attacksCount.BoneH) or "BoneH"

    SANS.images[key] = {
        img = nil,
        x = XPosition,
        y = YPosition,
        rotation = 0,
        scaleX = 1,
        scaleY = 1,
        visible = true,
        isAttack = true,
        width = Width,
        height = BONEH_HEIGHT,
        vx = dir.x * Speed,
        vy = dir.y * Speed,
        karma = 6, -- obj_sansbullet_parent's default innate_karma (BoneH isn't separately listed), see karma.lua
        color = colorTable,
        leftSegment = leftSegment,
        rightSegment = rightSegment,
        middleWidth = middleWidth,
        draw = function(bone)
            -- BoneH lives on source's plain (unclipped) CombatZone layer - unlike BoneV it's never scissor-clipped, regardless of direction
            love.graphics.setColor(1, 1, 1, 1)
            if bone.leftSegment and bone.leftSegment.img then
                love.graphics.draw(bone.leftSegment.img, bone.x, bone.y)
            end

            if bone.middleWidth > 0 then
                local color = bone.color or { r = 1, g = 1, b = 1, a = 1 }
                love.graphics.setColor(color.r or 1, color.g or 1, color.b or 1, color.a or 1)
                love.graphics.rectangle("fill", bone.x + BONEH_MIDDLE_OFFSET_X, bone.y + BONEH_MIDDLE_OFFSET_Y, bone.middleWidth, BONEH_HEIGHT - 4)
            end

            love.graphics.setColor(1, 1, 1, 1)
            if bone.rightSegment and bone.rightSegment.img then
                love.graphics.draw(bone.rightSegment.img, bone.x + bone.width - BONEH_RIGHT_WIDTH, bone.y)
            end

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setScissor()
        end,
    }
end

-- Also self explanatory...
function SANS.attackloader.BoneHRepeat(StartX, StartY, Width, Direction, Speed, Count, Spacing)
    StartX = tonumber(StartX) or 0
    StartY = tonumber(StartY) or 0
    Count = tonumber(Count) or 0
    Spacing = tonumber(Spacing) or 0

    local dir = BONE_DIRECTIONS[tonumber(Direction) or 0] or BONE_DIRECTIONS[0]

    for i = 0, Count - 1 do
        local x = StartX - dir.x * Spacing * i
        local y = StartY - dir.y * Spacing * i
        SANS.attackloader.BoneH(x, y, Width, Direction, Speed)
    end
end

-- attack used in intro and final
function SANS.attackloader.SineBones(Count, Spacing, Speed, Height)
    Count = tonumber(Count) or 0
    Spacing = tonumber(Spacing) or 0
    Speed = tonumber(Speed) or 0
    Height = tonumber(Height) or 0

    local combatZone = SANS.combatZone
    local baseX, direction

    if Spacing > 0 then
        baseX, direction = combatZone.right, 2 -- enters from the right edge, moving to the left
    else
        baseX, direction = combatZone.left, 0  -- enters from the left edge, moving to the right
    end

    local GAP = 39
    local TOP_MARGIN = 6
    local BOTTOM_MARGIN = 5

    for i = 0, Count - 1 do
        local x = baseX + Spacing * i
        local sine = math.floor(math.sin(i / 3) * 28)

        local topY = combatZone.top + TOP_MARGIN
        local topHeight = Height + sine
        SANS.attackloader.BoneV(x, topY, topHeight, direction, Speed)

        local bottomY = topY + topHeight + GAP
        local bottomHeight = combatZone.bottom - BOTTOM_MARGIN - bottomY
        SANS.attackloader.BoneV(x, bottomY, bottomHeight, direction, Speed)
    end
end

-- Platforms logic (can bounce back)
function SANS.attackloader.Platform(X, Y, Width, Direction, Speed, BooleanReverse)
    X = tonumber(X) or 0
    Y = tonumber(Y) or 0
    Width = tonumber(Width) or 0
    Direction = tonumber(Direction) or 0
    Speed = tonumber(Speed) or 0

    local dir = BONE_DIRECTIONS[Direction] or BONE_DIRECTIONS[0]

    table.insert(SANS.platforms, {
        x = X,
        y = Y,
        width = Width,
        height = SANS.PlatformConfig.height,
        vx = dir.x * Speed,
        vy = dir.y * Speed,
        reverse = (tonumber(BooleanReverse) or 0) ~= 0,
    })
end

-- Still self explanatory...
function SANS.attackloader.PlatformRepeat(StartX, StartY, Width, Direction, Speed, Count, Spacing)
    StartX = tonumber(StartX) or 0
    StartY = tonumber(StartY) or 0
    Count = tonumber(Count) or 0
    Spacing = tonumber(Spacing) or 0

    local dir = BONE_DIRECTIONS[tonumber(Direction) or 0] or BONE_DIRECTIONS[0]

    for i = 0, Count - 1 do
        local x = StartX - dir.x * Spacing * i
        local y = StartY - dir.y * Spacing * i
        SANS.attackloader.Platform(x, y, Width, Direction, Speed)
    end
end

-- SansSlam logic
SANS.slam = SANS.slam or {}

-- Direction: 0-3, same right/down/left/up convention as BONE_DIRECTIONS above.
SANS.slam.directions = SANS.slam.directions or {
    [0] = { x = 1, y = 0 },  -- right
    [1] = { x = 0, y = 1 },  -- down
    [2] = { x = -1, y = 0 }, -- left
    [3] = { x = 0, y = -1 }, -- up
}

SANS.slam.damageEnabled = SANS.slam.damageEnabled or false

-- no warning/delay, just rotates + launches the heart immediately, matches source - only BoneStab gets a telegraph
function SANS.attackloader.SansSlam(Direction)
    local dirIndex = tonumber(Direction) or 0
    local dir = SANS.slam.directions[dirIndex] or SANS.slam.directions[0]

    local heart = SANS.images.PlayerHeart
    if not heart then return end

    SANS.heartMode = 1
    SANS.UpdateHeartColor()
    heart = SANS.images.PlayerHeart

    SANS.SetHeartRotation(heart, dirIndex * (math.pi / 2)) -- 0=right,1=down,2=left,3=up, matches BONE_DIRECTIONS/GetHeartGravityAxis

    local speed = SANS.BlueHeart.maxFallSpeed
    heart.vx = dir.x * speed
    heart.vy = dir.y * speed
    heart.grounded = false
    heart.slammed = true -- consumed on the next landing (hooks.lua) - only a real SansSlam can trigger impact damage/sound, not an ordinary fast fall
end

function SANS.attackloader.SansSlamDamage(BooleanEnabled)
    SANS.slam.damageEnabled = (tonumber(BooleanEnabled) or 0) ~= 0
end

-- stab direction matches BONE_DIRECTIONS, bone count now scales with zone span instead of a flat 14 so it never overlaps on a smaller wall
local BONESTAB_REFERENCE_SPAN = 165
local BONESTAB_REFERENCE_COUNT = 14
local BONESTAB_PITCH = BONESTAB_REFERENCE_SPAN / (BONESTAB_REFERENCE_COUNT - 1)
local BONESTAB_GROW_RATE = 10

local STAB_TEXTURE_CACHE = {}
local function GetStabTexture(name)
    if not STAB_TEXTURE_CACHE[name] then
        local base = SANS.path or ""
        local last = base:sub(-1)
        if last ~= "/" and last ~= "\\" then
            base = base .. "/"
        end

        local file_data = NFS.newFileData(base .. "textures/" .. name .. ".png")
        STAB_TEXTURE_CACHE[name] = love.graphics.newImage(love.image.newImageData(file_data))
    end
    return STAB_TEXTURE_CACHE[name]
end

--Draws the stab piece : one extremity only
local function DrawBoneStabPiece(b)
    local cz = SANS.combatZone
    love.graphics.setScissor(cz.left, cz.top, cz.right - cz.left, cz.bottom - cz.top)
    love.graphics.setColor(1, 1, 1, 1)

    local cap = GetStabTexture(b.capName)
    local tip = b.wallCoord + b.growSign * b.currentLength
    local middleLen = math.max(0, b.currentLength - b.capSize)

    if b.vertical then
        local capY = (b.growSign < 0) and tip or (tip - b.capSize)
        love.graphics.draw(cap, b.transverseCoord, capY)

        if middleLen > 0 then
            local middleY = (b.growSign < 0) and (tip + b.capSize) or b.wallCoord
            love.graphics.rectangle("fill", b.transverseCoord + BONEV_MIDDLE_OFFSET_X, middleY, BONEV_WIDTH - 4, middleLen)
        end
    else
        local capX = (b.growSign < 0) and tip or (tip - b.capSize)
        love.graphics.draw(cap, capX, b.transverseCoord)

        if middleLen > 0 then
            local middleX = (b.growSign < 0) and (tip + b.capSize) or b.wallCoord
            love.graphics.rectangle("fill", middleX, b.transverseCoord + BONEH_MIDDLE_OFFSET_Y, middleLen, BONEH_HEIGHT - 4)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setScissor()
end

-- Handles the whole row of stabs
local function SpawnBoneStabRow(direction, distance, stayTime)
    local combatZone = SANS.combatZone
    local vertical = (direction == 1 or direction == 3)
    local nearEdge, farEdge
    if vertical then
        nearEdge, farEdge = combatZone.left, combatZone.right
    else
        nearEdge, farEdge = combatZone.top, combatZone.bottom
    end
    local span = farEdge - nearEdge
    local count = math.max(2, math.floor(span / BONESTAB_PITCH + 0.5) + 1)
    local pitch = span / (count - 1)

    -- spikes grow out of the interior wall face, not the outer border
    local wallCoord, growSign, capName
    local izLeft, izTop, izRight, izBottom = SANS.GetCombatZoneInterior()
    if direction == 0 then
        wallCoord, growSign, capName = izRight, -1, "BoneH_Left"
    elseif direction == 1 then
        wallCoord, growSign, capName = izBottom, -1, "BoneV_Top"
    elseif direction == 2 then
        wallCoord, growSign, capName = izLeft, 1, "BoneH_Right"
    else
        wallCoord, growSign, capName = izTop, 1, "BoneV_Bottom"
    end

    local thickness = vertical and BONEV_WIDTH or BONEH_HEIGHT
    local capSize = vertical and BONEV_TOP_HEIGHT or BONEH_LEFT_WIDTH
    local speed = distance * BONESTAB_GROW_RATE

    for i = 0, count - 1 do
        local transverseCoord = (nearEdge + pitch * i) - thickness / 2

        SANS.attacksCount.BoneStab = (SANS.attacksCount.BoneStab or 0) + 1
        local key = SANS.attacksCount.BoneStab > 1 and ("BoneStab" .. SANS.attacksCount.BoneStab) or "BoneStab"

        SANS.images[key] = {
            img = nil,
            x = vertical and transverseCoord or wallCoord,
            y = vertical and wallCoord or transverseCoord,
            rotation = 0,
            scaleX = 1,
            scaleY = 1,
            visible = true,
            isAttack = true,
            isBoneStab = true,
            clippedLayer = true, -- BoneStab lives on source's CombatZoneClipped layer too, same tier as BoneV
            vertical = vertical,
            transverseCoord = transverseCoord,
            wallCoord = wallCoord,
            growSign = growSign,
            capName = capName,
            capSize = capSize,
            currentLength = 0,
            distance = distance,
            speed = speed,
            stayTime = stayTime,
            state = "extend",
            karma = 6, -- obj_bonestab's innate_karma, see karma.lua
            draw = DrawBoneStabPiece,
        }
    end
end

-- slamming helper function
function SANS.GetBoneStabRect(b)
    local tip = b.wallCoord + b.growSign * b.currentLength

    if b.vertical then
        local top = math.min(b.wallCoord, tip)
        return b.transverseCoord, top, BONEV_WIDTH, b.currentLength
    else
        local left = math.min(b.wallCoord, tip)
        return left, b.transverseCoord, b.currentLength, BONEH_HEIGHT
    end
end

-- Advances one spike's length through extend then stay then retreat then destroyed.
local function StepBoneStab(b, dt)
    if b.state == "extend" then
        b.currentLength = math.min(b.currentLength + b.speed * dt, b.distance)
        if b.currentLength >= b.distance then
            b.state = "stay"
        end
    elseif b.state == "stay" then
        b.stayTime = b.stayTime - dt
        if b.stayTime <= 0 then
            b.state = "retreat"
        end
    elseif b.state == "retreat" then
        b.currentLength = math.max(b.currentLength - b.speed * dt, 0)
        if b.currentLength <= 0 then
            b.destroyed = true
        end
    end
end

-- actual stabbing
function SANS.attackloader.BoneStab(Direction, Distance, WarnTime, StayTime)
    Direction = tonumber(Direction) or 0
    Distance = tonumber(Distance) or 0
    WarnTime = tonumber(WarnTime) or 0
    StayTime = tonumber(StayTime) or 0

    -- Warning box flush against the interior wall face, spanning the visible field
    local left, top, right, bottom = SANS.GetCombatZoneInterior()
    local x, y, w, h

    if Direction == 0 then -- right wall
        x, y, w, h = right - Distance, top, Distance, bottom - top
    elseif Direction == 1 then -- floor
        x, y, w, h = left, bottom - Distance, right - left, Distance
    elseif Direction == 2 then -- left wall
        x, y, w, h = left, top, Distance, bottom - top
    else -- ceiling (3)
        x, y, w, h = left, top, right - left, Distance
    end

    SANS.attacksCount.BoneStabWarn = (SANS.attacksCount.BoneStabWarn or 0) + 1
    local key = SANS.attacksCount.BoneStabWarn > 1 and ("BoneStabWarn" .. SANS.attacksCount.BoneStabWarn) or "BoneStabWarn"

    SANS.images[key] = {
        img = nil,
        x = x,
        y = y,
        width = w,
        height = h,
        rotation = 0,
        scaleX = 1,
        scaleY = 1,
        visible = true,
        isAttack = true,
        isBoneStabWarn = true,
        direction = Direction,
        distance = Distance,
        warnTime = WarnTime,
        stayTime = StayTime,
        draw = function(warn)
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line", warn.x, warn.y, warn.width, warn.height)
            love.graphics.setColor(1, 1, 1, 1)
        end,
    }

    SANS.PlaySound("Warning", 1)
end

-- Called every fixed tick from the main update loop, alongside UpdateGasterBlasters/UpdatePlatforms
function SANS.UpdateBoneStabs(dt)
    local ready

    for key, b in pairs(SANS.images) do
        if b.isBoneStabWarn then
            b.warnTime = b.warnTime - dt
            if b.warnTime <= 0 then
                SANS.images[key] = nil
                ready = ready or {}
                table.insert(ready, { direction = b.direction, distance = b.distance, stayTime = b.stayTime })
            end
        elseif b.isBoneStab then
            StepBoneStab(b, dt)
            if b.destroyed then
                SANS.images[key] = nil
            end
        end
    end

    if ready then
        for _, r in ipairs(ready) do
            SANS.PlaySound("BoneStab", 1)
            SpawnBoneStabRow(r.direction, r.distance, r.stayTime)
        end
    end
end
