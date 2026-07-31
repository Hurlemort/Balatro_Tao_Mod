-- Sans's between-attack dialogue - decoupled from the attack csv system on purpose, triggers off hitAttempts changing, never touches a .csv.
SANS.dialogue = SANS.dialogue or {}

-- chars that don't make a blip sound when the typewriter reveals them
SANS.SILENT_CHARS = SANS.SILENT_CHARS or {}
for _, c in ipairs({ " ", "\t", "\n","\"", "-", "_", "(", ")", ":", ";" }) do
    SANS.SILENT_CHARS[c] = true
end

function SANS.IsSilentChar(c)
    return SANS.SILENT_CHARS[c] == true
end

-- colour tags dialogue text can use - add new ones here, DrawText (hooks.lua) just reads whatever colour the range carries
SANS.DIALOGUE_TAG_COLORS = {
    red = { 1, 0, 0, 1 },
    orange = { 1, 0.5, 0, 1 },
}

-- strips <red>...</red>/<orange>...</orange> tags out of dialogue text and returns which char ranges should draw which colour
function SANS.ParseColorTags(text)
    local plainParts = {}
    local ranges = {}
    local plainLen = 0
    local i, len = 1, #text

    while i <= len do
        -- find whichever known tag appears first (in case a string ever mixes colours)
        local tagStart, tagEnd, tagName
        for name in pairs(SANS.DIALOGUE_TAG_COLORS) do
            local s, e = text:find("<" .. name .. ">", i, true)
            if s and (not tagStart or s < tagStart) then
                tagStart, tagEnd, tagName = s, e, name
            end
        end

        if not tagStart then
            local chunk = text:sub(i)
            table.insert(plainParts, chunk)
            plainLen = plainLen + #chunk
            break
        end

        local before = text:sub(i, tagStart - 1)
        table.insert(plainParts, before)
        plainLen = plainLen + #before

        local closeStart, closeEnd = text:find("</" .. tagName .. ">", tagEnd + 1, true)
        if not closeStart then
            -- malformed/unclosed tag: treat the rest as plain text, ignore the stray marker
            local rest = text:sub(tagEnd + 1)
            table.insert(plainParts, rest)
            plainLen = plainLen + #rest
            break
        end

        local inner = text:sub(tagEnd + 1, closeStart - 1)
        table.insert(plainParts, inner)
        table.insert(ranges, { from = plainLen + 1, to = plainLen + #inner, color = SANS.DIALOGUE_TAG_COLORS[tagName] })
        plainLen = plainLen + #inner

        i = closeEnd + 1
    end

    return table.concat(plainParts), ranges
end


-- Dialogue data: keyed by hitAttempts, each entry is a list of {text, pose} bubbles
SANS.dialogue.blocks = {
    intro = {
        before = {
            { text = "ready?" },
        },
        after = {
            { text = "here we go." },
        },
    },

    [1] = {
        { text = "what?\nyou think i'm just\ngonna stand there\nand take it?", pose = { head = "Wink", torso = "Shrug" } },
    },
    [2] = {
        { text = "our reports showed\na massive anomaly\nin the timespace continuum.", pose = { head = "Default", torso = "Default" } },
        { text = "timelines jumping\nleft and right,\nstopping and\nstarting...", pose = { head = "Default", torso = "Default" } },
    },
    [3] = {
        { text = "until suddenly,\neverything ends.", pose = { head = "ClosedEyes", torso = "Default" } },
    },
    [4] = {
        { text = "heh heh heh...", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "that's your fault,\nisn't it?", pose = { head = "NoEyes", torso = "Default" } },
    },
    [5] = {
        { text = "you can't understand\nhow this feels.", pose = { head = "LookLeft", torso = "Default" } },
    },
    [6] = {
        { text = "knowing that one\nday, without any\nwarning...", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "it's all going to\nbe reset.", pose = { head = "Tired2", torso = "Default" } },
    },
    [7] = {
        { text = "look.\ni gave up trying\nto go back a long\ntime ago.", pose = { head = "Tired2", torso = "Shrug" } },
    },
    [8] = {
        { text = "and getting to the\nsurface doesn't\nreally appeal\nanymore, either.", pose = { head = "ClosedEyes", torso = "Shrug" } },
    },
    [9] = {
        { text = "cause even if we\ndo...", pose = { head = "ClosedEyes", torso = "Shrug" } },
        { text = "we'll just end up\nright back here,\nwithout any memory\nof it, right?", pose = { head = "NoEyes", torso = "Shrug" } },
    },
    [10] = {
        { text = "to be blunt...", pose = { head = "LookLeft", torso = "Shrug" } },
        { text = "it makes it kind\nof hard to give\nit my all.", pose = { head = "ClosedEyes", torso = "Shrug" } },
    },
    [11] = {
        { text = "... or is that just\na poor excuse for\nbeing lazy...?", pose = { head = "LookLeft", torso = "Shrug" } },
        { text = "hell if i know.", pose = { head = "Wink", torso = "Shrug" } },
    },
    [12] = {
        { text = "all i know is...\nseeing what comes\nnext...", pose = { head = "ClosedEyes", torso = "Shrug" } },
        { text = "i can't afford not\nto care anymore.", pose = { head = "Tired2", torso = "Shrug" } },
    },
    [13] = {
        -- sweat2 kicks in here and stays till attack 20
        { text = "ugh...\nthat being said...", pose = { head = "Tired2", torso = "Default", sweat = 2 } },
        { text = "you, uh, really\nlike swinging that\nthing around,\nhuh?", pose = { head = "LookLeft", torso = "Default" } },
        { text = "...", pose = { head = "Default", torso = "Default" } },
        { text = "listen.", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "i know you didn't\nanswer me before,\nbut...", pose = { head = "ClosedEyes", torso = "Default" } },
        -- no mercy-route line here yet, we don't track spare attempts
        { text = "somewhere in\nthere.\ni can feel it.", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "there's a glimmer\nof a good person\ninside of you.", pose = { head = "Default", torso = "Default" } },
        { text = "the memory of\nsomeone who once\nwanted to do the\nright thing.", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "someone who, in\nanother time, might have even\nbeen...", pose = { head = "LookLeft", torso = "Default" } },
        { text = "a friend?", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "c'mon, buddy.", pose = { head = "Wink", torso = "Default" } },
        { text = "do you remember\nme?", pose = { head = "Default", torso = "Default" } },
        { text = "please, if you're\nlistening...", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "let's forget all\nthis, ok?", pose = { head = "Tired2", torso = "Default" } },
        { text = "just lay down\nyour weapon, and...", pose = { head = "Wink", torso = "Default" } },
        { text = "well, my job\nwill be a lot\neasier.", pose = { head = "ClosedEyes", torso = "Default" } },
    },
    [14] = {
        { text = "welp, it was\nworth a shot.", pose = { head = "Wink", torso = "Shrug" } },
        { text = "guess you like\ndoing things the\nhard way, huh?", pose = { head = "NoEyes", torso = "Shrug" } },
    },
    [15] = {
        { text = "sounds strange, but\nbefore all this i\nwas secretly hoping\nwe could be friends.", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "i always thought the\nanomaly was doing\nthis cause they\nwere unhappy.", pose = { head = "LookLeft", torso = "Default" } },
        { text = "and when they got\nwhat they wanted,\nthey would stop\nall this.", pose = { head = "LookLeft", torso = "Default" } },
    },
    [16] = {
        { text = "and maybe all they\nneeded was...\ni dunno.", pose = { head = "Wink", torso = "Default" } },
        { text = "some good food,\nsome bad laughs,\nsome nice friends.", pose = { head = "Wink", torso = "Shrug" } },
    },
    [17] = {
        { text = "but that's\nridiculous,\nright?", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "yeah, you're the\ntype of person\nwho won't EVER\nbe happy.", pose = { head = "NoEyes", torso = "Default" } },
    },
    [18] = {
        { text = "you'll keep\nconsuming timelines\nover and over,\nuntil...", pose = { head = "NoEyes", torso = "Default" } },
        { text = "well.", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "hey.", pose = { head = "ClosedEyes", torso = "Shrug" } },
        { text = "take it from me,\nkid.", pose = { head = "Wink", torso = "Shrug" } },
        { text = "someday...", pose = { head = "Wink", torso = "Shrug" } },
        { text = "you gotta learn\nwhen to QUIT.", pose = { head = "Wink", torso = "Shrug" } },
    },
    [19] = {
        { text = "and that day's\nTODAY.", pose = { head = "Wink", torso = "Default" } },
    },
    [20] = {
        -- "[sweat1 from this point onwards]" - sweat level drops from 2 back to 1 here.
        { text = "cause...\ny'see..", pose = { head = "ClosedEyes", torso = "Default", sweat = 1 } },
        { text = "all this fighting\nis really tiring\nme out.", pose = { head = "LookLeft", torso = "Default" } },
    },
    [21] = {
        { text = "and if you keep\npushing me...", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "then i'll be\nforced to use my\n<red>special attack</red>.", pose = { head = "Wink", torso = "Default" } },
    },
    [22] = {
        -- "[sweat2 from this point onwards]" - back up to sweat level 2.
        { text = "yeah, my <red>special\nattack</red>.\nsound familiar?", pose = { head = "Wink", torso = "Default", sweat = 2 } },
        { text = "well, get ready.\ncause after the\nnext move, i'm\ngoing to <red>use it</red>.", pose = { head = "LookLeft", torso = "Default" } },
        { text = "so, if you don't\nwanna see it, now\nwould be a good\ntime to die.", pose = { head = "Wink", torso = "Default" } },
    },
    [23] = {
        -- "[no sweat for final attack]" - sweat level back to 0.
        { text = "well, here goes\nnothing...", pose = { head = "ClosedEyes", torso = "Default", sweat = 0 } },
        { text = "are you ready?", pose = { head = "Wink", torso = "Default" } },
        { text = "survive THIS, and\ni'll show you my\n<red>special attack</red>!", pose = { head = "NoEyes", torso = "Default" } },
    },

    -- plays when the player actually spares Sans while he's spareable (hits==13) - see SANS.StartSpareSequence below
    spareEnding = {
        { text = "Oh...", pose = { head = "Wink", torso = "Default", sweat = 0 } },
        { text = "I never thought\nyou'd actually\nspare me.", pose = { head = "Default", torso = "Default" } },
        { text = "Especially during\nyour precious\n<red>balatro</red> run.", pose = { head = "Wink", torso = "Shrug" } },
        { text = "Maybe in another\n<orange>timeline</orange>, it\nwould've been\ndifferent.", pose = { head = "ClosedEyes", torso = "Default" } },
        { text = "Who knows ?", pose = { head = "NoEyes", torso = "Default" } },
    },
}


-- Bubble sequencer --------------------------------------------------------------------------
SANS.dialogue.active = nil -- { bubbles, index, onComplete }

-- head/torso reset to Default every bubble unless the pose says otherwise, sweat is the one thing that sticks around between bubbles
local function ApplyPose(pose)
    if not pose then return end
    SANS.attackloader.SansHead(pose.head or "Default")
    SANS.attackloader.SansTorso(pose.torso or "Default")
    if pose.anim ~= nil then SANS.attackloader.SansAnimation(pose.anim) end
    if pose.body then SANS.attackloader.SansBody(pose.body) end
    if pose.sweat ~= nil then SANS.attackloader.SansSweat(pose.sweat) end
end

local function ShowBubble(bubble)
    ApplyPose(bubble.pose)
    SANS.attackloader.SansText(bubble.text) -- SansText handles the typewriter/blips/bubble draw and strips any "<red>" tags itself
end

-- plays bubbles one at a time till Enter dismisses the last one, empty/nil block just skips straight to onComplete
function SANS.dialogue.Play(bubbles, onComplete)
    if not bubbles or #bubbles == 0 then
        if onComplete then onComplete() end
        return
    end

    SANS.dialogue.active = { bubbles = bubbles, index = 1, onComplete = onComplete }
    ShowBubble(bubbles[1])
end

-- first Enter fast-forwards the typewriter, next one advances to the following bubble (or closes the block)
function SANS.dialogue.HandleEnter()
    local active = SANS.dialogue.active
    if not active then return false end

    local bubble = active.bubbles[active.index]
    if SANS.animations.textRevealed < #SANS.animations.text then
        SANS.animations.textRevealed = #SANS.animations.text
        return true
    end

    active.index = active.index + 1
    local nextBubble = active.bubbles[active.index]
    if nextBubble then
        ShowBubble(nextBubble)
    else
        SANS.animations.text = nil
        SANS.animations.textRevealed = 0
        SANS.animations.textColorRanges = nil
        SANS.dialogue.active = nil

        local onComplete = active.onComplete
        if onComplete then onComplete() end
    end
    return true
end

-- called from the fight minigame with the fresh hitAttempts, decides if dialogue plays before the next attack - 13 also swaps to the chokedup music
function SANS.dialogue.PlayForHits(hits, onComplete)
    if hits == 13 then
        SANS.PlayMusic("mus_chokedup")
    end
    SANS.dialogue.Play(SANS.dialogue.blocks[hits], onComplete)
end


-- Intro sequence: sans_intro.csv untouched, just wrapped with a "ready?"/"here we go." bubble
SANS.dialogue.pendingAfterAttack = nil

-- holds EndAttack's menu/music-start off until "here we go." actually gets dismissed
SANS.dialogue.deferEndAttackEntry = nil

-- polls for the watched attack finishing instead of hooking straight into attackrunner/attackloader
function SANS.dialogue.WatchForAttackEnd(callback)
    SANS.dialogue.pendingAfterAttack = callback
end

-- Called every fixed tick (see hooks.lua's Game:update).
function SANS.dialogue.Update(dt)
    if SANS.dialogue.introDelayTimer then
        SANS.dialogue.introDelayTimer = SANS.dialogue.introDelayTimer - dt
        if SANS.dialogue.introDelayTimer <= 0 then
            SANS.dialogue.introDelayTimer = nil
            SANS.dialogue.StartIntroDialogue()
        end
        return
    end

    if SANS.dialogue.pendingAfterAttack and not SANS.attackrunner.active then
        local callback = SANS.dialogue.pendingAfterAttack
        SANS.dialogue.pendingAfterAttack = nil
        callback()
    end
end

-- BeginFight runs straight into this - a beat of silence before Sans actually starts talking, so the fight doesn't
-- slam directly from the intro cutscene/toggle into dialogue
function SANS.dialogue.PlayIntro()
    SANS.dialogue.introDelayTimer = 0.5 -- was 1s, halved per explicit request
end

-- "ready?" -> sans_intro -> "here we go." -> then we open the menu ourselves
function SANS.dialogue.StartIntroDialogue()
    SANS.dialogue.Play(SANS.dialogue.blocks.intro.before, function()
        SANS.dialogue.deferEndAttackEntry = true
        SANS.attackrunner.StartAttack("sans_intro")
        SANS.dialogue.WatchForAttackEnd(function()
            SANS.dialogue.Play(SANS.dialogue.blocks.intro.after, function()
                SANS.dialogue.deferEndAttackEntry = false
                SANS.MENU.state = true
                SANS.MENU.flavorText = SANS.ComputeFlavorText() -- see attackloader.lua's EndAttack - this mirrors the same freeze-on-menu-open for the deferred-entry path
                SANS.SpawnMenuBonesForHits(SANS.hitAttempts) -- see menu.lua's MenuBones section - same mirroring
                if not SANS.attackrunner.musicStarted then
                    SANS.attackrunner.musicStarted = true
                    SANS.PlayMusic("mus_zz_megalovania")
                end
                SANS.UpdateHighlight(SANS.MENU.icons.current_highlight_index or 1)
            end)
        end)
    end)
end

-- Spare ending: dialogue.spareEnding -> spare_ending.ogv -> 3-page textbox -> fade to black -> parable_ending.ogv (full native res, bypasses our canvas)
SANS.spareSequence = SANS.spareSequence or { active = false, phase = nil, video = nil }

-- each page = table of paragraphs, plain "\n" is just wrap-continuation, new table element = new paragraph (see BuildPageDisplay)
SANS.spareSequence.textPages = {
    { "Just kidding lmao", "That's crazy you genuienly\ndecided to spare him,\nknowing perfectly well that\nyou will lose and restart." },
    { "You know what...", "I may have something for\nyou..." },
    { "Hmm...", "Let me see..." },
}

local SPARE_TEXT_PADDING = 24  -- not a source value, just enough that the text doesn't stick to the screen edges
local SPARE_TEXT_SCALE = 2     -- back down to the mod's usual 2x per explicit request (was bumped to 3x earlier)
local SPARE_LINE_WAIT = 0.3    -- not a source value - pause before a new PARAGRAPH starts typing (not every \n anymore)
local SPARE_FADE_TIME = 0.6    -- not a source value, a guess at a reasonable fade-to-black length

-- flattens a page's paragraphs into one string + which "\n" positions are real paragraph breaks vs plain wrap
local function BuildPageDisplay(paragraphs)
    local parts, breaks, len = {}, {}, 0
    for i, para in ipairs(paragraphs) do
        table.insert(parts, para)
        len = len + #para
        if i < #paragraphs then
            table.insert(parts, "\n")
            len = len + 1
            breaks[len] = true
        end
    end
    paragraphs.display = table.concat(parts)
    paragraphs.breaks = breaks
end

for _, page in ipairs(SANS.spareSequence.textPages) do
    BuildPageDisplay(page)
end

-- Draws `video`'s current frame into a small stable canvas cached on `state[key .. "_canvas_cache"]`,
-- only re-sampling the video's texture when its own reported timeline actually crosses into a new
-- source frame (tracked via video:tell() against source_fps) -- redrawing straight from the raw Video
-- object every render frame touches a texture that LOVE's background decode thread updates on its own
-- schedule, far less often than a high-refresh-rate render loop calls draw. Same fix as Tao's Angry
-- Birds Joker video (see Tao/globals.lua's identical draw_angry_birds_canvas), applied here to Sans's
-- three cutscene videos. Returns the canvas to draw in place of the raw video (falls back to the raw
-- video if given a nil video, so callers can do `love.graphics.draw(GetStableVideoCanvas(...) or video, ...)`).
function SANS.GetStableVideoCanvas(state, key, video, source_fps)
    if not video then return nil end
    local vw, vh = video:getDimensions()
    local cache_key = key .. "_canvas_cache"
    local cache = state[cache_key]
    if not cache or cache.w ~= vw or cache.h ~= vh then
        cache = { canvas = love.graphics.newCanvas(vw, vh), w = vw, h = vh, last_frame_idx = -1 }
        state[cache_key] = cache
    end

    local frame_idx = math.floor(video:tell() * source_fps)
    if cache.last_frame_idx ~= frame_idx then
        cache.last_frame_idx = frame_idx
        love.graphics.push('all')
        love.graphics.setCanvas(cache.canvas)
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(video, 0, 0)
        love.graphics.pop()
    end
    return cache.canvas
end

-- reads a .ogv out of Sans/resource and hands back a playable love.graphics.Video
local function LoadOgvFromResource(filename)
    local base = SANS.path or ""
    local last = base:sub(-1)
    if last ~= "/" and last ~= "\\" then base = base .. "/" end

    -- newVideo can't read a raw path outside love.filesystem's sandbox, so stash the real bytes in the save dir first
    return pcall(function()
        local fileData = NFS.newFileData(base .. "resources/" .. filename)
        local tempName = "sans_" .. filename
        local writeOk, writeErr = love.filesystem.write(tempName, fileData:getString())
        if not writeOk then error(writeErr) end
        return love.graphics.newVideo(tempName)
    end)
end

function SANS.StartSpareSequence()
    if SANS.spareSequence.active then return end
    SANS.spareSequence.active = true
    SANS.spareSequence.phase = "dialogue"
    SANS.StopMusic()

    SANS.dialogue.Play(SANS.dialogue.blocks.spareEnding, function()
        SANS.spareSequence.phase = "video"

        local ok, result = LoadOgvFromResource("spare_ending.ogv")
        if ok then
            SANS.spareSequence.video = result
            result:play()
        else
            print("[SANS] spare ending video failed to load: " .. tostring(result))
            -- skip the broken video, still show the text pages rather than getting stuck
            SANS.spareSequence.phase = "text"
            SANS.spareSequence.textIndex = 1
            SANS.spareSequence.textRevealed = 0
        end
    end)
end

-- Enter's handler for the "text" phase - same 1st-press-reveals/2nd-press-advances convention as every other
-- typewriter in this mod (SANS.dialogue.HandleEnter, SANS.AdvanceBattleText)
function SANS.AdvanceSpareText()
    local s = SANS.spareSequence
    local page = s.textPages[s.textIndex]
    if not page then return end

    if s.textRevealed < #page.display then
        s.textRevealed = #page.display
        return
    end

    s.textIndex = s.textIndex + 1
    if s.textPages[s.textIndex] then
        s.textRevealed = 0
        s.textLineWait = 0
    else
        -- last page dismissed: fade out, then the final full-screen video
        s.phase = "fade"
        s.fadeTimer = 0
        s.wrongOneRevealed = 0
    end
end

-- second-thoughts text typed out over the fade to black - per explicit request, not a source line
local WRONG_ONE_TEXT = "NO WAIT THAT'S THE WRONG ONE"

-- called every fixed tick (see hooks.lua's Game:update) - no-op unless the sequence is actually running
function SANS.UpdateSpareSequence(dt)
    local s = SANS.spareSequence
    if not s.active then return end

    if s.phase == "video" then
        if s.video and not s.video:isPlaying() then
            s.phase = "text"
            s.textIndex = 1
            s.textRevealed = 0
            s.textLineWait = 0
        end
    elseif s.phase == "text" then
        -- same per-char typewriter cadence as SANS.UpdateBattleText, but only pauses at a real paragraph break
        -- (page.breaks) - a plain word-wrap "\n" inside one paragraph reveals immediately, no pause
        local page = s.textPages[s.textIndex]
        if page and s.textRevealed < #page.display then
            if s.textLineWait and s.textLineWait > 0 then
                s.textLineWait = s.textLineWait - dt
            else
                s.textRevealed = s.textRevealed + 1
                local c = page.display:sub(s.textRevealed, s.textRevealed)
                if c == "\n" and page.breaks[s.textRevealed] then
                    s.textLineWait = SPARE_LINE_WAIT -- holds here before the next paragraph starts typing
                end
                if not SANS.IsSilentChar(c) then
                    SANS.PlaySound("BattleText", 1)
                end
            end
        end
    elseif s.phase == "fade" then
        s.fadeTimer = (s.fadeTimer or 0) + dt
        local t = math.min(s.fadeTimer / SPARE_FADE_TIME, 1)

        -- reveal tied directly to fade progress (not its own timer) so it always finishes exactly as the screen goes
        -- black - volume drops along with it (1 - t), the same falloff the black overlay gives the text's contrast
        local targetRevealed = math.floor(t * #WRONG_ONE_TEXT)
        if targetRevealed > (s.wrongOneRevealed or 0) then
            for i = (s.wrongOneRevealed or 0) + 1, targetRevealed do
                local c = WRONG_ONE_TEXT:sub(i, i)
                if not SANS.IsSilentChar(c) then
                    SANS.PlaySound("BattleText", 1, 1 - t)
                end
            end
            s.wrongOneRevealed = targetRevealed
        end

        if s.fadeTimer >= SPARE_FADE_TIME then
            s.phase = "finalVideo"
            local ok, result = LoadOgvFromResource("parable_ending.ogv")
            if ok then
                s.finalVideo = result
                result:play()
            else
                print("[SANS] parable ending video failed to load: " .. tostring(result))
                SANS.RestartRunAfterSpareEnding() -- nothing to wait for, don't get stuck on a black screen forever
            end
        end
    elseif s.phase == "finalVideo" then
        if s.finalVideo and not s.finalVideo:isPlaying() then
            SANS.RestartRunAfterSpareEnding()
        end
    end
end

-- once the last video ends, hand back to vanilla and do exactly what the real "Restart Run" button does
function SANS.RestartRunAfterSpareEnding()
    SANS.spareSequence.active = false
    SANS.spareSequence.phase = nil
    SANS.spareSequence.video = nil
    SANS.spareSequence.finalVideo = nil
    SANS.state = false
    G.FUNCS.start_run(nil)
    check_for_unlock({ type = "ach_tao_spare_sans" })
end

-- called once the sequence leaves "dialogue" phase - video/text/fade replace the whole screen (finalVideo's separate, bypasses the canvas)
function SANS.DrawSpareSequence()
    local s = SANS.spareSequence
    local phase = s.phase

    if phase == "video" then
        if s.video then
            love.graphics.setColor(1, 1, 1, 1)
            local vw, vh = s.video:getDimensions()
            local scale = math.min(640 / vw, 480 / vh)
            local x, y = (640 - vw * scale) / 2, (480 - vh * scale) / 2
            local canvas = SANS.GetStableVideoCanvas(s, "video", s.video, 30)
            love.graphics.draw(canvas or s.video, x, y, 0, scale, scale)
        end
    elseif phase == "text" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, 640, 480)

        local page = s.textPages[s.textIndex]
        if page then
            love.graphics.setColor(0, 0, 0, 1)
            SANS.DrawText("DefaultFont", page.display:sub(1, s.textRevealed), SPARE_TEXT_PADDING, SPARE_TEXT_PADDING, SPARE_TEXT_SCALE, SPARE_TEXT_SCALE, SPARE_TEXT_SCALE, nil, page.breaks)
            love.graphics.setColor(1, 1, 1, 1)
        end
    elseif phase == "fade" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, 640, 480)

        love.graphics.setColor(0, 0, 0, 1)
        SANS.DrawText("DefaultFont", WRONG_ONE_TEXT:sub(1, s.wrongOneRevealed or 0), SPARE_TEXT_PADDING, SPARE_TEXT_PADDING, SPARE_TEXT_SCALE, SPARE_TEXT_SCALE, SPARE_TEXT_SCALE)

        -- drawn last so it darkens the text too - contrast fades out with the background instead of staying legible
        local t = math.min((s.fadeTimer or 0) / SPARE_FADE_TIME, 1)
        love.graphics.setColor(0, 0, 0, t)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- the final video, drawn OUTSIDE the canvas at real native resolution, per explicit request
function SANS.DrawFinalSpareVideo()
    love.graphics.setCanvas()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)

    local video = SANS.spareSequence.finalVideo
    if video then
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local vw, vh = video:getDimensions()
        local scale = math.min(w / vw, h / vh)
        local x, y = (w - vw * scale) / 2, (h - vh * scale) / 2
        local canvas = SANS.GetStableVideoCanvas(SANS.spareSequence, "finalVideo", video, 30)
        love.graphics.draw(canvas or video, x, y, 0, scale, scale)
    end
end

-- Win sequence: fade to white -> 3-page text -> fade to black -> fight_ending.ogv looping w/ spaceship.ogg, Enter after 1 loop calls WinFight
SANS.winSequence = SANS.winSequence or { active = false, phase = nil, video = nil, loops = 0 }

-- same paragraph-array convention as the spare ending's textPages above (each table element is a paragraph, a plain
-- "\n" inside one is just a word-wrap continuation line)
SANS.winSequence.textPages = {
    { "Dont worry, you beat him.", "No dirty tricks from now one." },
    { "Here,", "Relax a little before you\nstart Balatroing again." },
    { "I got some nice calming music for you.", "Oh! I even found the perfect\nvideo to fit the music." },
}
for _, page in ipairs(SANS.winSequence.textPages) do
    BuildPageDisplay(page)
end

local WIN_FADE_TIME = 0.6 -- not a source value, matches SPARE_FADE_TIME's guess

function SANS.StartWinSequence()
    if SANS.winSequence.active then return end
    SANS.winSequence.active = true
    SANS.winSequence.phase = "fadeIn"
    SANS.winSequence.fadeTimer = 0
    SANS.winSequence.textIndex = 1
    SANS.winSequence.textRevealed = 0
    SANS.winSequence.textLineWait = 0
    SANS.winSequence.loops = 0
    SANS.winSequence.video = nil
    SANS.StopMusic()
end

-- Enter's handler for the "text" phase, same convention as SANS.AdvanceSpareText/dialogue.HandleEnter
function SANS.AdvanceWinText()
    local s = SANS.winSequence
    local page = s.textPages[s.textIndex]
    if not page then return end

    if s.textRevealed < #page.display then
        s.textRevealed = #page.display
        return
    end

    s.textIndex = s.textIndex + 1
    if s.textPages[s.textIndex] then
        s.textRevealed = 0
        s.textLineWait = 0
    else
        s.phase = "fadeOut"
        s.fadeTimer = 0
    end
end

-- Enter's handler once the video's up - only reachable after the first full loop, see hooks.lua's Keypressed
function SANS.AdvanceWinSequence()
    SANS.winSequence.active = false
    SANS.winSequence.phase = nil
    SANS.winSequence.video = nil
    SANS.WinFight()
end

-- called every fixed tick (see hooks.lua's Game:update) - no-op unless the sequence is actually running
function SANS.UpdateWinSequence(dt)
    local s = SANS.winSequence
    if not s.active then return end

    if s.phase == "fadeIn" then
        s.fadeTimer = (s.fadeTimer or 0) + dt
        if s.fadeTimer >= WIN_FADE_TIME then
            s.phase = "text"
        end
    elseif s.phase == "text" then
        -- only pauses at a real paragraph break (page.breaks) - a plain word-wrap "\n" reveals with no pause
        local page = s.textPages[s.textIndex]
        if page and s.textRevealed < #page.display then
            if s.textLineWait and s.textLineWait > 0 then
                s.textLineWait = s.textLineWait - dt
            else
                s.textRevealed = s.textRevealed + 1
                local c = page.display:sub(s.textRevealed, s.textRevealed)
                if c == "\n" and page.breaks[s.textRevealed] then
                    s.textLineWait = SPARE_LINE_WAIT
                end
                if not SANS.IsSilentChar(c) then
                    SANS.PlaySound("BattleText", 1)
                end
            end
        end
    elseif s.phase == "fadeOut" then
        s.fadeTimer = (s.fadeTimer or 0) + dt
        if s.fadeTimer >= WIN_FADE_TIME then
            s.phase = "video"
            local ok, result = LoadOgvFromResource("fight_ending.ogv")
            if ok then
                s.video = result
                local src = result:getSource()
                if src then src:setVolume(0) end -- kept (LÖVE needs a track present to play at all) but silenced - spaceship.ogg plays instead
                result:play()
                SANS.PlayMusic("spaceship")
            else
                print("[SANS] fight ending video failed to load: " .. tostring(result))
            end
        end
    elseif s.phase == "video" then
        if s.video and not s.video:isPlaying() then
            s.loops = s.loops + 1
            s.video:seek(0)
            s.video:play()
        end
    end
end

function SANS.DrawWinSequence()
    local s = SANS.winSequence
    local phase = s.phase

    if phase == "fadeIn" then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        local t = math.min((s.fadeTimer or 0) / WIN_FADE_TIME, 1)
        love.graphics.setColor(1, 1, 1, t)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1, 1, 1, 1)
    elseif phase == "text" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, 640, 480)

        local page = s.textPages[s.textIndex]
        if page then
            love.graphics.setColor(0, 0, 0, 1)
            SANS.DrawText("DefaultFont", page.display:sub(1, s.textRevealed), SPARE_TEXT_PADDING, SPARE_TEXT_PADDING, SPARE_TEXT_SCALE, SPARE_TEXT_SCALE, SPARE_TEXT_SCALE, nil, page.breaks)
            love.graphics.setColor(1, 1, 1, 1)
        end
    elseif phase == "fadeOut" then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        local t = math.min((s.fadeTimer or 0) / WIN_FADE_TIME, 1)
        love.graphics.setColor(0, 0, 0, t)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        love.graphics.setColor(1, 1, 1, 1)
    elseif phase == "video" then
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, 640, 480)
        if s.video then
            love.graphics.setColor(1, 1, 1, 1)
            local vw, vh = s.video:getDimensions()
            local scale = math.min(640 / vw, 480 / vh)
            local x, y = (640 - vw * scale) / 2, (480 - vh * scale) / 2
            local canvas = SANS.GetStableVideoCanvas(s, "video", s.video, 30)
            love.graphics.draw(canvas or s.video, x, y, 0, scale, scale)
        end
    end
end
