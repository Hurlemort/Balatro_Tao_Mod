-- everything menu-related lives here: the FIGHT/ACT/ITEM/MERCY action menu and the FIGHT targeting minigame

SANS.MENU = SANS.MENU or {state = false}
SANS.MENU.icons = SANS.MENU.icons or { UIFight = false, UIAct = false, UIItem = false, UIMercy = false, current_highlight_index = 1}
SANS.MENU.icons_list = {"UIFight", "UIAct", "UIItem", "UIMercy"}
SANS.MENU.icons_Xoffset = {25, 27, 25, 24} -- offset to center the heart on each icon
SANS.MENU.fontScale = 2

-- top-level flavor line: phase text wins over karma tier, karma snapshotted at attack start
SANS.MENU.flavorText = SANS.MENU.flavorText or nil
SANS.MENU.karmaSnapshot = SANS.MENU.karmaSnapshot or 0

-- highest KR first, first tier the snapshot clears wins
local KARMA_TIER_TEXT = {
    { min = 30, text = "* Doomed to death of KARMA!" },
    { min = 20, text = "* KARMA coursing through your\n  veins." },
    { min = 10, text = "* You felt your sins weighing\n  on your neck." },
    { min = 0,  text = "* You felt your sins crawling\n  on your back." },
}

-- exact hitAttempts -> text mapping
local PHASE_TEXT = {
    [0]  = "* You feel like you're going to\n  have a bad time.",
    [1]  = "* Just keep attacking.",
    [4]  = "* Sans's movements grow a little\n  wearier.",
    [9]  = "* Sans's movements seem to be\n  slower.",
    [13] = "* Sans is sparing you.",
    [14] = "* Felt like a turning point.",
    [15] = "* The REAL battle finally begins.",
    [19] = "* Reading this doesn't seem\n  like the best use of time.",
    [20] = "* Sans is starting to look\n  really tired.",
    [21] = "* Sans is preparing something.",
    [22] = "* Sans is getting ready to\n  use his special attack.",
}

function SANS.ComputeFlavorText()
    local phaseText = PHASE_TEXT[SANS.hitAttempts]
    if phaseText then return phaseText end

    local kr = SANS.MENU.karmaSnapshot or 0
    for _, tier in ipairs(KARMA_TIER_TEXT) do
        if kr >= tier.min then return tier.text end
    end
    return KARMA_TIER_TEXT[#KARMA_TIER_TEXT].text
end

-- checks hitAttempts against MenuBones' two trigger windows and spawns whichever qualifies
function SANS.SpawnMenuBonesForHits(hits)
    if hits > 13 and hits ~= 16 and hits ~= 17 and hits <= 22 then
        SANS.SpawnMenuBoneLeft()
    end
    if hits > 15 and hits <= 22 then
        SANS.SpawnMenuBoneBottom()
    end
end

-- right after sans_spare, his name is tinted yellow wherever it's shown as a menu target
function SANS.IsSansSparing()
    return SANS.hitAttempts == 13
end

-- only the top-level flavor line animates, the static "* Sans"/"* Check"/"* Spare" labels don't
SANS.MENU.textReveal = SANS.MENU.textReveal or { key = nil, revealed = 0 }

local function MenuLabelKey()
    local m = SANS.MENU
    if SANS.battleText then return nil end -- battleText (ITEM/CHECK's confirmed flavor text) owns its own reveal below
    if SANS.dialogue.active then return nil end -- flavor text must never animate/blip while Sans is talking
    if not m.substate and m.state and m.flavorText then return "flavor" end
    return nil
end

local function MenuLabelTexts(key)
    if key == "flavor" then
        return SANS.MENU.flavorText and { SANS.MENU.flavorText } or {}
    end
    return {}
end

-- called once per fixed tick, no-op unless a label's currently supposed to be showing
function SANS.UpdateMenuTextReveal(dt)
    local key = MenuLabelKey()
    local r = SANS.MENU.textReveal

    if key ~= r.key then
        r.key = key
        r.revealed = 0
        return -- the tick a label first appears just shows 0 characters, same as a fresh dialogue bubble
    end
    if not key then return end

    local texts = MenuLabelTexts(key)
    local maxLen = 0
    for _, t in ipairs(texts) do maxLen = math.max(maxLen, #t) end
    if r.revealed >= maxLen then return end

    r.revealed = r.revealed + 1
    for _, t in ipairs(texts) do
        if r.revealed <= #t and not SANS.IsSilentChar(t:sub(r.revealed, r.revealed)) then
            SANS.PlaySound("BattleText", 1)
            break
        end
    end
end

-- clips text to however much has revealed so far
function SANS.RevealMenuText(fullText)
    local r = SANS.MENU.textReveal
    return fullText:sub(1, math.min(r.revealed or 0, #fullText))
end

SANS.DEFAULT_ITEMS = {
    { menuName = "Pie", amount = 99, altName = "Butterscotch Pie"},
    { menuName = "I. Noodles", amount = 90, altName = "Instant Noodles"},
    { menuName = "Steak", amount = 60, altName = "Face Steak"},
    { menuName = "L. Hero", amount = 40, altName = "Legendary Hero"},
    { menuName = "L. Hero", amount = 40, altName = "Legendary Hero"},
    { menuName = "L. Hero", amount = 40, altName = "Legendary Hero"},
    { menuName = "L. Hero", amount = 40, altName = "Legendary Hero"},
    { menuName = "L. Hero", amount = 40, altName = "Legendary Hero"},
}
SANS.items = copy_table(SANS.DEFAULT_ITEMS)

function SANS.LoadUI()
    -- Get last highlighted icon
    local last = SANS.MENU.icons[SANS.MENU.icons.current_highlight_index or 1]

    -- Layout settings
    local iconW, iconH = 110, 42
    local paddingSides, paddingBot = 28, 1
    local containerW = 640 - 2 * paddingSides
    local containerH = iconH
    local containerX = paddingSides
    local containerY = 480 - paddingBot - containerH

    local spaceBetween = (containerW - (4*iconW)) / 3

    -- Load all normal + highlighted versions
    for i, name in ipairs({ "UIFight", "UIAct", "UIItem", "UIMercy" }) do
        local x = containerX + (i - 1) * (iconW + spaceBetween)
        local y = containerY

        -- Normal version
        local normal = name
        SANS.LoadImage(normal, x, y, 0, 1, 1, false)

        -- Highlight version
        local highlight = name .. "_Highlight"
        SANS.LoadImage(highlight, x, y, 0, 1, 1, false)

        -- Set visibility right
        if SANS.images[normal] then
            SANS.images[normal].visible = (name ~= last)
        end
        if SANS.images[highlight] then
            SANS.images[highlight].visible = (name == last)
        end
    end
end

-- these are the original committed values, reverted back to after the XML-audit numbers looked wrong in actual play
function SANS.SnapHeart(x,y)
    SANS.images.PlayerHeart.x = 70 + (x * 227)
    SANS.images.PlayerHeart.y = 268 + (y * 31)
end

function SANS.DrawSubstate(substate)
    if substate == 1 then
        -- shows "* Sans" first, the targeting minigame only starts on the NEXT Enter press
        if SANS.fight.state then
            SANS.DrawFightMinigame()
        else
            if SANS.IsSansSparing() then love.graphics.setColor(1, 1, 0, 1) end
            SANS.DrawText("DefaultFont", "* Sans", 91, 263, 2, SANS.MENU.fontScale, SANS.MENU.fontScale)
            love.graphics.setColor(1, 1, 1, 1)
        end
        SANS.SnapHeart(0,0)
    end
    if substate == 2 then
        if SANS.battleText then
            -- Check's flavor text replaces the Sans/Check line entirely, same as item flavor text below
            SANS.DrawBattleText()
        elseif not SANS.MENU.act then
            if SANS.IsSansSparing() then love.graphics.setColor(1, 1, 0, 1) end
            SANS.DrawText("DefaultFont", "* Sans", 91, 263, 2, SANS.MENU.fontScale, SANS.MENU.fontScale)
            love.graphics.setColor(1, 1, 1, 1)
        else
            SANS.DrawText("DefaultFont", "* Check", 91, 263, 2, SANS.MENU.fontScale, SANS.MENU.fontScale)
        end
        SANS.SnapHeart(0,0)
    end
    if substate == 3 then
        -- once an item's used, the flavor text replaces the item grid entirely
        if SANS.battleText then
            SANS.DrawBattleText()
        else
            SANS.DrawItemMenu()
        end
    end
    if substate == 4 then
        if SANS.IsSansSparing() then love.graphics.setColor(1, 1, 0, 1) end
        SANS.DrawText("DefaultFont", "* Spare", 91, 263, 2, SANS.MENU.fontScale, SANS.MENU.fontScale)
        love.graphics.setColor(1, 1, 1, 1)
        SANS.SnapHeart(0,0)
    end
    return
end

function SANS.DrawItemMenu()
    SANS.MENU.item_page = SANS.MENU.item_page or 1
    SANS.MENU.selected_item_index = SANS.MENU.selected_item_index or 1

    -- reverted 2026-07-23 (2nd pass) back to the original committed values, same reason as SnapHeart above
    local positions = {
        {91, 263},
        {318, 263},
        {91, 294},
        {318, 294}
    }

    -- get which item to draw on this page
    local startIndex = (SANS.MENU.item_page - 1) * 4 + 1
    local endIndex = math.min(startIndex + 3, #SANS.items)
    local itemsToDraw = {}
    for i = startIndex, endIndex do
        table.insert(itemsToDraw, SANS.items[i])
    end

    -- draw the 4 (or less) items
    for i, item in ipairs(itemsToDraw) do
        local pos = positions[i]
        if item and pos then
            SANS.DrawText("DefaultFont", "* " .. item.menuName, pos[1], pos[2], 2, SANS.MENU.fontScale, SANS.MENU.fontScale)
        end
    end

    -- draw page number - reverted 2026-07-23 (2nd pass) back to the original committed value
    SANS.DrawText("DefaultFont", "PAGE " .. tostring(SANS.MENU.item_page), 363, 325, 2, SANS.MENU.fontScale, SANS.MENU.fontScale)

    -- Snap heart position
    local snapPositions = {
        {0, 0}, -- 1
        {1, 0}, -- 2
        {0, 1}, -- 3
        {1, 1}  -- 4
    }
    local pos = snapPositions[SANS.MENU.selected_item_index]
    if pos then
        SANS.SnapHeart(pos[1], pos[2])
    end
end

-- using an item hides the heart, heals, shows a typewriter "you ate X" text, then goes to the next attack
SANS.battleText = SANS.battleText or nil

function SANS.UseSelectedItem()
    local page = SANS.MENU.item_page or 1
    local idx = (page - 1) * 4 + (SANS.MENU.selected_item_index or 1)
    local item = SANS.items[idx]
    if not item then return end -- empty slot/empty inventory: nothing to use

    table.remove(SANS.items, idx)

    -- heal always sticks (capped at max_hp), karma gets reduced instead if the two together would overflow
    local p = SANS.player
    p.hp = math.min(p.max_hp, p.hp + item.amount)
    if p.hp + p.kr > p.max_hp then
        p.kr = p.max_hp - p.hp
    end

    SANS.PlaySound("PlayerHeal", 1)

    local heart = SANS.images.PlayerHeart
    if heart then heart.visible = false end -- MenuUseItem sets PlayerHeart invisible for the text's duration

    -- "you eat" present tense is intentional, and shows the raw amount even if the heal got capped
    SANS.battleText = {
        text = "* You eat the " .. item.altName .. ".\n* You recovered " .. item.amount .. " HP!",
        revealed = 0,
    }

    -- next open of the item menu starts from a clean page/slot
    SANS.MENU.item_page = 1
    SANS.MENU.selected_item_index = 1
end

-- 1st check gives a unique line, every one after just repeats "keep attacking"
SANS.checkCount = SANS.checkCount or 0

function SANS.UseCheck()
    SANS.checkCount = SANS.checkCount + 1

    local text
    if SANS.checkCount == 1 then
        text = "* SANS 1 ATK 1 DEF\n* The easiest enemy. \n* Can only deal 1 damage."
    else
        text = "* Can't keep dodging forever.\n* Keep attacking."
    end

    SANS.battleText = { text = text, revealed = 0 }

    local heart = SANS.images.PlayerHeart
    if heart then heart.visible = false end -- matches ITEM's heart-hide for the text's duration
end

-- sparing while Sans isn't spareable yet does nothing, no text/dialogue, straight to the next attack. Sparing while
-- he IS spareable (hits==13) instead plays his ending (SANS.StartSpareSequence, dialogue.lua)
function SANS.UseSpare()
    SANS.MENU.substate = nil
    if SANS.IsSansSparing() then
        SANS.StartSpareSequence()
    else
        SANS.attackrunner.RunNextAttack()
    end
end

-- same cadence as SansText's reveal, both typewriters run at the same speed
function SANS.UpdateBattleText(dt)
    local bt = SANS.battleText
    if not bt then return end

    if bt.revealed < #bt.text then
        bt.revealed = bt.revealed + 1
        local c = bt.text:sub(bt.revealed, bt.revealed)
        if not SANS.IsSilentChar(c) then
            SANS.PlaySound("BattleText", 1)
        end
    end
end

-- Enter fast-forwards if still revealing, otherwise dismisses and starts the next attack directly
function SANS.AdvanceBattleText()
    local bt = SANS.battleText
    if not bt then return end

    if bt.revealed < #bt.text then
        bt.revealed = #bt.text
        return
    end

    SANS.battleText = nil
    SANS.MENU.substate = nil
    SANS.MENU.act = nil -- no-op for ITEM; for CHECK this is what unlocks icon navigation again (see HandleMenuKeypress)

    local heart = SANS.images.PlayerHeart
    if heart then heart.visible = true end -- attacks expect a visible heart (EndAttack normally re-shows it)

    if SANS.IsSansSparing() then
        -- while sparable, ITEM/CHECK must never advance the attack sequence - only FIGHT/SPARE may leave this state
        SANS.attackrunner.StartAttack("sans_spare")
    else
        SANS.attackrunner.RunNextAttack()
    end
end

-- drawn at the same (48,272) "InfoText" DefaultFont slot the top-level flavor text uses, not the "* Sans"-style label slot
function SANS.DrawBattleText()
    local bt = SANS.battleText
    if not bt then return end
    SANS.DrawText("DefaultFont", bt.text:sub(1, bt.revealed), 48, 272, 2, SANS.MENU.fontScale, SANS.MENU.fontScale)
end

function SANS.UpdateHighlight(index)
    local icons = SANS.MENU.icons_list
    for i, name in ipairs(icons) do
        local normal = SANS.images[name]
        local highlight = SANS.images[name .. "_Highlight"]

        if normal then
            normal.visible = (name ~= icons[index])
        end
        if highlight then
            highlight.visible = (name == icons[index])
            SANS.images.PlayerHeart.x = SANS.images[icons[index]].x + SANS.MENU.icons_Xoffset[index]
            SANS.images.PlayerHeart.y = SANS.images[icons[index]].y + 13
        end
    end
end

-- when an attack is running, each menu icon goes back to its normal version
function SANS.ClearHighlight()
    local icons = SANS.MENU.icons_list
    for _, name in ipairs(icons) do
        local normal = SANS.images[name]
        local highlight = SANS.images[name .. "_Highlight"]

        if normal then normal.visible = true end
        if highlight then highlight.visible = false end
    end
end

-- handles icon navigation, substates, the FIGHT minigame's input, and item submenu movement
function SANS.HandleMenuKeypress(scancode, isrepeat)
    if not (SANS.images.PlayerHeart and SANS.MENU.state) then return end

    -- item flavor text owns ALL input while it's up, nothing else can run underneath it
    if SANS.battleText then
        if scancode == "return" and not isrepeat then
            SANS.AdvanceBattleText()
        elseif scancode == "x" and not isrepeat then
            SANS.battleText.revealed = #SANS.battleText.text
        end
        return
    end

    local icons = SANS.MENU.icons_list
    local index = SANS.MENU.icons.current_highlight_index
    local hasIndexChanged = false

    if not SANS.MENU.substate and not SANS.MENU.act then
        if scancode == "left" and not isrepeat then
            index = index - 1
            if index < 1 then index = #icons end
            hasIndexChanged = true
        end
        if scancode == "right" and not isrepeat then
            index = index + 1
            if index > #icons then index = 1 end
            hasIndexChanged = true
        end
        if hasIndexChanged then
            print("Icon changed to " .. icons[index])
            SANS.MENU.icons.current_highlight_index = index
            SANS.UpdateHighlight(index)
            SANS.images.PlayerHeart.rotation = math.pi / 2
            SANS.PlaySound("MenuCursor", 1)
        end
    end

    if scancode == "return" and not isrepeat then
        if not SANS.MENU.substate and not SANS.MENU.act then
            -- 1st Enter just enters the substate, targeting doesn't start till the NEXT Enter
            SANS.MENU.substate = index
            print("Substate is " .. tostring(index))
            SANS.PlaySound("MenuSelect", 1)
        elseif SANS.MENU.substate == 1 then
            -- 2nd Enter starts the minigame, every Enter after that (even mid-growth) resolves the attempt
            if SANS.fight.state then
                SANS.ResolveFightAttempt()
            else
                SANS.StartFightMinigame()
            end
        elseif SANS.MENU.substate == 2 and not SANS.MENU.act then
            SANS.MENU.act = true
            print("Act is true (from substate 2)")
            SANS.PlaySound("MenuSelect", 1)
        elseif SANS.MENU.substate == 2 and SANS.MENU.act then
            SANS.UseCheck()
        elseif SANS.MENU.substate == 3 then
            SANS.UseSelectedItem()
        elseif SANS.MENU.substate == 4 then
            SANS.UseSpare()
        else
            print("Nothing")
        end
    end

    if scancode == "x" and not isrepeat then
        if SANS.MENU.act then
            SANS.MENU.act = nil
            SANS.MENU.substate = 2
            print("Act is nil")
            print("Substate is " .. tostring(SANS.MENU.substate))
        elseif SANS.MENU.substate then
            -- once the fight minigame itself is actually running (target growing/sliding), "x" is locked out entirely -
            -- backing out is only allowed at the "* Sans" label stage, before the 2nd Enter starts it for real
            if SANS.MENU.substate == 1 and SANS.fight.state then
                return
            end

            print("Substate is nil (was " .. tostring(SANS.MENU.substate) .. ")")
            if SANS.MENU.substate == 1 then
                SANS.CancelFightMinigame()
            end
            if SANS.MENU.selected_item_index then SANS.MENU.selected_item_index = nil end
            SANS.UpdateHighlight(SANS.MENU.icons.current_highlight_index or 1)
            SANS.MENU.substate = nil
        end
    end

    -- movement inside the items menu
    if SANS.MENU.substate == 3 then
        SANS.MENU.selected_item_index = SANS.MENU.selected_item_index or 1
        SANS.MENU.item_page = SANS.MENU.item_page or 1
        local subIndex = SANS.MENU.selected_item_index
        local page = SANS.MENU.item_page
        local itemCount = #SANS.items
        local hasSecondPage = itemCount > 4

        -- grid movement
        if scancode == "left" and (subIndex == 2 or subIndex == 4) then
            SANS.MENU.selected_item_index = subIndex - 1
        elseif scancode == "right" and (subIndex == 1 or subIndex == 3) then
            SANS.MENU.selected_item_index = subIndex + 1
        elseif scancode == "up" and (subIndex == 3 or subIndex == 4) then
            SANS.MENU.selected_item_index = subIndex - 2
        elseif scancode == "down" and (subIndex == 1 or subIndex == 2) then
            SANS.MENU.selected_item_index = subIndex + 2
        end

        -- page switching
        if hasSecondPage then
            -- go to page 2
            if page == 1 and scancode == "right" and (subIndex == 2 or subIndex == 4) then
                SANS.MENU.item_page = 2
                SANS.MENU.selected_item_index = (subIndex == 2) and 1 or 3
                print("Switched to page 2")
            end
            -- go back to page 1
            if page == 2 and scancode == "left" and (subIndex == 1 or subIndex == 3) then
                SANS.MENU.item_page = 1
                SANS.MENU.selected_item_index = (subIndex == 1) and 2 or 4
                print("Returned to page 1")
            end
        end
    end
end

-- The FIGHT minigame: 2nd Enter shows the target bar at full size and starts the marker sliding immediately (source has no grow-in delay), hitting Enter while it slides plays the strike/dodge/MISS sequence, and every swing bumps hitAttempts which drives the attack phases.
SANS.fight = SANS.fight or { state = nil }
SANS.hitAttempts = SANS.hitAttempts or 0

local TARGET_RETRACT_TIME = 0.15 -- how fast the Target bar shrinks back on a swing, instead of vanishing instantly
local MARKER_SPEED = 360 -- TargetChoice.X + cos(Direction*90)*dt*360

-- dodge timings/curve, dt*225 is degrees so gets converted to radians at use
local DODGE_OUT_TIME = 0.4   -- state 1: sliding away from center
local DODGE_HOLD_TIME = 1.1  -- state 2: held at the dodge position
local DODGE_BACK_TIME = 0.4  -- state 3: sliding back to center
local DODGE_DISTANCE = 100
local MISS_TEXT_DELAY = 0.6  -- extra wait (from the start of the hold) before "MISS" shows
local MISS_DISPLAY_TIME = 1.5

-- stays frozen on frame 1 while sliding, only starts looping once struck
local CHOICE_FRAME_TIME = { 3 / 30, 2 / 30 }
local CHOICE_FRAME_NAMES = { "TargetChoice1", "TargetChoice2" }

-- strike's 6 frames, hotspot varies wildly per frame which is what makes it read as a sweep instead of a stretch
local STRIKE_FRAME_TIME = 1 / 10
local STRIKE_FRAMES = {
    { name = "Strike1", ox = -4, oy = 34 },
    { name = "Strike2", ox = -2, oy = 30 },
    { name = "Strike3", ox = 0,  oy = 18 },
    { name = "Strike4", ox = 0,  oy = 10 },
    { name = "Strike5", ox = 0,  oy = -24 },
    { name = "Strike6", ox = -2, oy = -48 },
}
local STRIKE_SCALE = 1.5

-- Target/TargetChoice/Strike are kept out of SANS.images so DrawFightMinigame can draw them in a fixed order instead of pairs()'s undefined one
local MENU_TEXTURE_CACHE = {}
local function GetMenuTexture(name)
    if not MENU_TEXTURE_CACHE[name] then
        local base = SANS.path or ""
        local last = base:sub(-1)
        if last ~= "/" and last ~= "\\" then
            base = base .. "/"
        end
        local file_data = NFS.newFileData(base .. "textures/" .. name .. ".png")
        MENU_TEXTURE_CACHE[name] = love.graphics.newImage(love.image.newImageData(file_data))
    end
    return MENU_TEXTURE_CACHE[name]
end

-- MenuBones: purely decorative, a bone bounces in from the left + bones pop up under icons in phase 2, no damage
SANS.menuBones = SANS.menuBones or {
    left = nil,             -- { x, y, timer, destroy } or nil - single instance, matches the source
    bottomActive = false,   -- whether the 0.6s spawn cycle below is currently running
    bottomTimer = 0,
    bottomAlternate = 0,    -- flips 0/1 every spawn cycle: alternates which icon pair gets a bone
    bottom = {},            -- list of { x, y, button, state } - state 0=rising,1=sliding,2=falling
}

-- both nudged 8px higher than Battle.xml's authored 270/440, per explicit request - a deliberate mod-only tweak
local MENUBONE_LEFT_Y = 262
local MENUBONE_BOTTOM_SPAWN_INTERVAL = 0.6
local MENUBONE_BOTTOM_RISE_SPEED = 300
local MENUBONE_BOTTOM_RISE_TARGET_Y = 432
local MENUBONE_BOTTOM_SLIDE_SPEED = 150
local MENUBONE_BOTTOM_SLIDE_MARGIN = 14
local MENUBONE_BOTTOM_FALL_SPEED = 300
local MENUBONE_LAYOUT_HEIGHT = 480 -- C2's LayoutHeight - matches this mod's 640x480 framebuffer

function SANS.SpawnMenuBoneLeft()
    SANS.menuBones.left = { x = -30, y = MENUBONE_LEFT_Y, timer = 0, destroy = false }
end

function SANS.SpawnMenuBoneBottom()
    SANS.menuBones.bottomActive = true
    SANS.menuBones.bottomTimer = 0
    SANS.menuBones.bottomAlternate = 0
end

function SANS.MenuBonesOff()
    if SANS.menuBones.left then
        -- flagged not removed instantly, it swings back out past the left edge first
        SANS.menuBones.left.destroy = true
    end
    -- stops future spawns only, bones already mid-flight finish their cycle uninterrupted
    SANS.menuBones.bottomActive = false
end

-- buttonIndex is 0-based (0=Fight,1=Act,2=Item,3=Mercy), icons_list is the 1-based Lua equivalent
local function SpawnOneMenuBoneBottom(buttonIndex)
    local name = SANS.MENU.icons_list[buttonIndex + 1]
    local img = name and SANS.images[name]
    if not img then return end

    local _, _, bboxRight = SANS.GetImageBBox(img)
    table.insert(SANS.menuBones.bottom, {
        x = bboxRight, -- starts flush against the icon's right edge, matching Battle.xml's "Set X = UIButtons.BBoxRight" on spawn
        y = MENUBONE_LAYOUT_HEIGHT, -- off-screen below, rises into view
        button = buttonIndex,
        state = 0,
    })
end

-- runs every fixed tick regardless of menu state, no-op unless something's active
function SANS.UpdateMenuBones(dt)
    local mb = SANS.menuBones

    local left = mb.left
    if left then
        left.timer = left.timer + dt
        -- the sine bounce formula, degrees converted to radians same as the dodge curve
        left.x = -30 + math.abs(math.sin(math.rad(600 * left.timer / math.pi))) * 105
        if left.x > 64 then
            -- damping: slows down once it swings deep into frame, a lazy tired-looking bounce
            left.timer = left.timer - dt * 0.72
        end
        if left.destroy and left.x <= -8 then
            mb.left = nil
        end
    end

    if mb.bottomActive then
        mb.bottomTimer = mb.bottomTimer + dt
        if mb.bottomTimer >= MENUBONE_BOTTOM_SPAWN_INTERVAL then
            mb.bottomTimer = mb.bottomTimer - MENUBONE_BOTTOM_SPAWN_INTERVAL
            local alt = mb.bottomAlternate
            SpawnOneMenuBoneBottom(0 + alt) -- Fight/Item pair on one cycle, Act/Mercy on the next
            SpawnOneMenuBoneBottom(2 + alt)
            mb.bottomAlternate = (alt == 0) and 1 or 0
        end
    end

    for i = #mb.bottom, 1, -1 do
        local b = mb.bottom[i]

        if b.state == 0 then
            b.y = b.y - MENUBONE_BOTTOM_RISE_SPEED * dt
            if b.y <= MENUBONE_BOTTOM_RISE_TARGET_Y then
                b.y = MENUBONE_BOTTOM_RISE_TARGET_Y
                b.state = 1
            end
        elseif b.state == 1 then
            b.x = b.x - MENUBONE_BOTTOM_SLIDE_SPEED * dt
            local name = SANS.MENU.icons_list[b.button + 1]
            local img = name and SANS.images[name]
            if img then
                local bboxLeft = SANS.GetImageBBox(img)
                local target = bboxLeft - MENUBONE_BOTTOM_SLIDE_MARGIN
                if b.x <= target then
                    b.x = target
                    b.state = 2
                end
            end
        elseif b.state == 2 then
            b.y = b.y + MENUBONE_BOTTOM_FALL_SPEED * dt
            if b.y >= MENUBONE_LAYOUT_HEIGHT then
                table.remove(mb.bottom, i)
            end
        end
    end
end

-- drawn above the menu icon sprites, no-op unless something's active
function SANS.DrawMenuBones()
    local mb = SANS.menuBones
    love.graphics.setColor(1, 1, 1, 1)

    if mb.left then
        love.graphics.draw(GetMenuTexture("MenuBoneLeft"), mb.left.x, mb.left.y)
    end
    for _, b in ipairs(mb.bottom) do
        love.graphics.draw(GetMenuTexture("MenuBoneBottom"), b.x, b.y)
    end
end

local function ClearFightVisuals()
    local f = SANS.fight
    f.target = nil
    f.marker = nil
    f.strike = nil
end

local function SpawnMarker()
    local f = SANS.fight
    local cz = SANS.combatZone
    local tex = GetMenuTexture(CHOICE_FRAME_NAMES[1])

    local marker = {
        img = tex,
        choiceFrame = 1,
        choiceTimer = 0,
        y = f.centerY - tex:getHeight() / 2,
    }

    if love.math.random() < 0.5 then
        marker.x = cz.left - tex:getWidth() / 2
        marker.vx = MARKER_SPEED
    else
        marker.x = cz.right - tex:getWidth() / 2
        marker.vx = -MARKER_SPEED
    end

    f.marker = marker
end

-- starts the targeting sequence, called on the 2nd Enter press
function SANS.StartFightMinigame()
    if SANS.fight.state then return end

    local heart = SANS.images.PlayerHeart
    if heart then heart.visible = false end

    local cz = SANS.combatZone
    local cx, cy = (cz.left + cz.right) / 2, (cz.top + cz.bottom) / 2
    local tex = GetMenuTexture("Target")

    SANS.fight.state = "sliding"
    SANS.fight.centerX = cx
    SANS.fight.centerY = cy
    SANS.fight.target = {
        img = tex,
        x = cx - tex:getWidth() / 2,
        y = cy - tex:getHeight() / 2,
        scaleX = 1,
    }
    SpawnMarker()
end

-- Called every fixed tick regardless of menu state (no-op unless a fight is active).
function SANS.UpdateFightMinigame(dt)
    local f = SANS.fight
    if not f.state then return end

    if f.state == "sliding" then
        local marker = f.marker
        marker.x = marker.x + marker.vx * dt

        local cz = SANS.combatZone
        local exited = (marker.vx > 0 and marker.x > cz.right) or (marker.vx < 0 and marker.x + marker.img:getWidth() < cz.left)

        if exited then
            -- No input: straight to the next attack, no MISS, no dodge.
            ClearFightVisuals()
            SANS.FinishFightMinigame()
        end
    elseif f.state == "striking" then
        SANS.UpdateSansDodge(dt)

        local target = f.target
        if target then
            target.retractTimer = target.retractTimer + dt
            local t = math.min(target.retractTimer / TARGET_RETRACT_TIME, 1)
            target.scaleX = target.retractFrom * (1 - t)
            target.x = f.centerX - (target.img:getWidth() * target.scaleX) / 2
            if t >= 1 then
                f.target = nil
            end
        end

        local marker = f.marker
        if marker then
            marker.choiceTimer = marker.choiceTimer + dt
            if marker.choiceTimer >= CHOICE_FRAME_TIME[marker.choiceFrame] then
                marker.choiceTimer = marker.choiceTimer - CHOICE_FRAME_TIME[marker.choiceFrame]
                marker.choiceFrame = (marker.choiceFrame == 1) and 2 or 1
                marker.img = GetMenuTexture(CHOICE_FRAME_NAMES[marker.choiceFrame])
            end
        end

        local strike = f.strike
        if strike then
            strike.timer = strike.timer + dt
            if strike.timer >= STRIKE_FRAME_TIME then
                strike.timer = strike.timer - STRIKE_FRAME_TIME
                strike.frame = strike.frame + 1
                if strike.frame > #STRIKE_FRAMES then
                    f.strike = nil
                else
                    local fr = STRIKE_FRAMES[strike.frame]
                    strike.img = GetMenuTexture(fr.name)
                    strike.ox, strike.oy = fr.ox, fr.oy
                end
            end
        end
    end
end

-- Enter mid-sliding (spamming is fine), plays the strike/dodge/MISS sequence
function SANS.ResolveFightAttempt()
    local f = SANS.fight
    if f.state ~= "sliding" then return end

    -- target bar retracts back to 0 from wherever it was interrupted, instead of vanishing instantly
    if f.target then
        f.target.retractFrom = f.target.scaleX
        f.target.retractTimer = 0
    end
    f.state = "striking"

    local legs = SANS.animations.legs
    local fr = STRIKE_FRAMES[1]
    f.strike = {
        img = GetMenuTexture(fr.name),
        x = legs.x,
        y = legs.y - 96,
        ox = fr.ox,
        oy = fr.oy,
        frame = 1,
        timer = 0,
    }
    SANS.PlaySound("PlayerFight", 1)

    SANS.StartSansDodge()
end

-- abandons an in-progress attempt, e.g. backing out with cancel while still on the Fight substate
function SANS.CancelFightMinigame()
    ClearFightVisuals()
    SANS.fight.state = nil

    -- re-shows the heart, StartFightMinigame hid it and only FinishFightMinigame used to bring it back
    local heart = SANS.images.PlayerHeart
    if heart then heart.visible = true end
end

-- sans's dodge, state 0 = idle/not dodging
function SANS.StartSansDodge()
    local legs = SANS.animations.legs
    SANS.dodge = {
        state = 1,
        timer = 0,
        originX = legs.x,
        missShown = false,
    }
end

function SANS.UpdateSansDodge(dt)
    local d = SANS.dodge
    if not d then return end
    local legs = SANS.animations.legs

    d.timer = d.timer + dt

    if d.state == 1 then
        legs.x = d.originX - math.sin(math.rad(d.timer * 225)) * DODGE_DISTANCE
        if d.timer >= DODGE_OUT_TIME then
            legs.x = d.originX - DODGE_DISTANCE
            d.state = 2
            d.timer = 0
        end
    elseif d.state == 2 then
        if not d.missShown and d.timer >= MISS_TEXT_DELAY then
            d.missShown = true
            d.missTimer = MISS_DISPLAY_TIME
        end
        if d.timer >= DODGE_HOLD_TIME then
            d.state = 3
            d.timer = 0
        end
    elseif d.state == 3 then
        legs.x = d.originX - math.cos(math.rad(d.timer * 225)) * DODGE_DISTANCE
        if d.timer >= DODGE_BACK_TIME then
            legs.x = d.originX
            d.state = 0
            SANS.hitAttempts = SANS.hitAttempts + 1
            SANS.dodge = nil

            ClearFightVisuals()
            SANS.FinishFightMinigame()
        end
    end

    if d and d.missShown and d.missTimer then
        d.missTimer = d.missTimer - dt
        if d.missTimer <= 0 then
            d.missShown = false
            d.missTimer = nil
        end
    end
end

function SANS.FinishFightMinigame()
    SANS.fight.state = nil
    SANS.MENU.substate = nil
    local heart = SANS.images.PlayerHeart
    if heart then heart.visible = true end

    -- RunNextAttack only fires once dialogue for this hit count is dismissed, or immediately if there's none
    SANS.dialogue.PlayForHits(SANS.hitAttempts, function()
        SANS.attackrunner.RunNextAttack()
    end)
end

-- fixed draw order: Target on bottom, TargetChoice above it, Strike on top, MISS text last
function SANS.DrawFightMinigame()
    local f = SANS.fight
    love.graphics.setColor(1, 1, 1, 1)

    if f.target then
        love.graphics.draw(f.target.img, f.target.x, f.target.y, 0, f.target.scaleX, 1)
    end
    if f.marker then
        love.graphics.draw(f.marker.img, f.marker.x, f.marker.y)
    end
    if f.strike then
        love.graphics.draw(f.strike.img, f.strike.x, f.strike.y, 0, STRIKE_SCALE, STRIKE_SCALE, f.strike.ox, f.strike.oy)
    end

    local d = SANS.dodge
    if d and d.missShown then
        love.graphics.setColor(75 / 255, 75 / 255, 75 / 255, 1)
        SANS.DrawText("DamageFont", "MISS", 272, 50, 1, 1, 1)
        love.graphics.setColor(1, 1, 1, 1)
    end
end
