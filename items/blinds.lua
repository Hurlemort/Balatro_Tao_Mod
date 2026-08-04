SMODS.Atlas {
    key = "blinds",
    path = "blinds.png",
    px = 34,
    py = 34,
    frames = 21,
    atlas_table = "ANIMATION_ATLAS",
}

SMODS.Blind {
    name = "boss_shark",
    key = "boss_shark",
    atlas = "blinds",
    pos = { x = 0, y = 0 },
    dollars = 6,
    mult = 2,
    discovered = true,
    loc_txt = {
        name = 'The Shark',
        text = {
            "#1# in 7 chance to destroy",
            "any playing card held in hand or played",
            "after hand is played"
        }
    },
    boss = { min = 0 },
    boss_colour = HEX('7aa2e9'),

    -- stringifies the var like vanilla probability jokers do
    loc_vars = function(self, info_queue, blind)
        return { vars = { ''..(G.GAME and G.GAME.probabilities.normal or 1) } }
    end,

    calculate = function(self, blind, context)
        -- context.after fires per hand played; card areas are looped below instead of gating on cardarea
        if context.after and not G.GAME.blind.disabled then

            -- Destroy played cards
            if G.play.cards then
                for i = #G.play.cards, 1, -1 do
                    local playing_card = G.play.cards[i]
                    if pseudorandom("boss_shark") < G.GAME.probabilities.normal / 7 then
                        -- playing_card:start_dissolve()
                        return { remove = not playing_card.ability.eternal }
                    end
                end
            end
            -- Destroy hand cards
            if G.hand.cards then
                for i = #G.hand.cards, 1, -1 do
                    local playing_card = G.hand.cards[i]
                    if pseudorandom("boss_shark") < G.GAME.probabilities.normal / 7 then
                        -- playing_card:start_dissolve()
                        return { remove = not playing_card.ability.eternal }
                    end
                end
            end
        end
    end
}

-- SMODS.Blind {
--     name = "boss_rainbow",
--     key = "boss_rainbow",
--     atlas = "blinds",
--     pos = { x = 0, y = 1 },
--     dollars = 6,
--     mult = 3,
--     discovered = true,
--     loc_txt = {
--         name = 'The Rainbow',
--         text = {
--             "Each click changes",
--             "the game's language",
--         }
--     },
--     boss = { min = 0 },
--     boss_colour = HEX('de4e5c'),
-- }

-- pays an Egg instead of money; the "EGG" reward text comes from the blind.lua patches (sans_patches.toml)
SMODS.Blind {
    name = "boss_tree",
    key = "boss_tree",
    atlas = "blinds",
    pos = { x = 0, y = 1 },
    dollars = 0,
    mult = 2,
    discovered = true,
    loc_txt = {
        name = 'The Tree',
        text = {
            "Pays an {C:attention}Egg{}",
            "instead of money",
        }
    },
    boss = { min = 0 },
    boss_colour = HEX('000000'),

    defeat = function(self)
        local egg = SMODS.create_card({ set = 'Joker', key = 'j_egg', skip_materialize = true })
        egg:add_to_deck()
        G.jokers:emplace(egg) -- emplace ignores the slot limit, so the Egg can overflow
        egg:juice_up(0.3, 0.5)
    end,
}

SMODS.Blind {
    name = "boss_bestspark",
    key = "boss_bestspark",
    atlas = "blinds",
    pos = { x = 0, y = 2 },
    dollars = 6,
    mult = 2,
    discovered = true,
    loc_txt = {
        name = 'BestSpark',
        text = {
            "Explodes every card",
            "in the winning hand",
        }
    },
    boss = { min = 0 },
    boss_colour = HEX('44a338'),

    calculate = function(self, blind, context)
        if context.after and not G.GAME.blind.disabled then
            -- the live scoring parameters hold this hand's score
            local hand_score = SMODS.calculate_round_score and SMODS.calculate_round_score() or 0
            local projected_total = G.GAME.chips + math.floor(hand_score)
            if projected_total >= G.GAME.blind.chips then
                G.GAME.blind.triggered = true
                for i = #G.play.cards, 1, -1 do
                    local playing_card = G.play.cards[i]
                    if playing_card and not playing_card.ability.eternal and not playing_card.destroyed then
                        playing_card.destroyed = true
                        -- shares the dissolve's event so both fire together
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                play_effect("explosion", Tao.funcs.card_screen_pos(playing_card))
                                playing_card:start_dissolve()
                                return true
                            end
                        }))
                    end
                end
            end
        end
    end
}

-- effect lives in the state_events.lua patch (patches.toml) + debuff_hand below on failure
SMODS.Blind {
    name = "boss_math",
    key = "boss_math",
    atlas = "blinds",
    pos = { x = 0, y = 3 },
    dollars = 6,
    mult = 2,
    discovered = true,
    loc_txt = {
        name = 'The Problem',
        text = {
            "Solve a linear equation",
            "before each hand is played",
        }
    },
    boss = { min = 0 },
    boss_colour = HEX('b51f1f'),

    debuff_hand = function(self, cards, hand, handname, check)
        if check then return false end
        if Tao.equation.failed then
            Tao.equation.failed = false
            return true
        end
        return false
    end,
}

Tao.equation = {
    a = 1,
    b = 0,
    c_scaled = 100,
    answer_scaled = 100,
    input = "",
    display = "x = _",
    text = "",
    feedback = "",
    attempts = 0,
    max_attempts = 3,
    active = false,
    answered = false,
    failed = false,
    cursor_on = true,
    blink_timer = 0,
}

-- rounds to nearest int, symmetric around 0
function Tao.funcs.round(n)
    if n >= 0 then return math.floor(n + 0.5) end
    return -math.floor(-n + 0.5)
end

-- turns a hundredths-scaled int back into a trimmed decimal string
function Tao.funcs.format_scaled(scaled)
    local sign = scaled < 0 and "-" or ""
    local abs_scaled = math.abs(scaled)
    local whole = math.floor(abs_scaled / 100)
    local frac = abs_scaled % 100
    if frac == 0 then return sign..whole end
    local frac_str = frac < 10 and ("0"..frac) or tostring(frac)
    frac_str = frac_str:gsub("0$", "")
    return sign..whole.."."..frac_str
end

function Tao.funcs.equation_text(eq)
    local sign = eq.b >= 0 and " + " or " - "
    return eq.a.."x"..sign..math.abs(eq.b).." = "..Tao.funcs.format_scaled(eq.c_scaled)
end

-- rebuilds the "x = ..._" display with the blinking cursor
function Tao.funcs.refresh_equation_display()
    local eq = Tao.equation
    eq.display = "x = "..eq.input..(eq.cursor_on and "_" or " ")
end

-- ticks the blinking cursor, called every frame from Game:update (globals.lua)
function Tao.funcs.update_equation_blink(dt)
    local eq = Tao.equation
    eq.blink_timer = (eq.blink_timer or 0) + dt
    if eq.blink_timer >= 0.5 then
        eq.blink_timer = eq.blink_timer - 0.5
        eq.cursor_on = not eq.cursor_on
        Tao.funcs.refresh_equation_display()
    end
end

function Tao.funcs.generate_equation()
    local eq = Tao.equation

    -- x rolls in tenths then gets scaled to hundredths, a/b stay whole numbers
    local x_tenths = pseudorandom("tao_boss_math_x", -120, 120)
    if x_tenths == 0 then x_tenths = 50 end
    local x_scaled = x_tenths * 10
    local a = pseudorandom("tao_boss_math_a", 2, 9)
    local b = pseudorandom("tao_boss_math_b", -20, 20)

    eq.a = a
    eq.b = b
    eq.c_scaled = a * x_scaled + b * 100
    eq.answer_scaled = x_scaled
    eq.input = ""
    eq.feedback = ""
    eq.text = Tao.funcs.equation_text(eq)
    Tao.funcs.refresh_equation_display()
end

function Tao.funcs.equation_key(key)
    local eq = Tao.equation
    if key == "back" then
        eq.input = eq.input:sub(1, -2)
    elseif key == "neg" then
        if eq.input:sub(1, 1) == "-" then
            eq.input = eq.input:sub(2)
        else
            eq.input = "-"..eq.input
        end
    elseif key == "." then
        -- plain=true: "." is a Lua pattern wildcard otherwise
        if not eq.input:find(".", 1, true) then
            eq.input = eq.input.."."
        end
    else
        local dot_pos = eq.input:find(".", 1, true)
        local decimals_so_far = dot_pos and (#eq.input - dot_pos) or 0
        if decimals_so_far < 1 and #eq.input < 9 then
            eq.input = eq.input..key
        end
    end
    eq.feedback = ""
    Tao.funcs.refresh_equation_display()
end

function Tao.funcs.submit_equation_answer()
    local eq = Tao.equation
    local guess = tonumber(eq.input)
    local guess_scaled = guess and Tao.funcs.round(guess * 100)

    if guess_scaled and guess_scaled == eq.answer_scaled then
        play_sound("tarot2", 1, 0.6)
        eq.answered = true
        G.FUNCS.exit_overlay_menu()
        return
    end

    eq.attempts = eq.attempts + 1
    eq.input = ""
    Tao.funcs.refresh_equation_display()
    play_sound("cancel", 0.9, 0.8)

    if eq.attempts >= eq.max_attempts then
        eq.feedback = "Out of attempts!"
        eq.failed = true
        -- small grace period so "Out of attempts!" is actually readable before the overlay closes
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.8,
            blocking = false,
            blockable = false,
            func = function()
                eq.answered = true
                G.FUNCS.exit_overlay_menu()
                return true
            end
        }))
    else
        local left = eq.max_attempts - eq.attempts
        eq.feedback = "Incorrect! "..left.." attempt"..(left == 1 and "" or "s").." left"
    end
end

-- called every frame from the patched Event in state_events.lua, returning true holds scoring
function Tao.funcs.equation_gate()
    if not (G.GAME and G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind) then return false end
    -- SMODS prefixes the key to "bl_tao_boss_math"
    if G.GAME.blind.config.blind.key ~= "bl_tao_boss_math" then return false end
    if G.GAME.blind.disabled then return false end

    if not Tao.equation.active then
        Tao.funcs.start_equation()
    end
    return not Tao.equation.answered
end

function Tao.funcs.start_equation()
    local eq = Tao.equation
    eq.active = true
    eq.answered = false
    eq.failed = false
    eq.attempts = 0

    Tao.funcs.generate_equation()

    G.FUNCS.overlay_menu{
        definition = create_UIBox_tao_equation(),
        config = { no_esc = false }
    }
    G.OVERLAY_MENU.config.tao_equation = true
end

-- lets ESC reach the pause menu from the equation overlay, then reopens the equation if still unsolved
local tao_vanilla_exit_overlay_menu = G.FUNCS.exit_overlay_menu
G.FUNCS.exit_overlay_menu = function()
    local ov = G.OVERLAY_MENU
    if ov and ov.config and ov.config.tao_equation and not Tao.equation.answered then
        tao_vanilla_exit_overlay_menu()
        G.FUNCS.options()
        G.OVERLAY_MENU.config.tao_return_to_equation = true
        return
    end
    if ov and ov.config and ov.config.tao_return_to_equation and not Tao.equation.answered then
        tao_vanilla_exit_overlay_menu()
        G.FUNCS.overlay_menu{
            definition = create_UIBox_tao_equation(),
            config = { no_esc = false }
        }
        G.OVERLAY_MENU.config.tao_equation = true
        return
    end
    tao_vanilla_exit_overlay_menu()
end

G.FUNCS.tao_equation_key = function(e)
    Tao.funcs.equation_key(e.config.ref_table.key)
end

G.FUNCS.tao_equation_submit = function(e)
    Tao.funcs.submit_equation_answer()
end

function create_UIBox_tao_equation()
    local numpad_rows = {
        { "7", "8", "9" },
        { "4", "5", "6" },
        { "1", "2", "3" },
        { "neg", "0", ".", "back" },
    }
    local numpad_labels = { neg = "+/-", back = "<-" }
    local numpad_colours = { neg = G.C.BLUE, back = G.C.RED }

    local pad_rows = {}
    for _, row in ipairs(numpad_rows) do
        local btns = {}
        for _, key in ipairs(row) do
            btns[#btns + 1] = UIBox_button({
                label = { numpad_labels[key] or key },
                button = "tao_equation_key",
                ref_table = { key = key },
                colour = numpad_colours[key] or G.C.JOKER_GREY,
                col = true,
                minw = 0.9,
                minh = 0.9,
                scale = 0.5,
            })
        end
        pad_rows[#pad_rows + 1] = { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = btns }
    end

    local contents = {
        { n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
            { n = G.UIT.T, config = { text = "SOLVE THE EQUATION", scale = 0.5, colour = G.C.RED, shadow = true } },
        } },
        { n = G.UIT.R, config = { align = "cm", padding = 0.15 }, nodes = {
            { n = G.UIT.T, config = { ref_table = Tao.equation, ref_value = "text", scale = 0.75, colour = G.C.WHITE, shadow = true } },
        } },
        { n = G.UIT.R, config = { align = "cm", padding = 0.1, colour = G.C.BLACK, r = 0.1, minw = 3, minh = 0.7 }, nodes = {
            { n = G.UIT.T, config = { ref_table = Tao.equation, ref_value = "display", scale = 0.6, colour = G.C.WHITE, shadow = true } },
        } },
        { n = G.UIT.R, config = { align = "cm", padding = 0.05 }, nodes = pad_rows },
        { n = G.UIT.R, config = { align = "cm", padding = 0.1, minh = 0.4 }, nodes = {
            { n = G.UIT.T, config = { ref_table = Tao.equation, ref_value = "feedback", scale = 0.4, colour = G.C.RED, shadow = true } },
        } },
        { n = G.UIT.R, config = { align = "cm", padding = 0.1 }, nodes = {
            UIBox_button({ label = { "SUBMIT" }, button = "tao_equation_submit", colour = G.C.GREEN, minw = 3, minh = 0.8 }),
        } },
    }

    return create_UIBox_generic_options({
        no_back = true,
        colour = G.C.BLACK,
        contents = contents,
    })
end

RECORD_RAD_PER_SEC = 0.9 -- radians/sec the screen spins; effect registers in Tao.screen_effects

SMODS.Blind {
    name = "boss_record",
    key = "boss_record",
    atlas = "blinds",
    pos = { x = 0, y = 4 },
    dollars = 6,
    mult = 2,
    discovered = true,
    loc_txt = {
        name = 'Record',
        text = {
            "You spin me right round,",
            "baby, right round",
        }
    },
    boss = { min = 0 },
    boss_colour = HEX('6c3fc9'),
}

Tao.screen_effects.boss_record = {
    is_active = function()
        -- same early-loading guard as the Angry Birds hooks (globals.lua)
        if not G.STAGE or G.STATE == G.STATES.SPLASH then return false end
        return G.GAME and G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind
            and G.GAME.blind.config.blind.key == "bl_tao_boss_record" and not G.GAME.blind.disabled
    end,

    draw = function(canvas)
        local angle = (G.TIMERS and G.TIMERS.REAL or 0) * RECORD_RAD_PER_SEC
        -- blanks the unrotated frame first
        love.graphics.clear(0, 0, 0, 1)
        love.graphics.push()
        love.graphics.setColor(1, 1, 1, 1)
        local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
        love.graphics.translate(cx, cy)
        love.graphics.rotate(angle)
        love.graphics.translate(-cx, -cy)
        love.graphics.draw(canvas, 0, 0)
        love.graphics.pop()
    end,

    -- inverse of draw()'s transform; rotates a raw screen point by -angle around center
    remap_point = function(x, y)
        local angle = (G.TIMERS and G.TIMERS.REAL or 0) * RECORD_RAD_PER_SEC
        local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
        local dx, dy = x - cx, y - cy
        local cos_a, sin_a = math.cos(-angle), math.sin(-angle)
        return dx*cos_a - dy*sin_a + cx, dx*sin_a + dy*cos_a + cy
    end,

    -- is_active/remap_point feed the cursor-remap patch
}

-- real GPU shader on Steamodded's CRT ping-pong pipeline; zero extra per-frame cost when inactive
SMODS.ScreenShader{
    key = "tao_record_spin",
    path = "record_spin.fs",
    order = 1000,
    should_apply = function(self) return Tao.screen_effects.boss_record.is_active() end,
    send_vars = function(self)
        return { angle = (G.TIMERS and G.TIMERS.REAL or 0) * RECORD_RAD_PER_SEC }
    end,
}

-- Sound for record boss blind, "music" has to be in the file name
SMODS.Sound({
    key = "record_music",
    path = "record_music.ogg",
    pitch = 1,
    volume = 1,
    select_music_track = function(self)
        return Tao.screen_effects.boss_record.is_active() and 10 or false
    end,
})

-- actual effect registers below, same Tao.screen_effects pattern as boss_record but with square-shuffling
PUZZLE_SQUARE_SIZE = 180

SMODS.Blind {
    name = "boss_puzzle",
    key = "boss_puzzle",
    atlas = "blinds",
    pos = { x = 0, y = 5 },
    dollars = 6,
    mult = 2,
    discovered = true,
    loc_txt = {
        name = 'The Puzzle',
        text = {
            "Splits the screen into",
            "scrambled squares",
        }
    },
    boss = { min = 0 },
    boss_colour = HEX('12cca1'),
}

Tao.puzzle = {
    perm = nil,       -- perm[screen_cell_index] = source_cell_index (1-based)
    cols = 0,
    rows = 0,
    w = 0, h = 0,      -- screen size the scramble was built for
}

-- (re)builds the scramble if there isn't one yet or the window size changed
function Tao.funcs.ensure_puzzle_scramble()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    if Tao.puzzle.perm and Tao.puzzle.w == w and Tao.puzzle.h == h then return end

    local size = PUZZLE_SQUARE_SIZE
    local cols = math.ceil(w / size)
    local rows = math.ceil(h / size)
    local n = cols * rows

    local perm = {}
    for i = 1, n do perm[i] = i end
    for i = n, 2, -1 do -- Fisher-Yates
        local j = pseudorandom("tao_boss_puzzle_shuffle", 1, i)
        perm[i], perm[j] = perm[j], perm[i]
    end

    Tao.puzzle.perm = perm
    Tao.puzzle.cols = cols
    Tao.puzzle.rows = rows
    Tao.puzzle.w = w
    Tao.puzzle.h = h
end

Tao.screen_effects.boss_puzzle = {
    is_active = function()
        if not G.STAGE or G.STATE == G.STATES.SPLASH then return false end
        local active = G.GAME and G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind
            and G.GAME.blind.config.blind.key == "bl_tao_boss_puzzle" and not G.GAME.blind.disabled
        if active then
            Tao.funcs.ensure_puzzle_scramble()
        else
            Tao.puzzle.perm = nil
        end
        return active
    end,

    -- maps a raw point to its equivalent spot in the source square that's actually displayed there
    remap_point = function(x, y)
        local puzzle = Tao.puzzle
        if not puzzle.perm then return x, y end
        local size = PUZZLE_SQUARE_SIZE
        local dc, dr = math.floor(x / size), math.floor(y / size)
        if dc < 0 or dc >= puzzle.cols or dr < 0 or dr >= puzzle.rows then return x, y end
        local screen_i = dr * puzzle.cols + dc + 1
        local source_i = puzzle.perm[screen_i]
        if not source_i then return x, y end
        local sc, sr = (source_i - 1) % puzzle.cols, math.floor((source_i - 1) / puzzle.cols)
        local offset_x, offset_y = x - dc * size, y - dr * size
        return sc * size + offset_x, sr * size + offset_y
    end,
}

SMODS.ScreenShader{
    key = "tao_puzzle_shuffle",
    path = "puzzle_shuffle.fs",
    order = 1001,
    should_apply = function(self) return Tao.screen_effects.boss_puzzle.is_active() end,
    send_vars = function(self)
        local puzzle = Tao.puzzle
        local perm0 = {}
        for i = 1, #(puzzle.perm or {}) do perm0[i] = puzzle.perm[i] - 1 end
        return {
            perm = { array = perm0 }, -- .array makes send_vars spread it as a number-array
            cols = puzzle.cols,
            rows = puzzle.rows,
            cell_size = PUZZLE_SQUARE_SIZE,
        }
    end,
}

LIGHT_DIAMETER_CARDS = 1.3 -- 1.3 card height so that you can still see cards + descriptions
SMODS.Blind {
    name = "boss_light",
    key = "boss_light",
    atlas = "blinds",
    pos = { x = 0, y = 7 },
    dollars = 6,
    mult = 2,
    discovered = true,
    loc_txt = {
        name = 'The Light',
        text = {
            "DARK, DARKER,",
            "YET DARKER"
        }
    },
    boss = { min = 0 },
    boss_colour = HEX('2b2b3d'),
}

-- nothing moves on screen, so this one needs no cursor remap entry
local function tao_light_is_active()
    if not G.STAGE or G.STATE == G.STATES.SPLASH then return false end
    return G.GAME and G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind
        and G.GAME.blind.config.blind.key == "bl_tao_boss_light" and not G.GAME.blind.disabled
end

SMODS.ScreenShader{
    key = "tao_light_mask",
    path = "light_mask.fs",
    order = 1002,
    should_apply = function(self) return tao_light_is_active() end,
    send_vars = function(self)
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local mx, my = love.mouse.getPosition()
        return {
            light_pos = { mx / w, my / h },
            light_radius = (0.5 * LIGHT_DIAMETER_CARDS * G.CARD_H * G.TILESIZE * G.TILESCALE) / h,
        }
    end,
}

-- actual effect in Tao.funcs.update_dvd_blind, called every frame from Game:update (globals.lua)
SMODS.Blind {
    name = "boss_dvd",
    key = "boss_dvd",
    atlas = "blinds",
    pos = { x = 0, y = 6 },
    dollars = 6,
    mult = 2,
    discovered = true,
    loc_txt = {
        name = 'The DVD',
        text = {
            "OFFICER, THEY ARE",
            "TRYING TO ESCAPE!!"
        }
    },
    boss = { min = 0 },
    boss_colour = HEX('cc4974'),
}

-- hardcoded bounce ranges for boss_dvd
DVD_SPEED_MIN = 3.0        -- game units/sec
DVD_SPEED_MAX = 7.0
DVD_ANGLE_DELTA_DEG = 5   -- every bounce is normal but adds/substracts a random 0-5 degree delta to the angle for randomness

Tao.dvd = {
    active = false,
}

function Tao.funcs.dvd_is_active()
    return G.GAME and G.GAME.blind and G.GAME.blind.config and G.GAME.blind.config.blind
        and G.GAME.blind.config.blind.key == "bl_tao_boss_dvd" and not G.GAME.blind.disabled
end

-- random float with a given seed key, in [min, max)
function Tao.funcs.dvd_random_float(seed_key, min, max)
    return min + pseudorandom(seed_key) * (max - min)
end

-- collects a UIElement and all things attached to it (button > row > text) into a flat list
function Tao.funcs.dvd_collect_subtree(elem, out)
    out = out or {}
    out[#out + 1] = elem
    for _, child in pairs(elem.children) do
        if child.T then Tao.funcs.dvd_collect_subtree(child, out) end
    end
    return out
end

function Tao.funcs.dvd_hijack_button(btn, seed_prefix)
    local orig_x, orig_y = btn.T.x, btn.T.y
    local nodes = {}
    for _, node in ipairs(Tao.funcs.dvd_collect_subtree(btn)) do
        node:set_role({ role_type = 'Major' })
        nodes[#nodes + 1] = { elem = node, rel_x = node.T.x - orig_x, rel_y = node.T.y - orig_y }
    end

    local speed = Tao.funcs.dvd_random_float(seed_prefix.."_speed_init", DVD_SPEED_MIN, DVD_SPEED_MAX)
    local ang = Tao.funcs.dvd_random_float(seed_prefix.."_ang_init", 0, 2 * math.pi)

    btn.tao_dvd = {
        nodes = nodes,
        pos_x = orig_x,
        pos_y = orig_y,
        vx = speed * math.cos(ang),
        vy = speed * math.sin(ang),
    }
end

-- writes the hijacked button's current position out to every node in its subtree.
function Tao.funcs.dvd_apply_position(btn)
    local dvd = btn.tao_dvd
    for _, n in ipairs(dvd.nodes) do
        local x, y = dvd.pos_x + n.rel_x, dvd.pos_y + n.rel_y
        n.elem.T.x, n.elem.T.y = x, y
        n.elem.VT.x, n.elem.VT.y = x, y
    end
end

-- mirror-reflects vx/vy off the hit axis, layers a random +/-5deg delta, re-rolls speed
function Tao.funcs.dvd_reflect_velocity(dvd, hit_x, hit_y, seed_prefix)
    local rvx = hit_x and -dvd.vx or dvd.vx
    local rvy = hit_y and -dvd.vy or dvd.vy
    local reflect_angle = math.atan2(rvy, rvx)
    local delta = Tao.funcs.dvd_random_float(seed_prefix.."_delta", -DVD_ANGLE_DELTA_DEG, DVD_ANGLE_DELTA_DEG)
    local final_angle = reflect_angle + math.rad(delta)
    local speed = Tao.funcs.dvd_random_float(seed_prefix.."_speed", DVD_SPEED_MIN, DVD_SPEED_MAX)
    dvd.vx = speed * math.cos(final_angle)
    dvd.vy = speed * math.sin(final_angle)
end

function Tao.funcs.dvd_move_button(btn, seed_prefix, dt)
    local dvd = btn.tao_dvd
    local min_x, min_y = 0, 0
    local max_x, max_y = G.ROOM.T.w - btn.T.w, G.ROOM.T.h - btn.T.h

    local x = dvd.pos_x + dvd.vx * dt
    local y = dvd.pos_y + dvd.vy * dt

    local hit_x = x < min_x or x > max_x
    local hit_y = y < min_y or y > max_y
    x = math.min(math.max(x, min_x), max_x)
    y = math.min(math.max(y, min_y), max_y)

    if hit_x or hit_y then
        Tao.funcs.dvd_reflect_velocity(dvd, hit_x, hit_y, seed_prefix)
    end

    dvd.pos_x, dvd.pos_y = x, y
end

-- AABB overlap between the two buttons; separates + mirror-reflects velocity along the smaller-penetration axis
function Tao.funcs.dvd_resolve_button_collision(a, b, seed_a, seed_b)
    local da, db = a.tao_dvd, b.tao_dvd

    local overlap_x = math.min(da.pos_x + a.T.w, db.pos_x + b.T.w) - math.max(da.pos_x, db.pos_x)
    local overlap_y = math.min(da.pos_y + a.T.h, db.pos_y + b.T.h) - math.max(da.pos_y, db.pos_y)
    if overlap_x <= 0 or overlap_y <= 0 then return end -- not actually touching

    if overlap_x < overlap_y then
        -- left/right collision: push apart along x, flip both buttons x velocity
        local push = overlap_x / 2 + 0.001
        local a_is_left = da.pos_x < db.pos_x
        da.pos_x = da.pos_x + (a_is_left and -push or push)
        db.pos_x = db.pos_x + (a_is_left and push or -push)
        Tao.funcs.dvd_reflect_velocity(da, true, false, seed_a)
        Tao.funcs.dvd_reflect_velocity(db, true, false, seed_b)
    else
        -- top/bottom collision: push apart along y, flip both buttons y velocity
        local push = overlap_y / 2 + 0.001
        local a_is_above = da.pos_y < db.pos_y
        da.pos_y = da.pos_y + (a_is_above and -push or push)
        db.pos_y = db.pos_y + (a_is_above and push or -push)
        Tao.funcs.dvd_reflect_velocity(da, false, true, seed_a)
        Tao.funcs.dvd_reflect_velocity(db, false, true, seed_b)
    end

    -- re-clamp against the room's walls in case the push shoved a button out of bounds
    for _, elem in ipairs({ a, b }) do
        local dvd = elem.tao_dvd
        dvd.pos_x = math.min(math.max(dvd.pos_x, 0), G.ROOM.T.w - elem.T.w)
        dvd.pos_y = math.min(math.max(dvd.pos_y, 0), G.ROOM.T.h - elem.T.h)
    end
end

function Tao.funcs.update_dvd_blind(dt)
    if not Tao.funcs.dvd_is_active() then
        Tao.dvd.active = false
        return
    end
    Tao.dvd.active = true
    if G.SETTINGS.paused then return end
    if not (G.buttons and G.buttons.states.visible) then return end

    local buttons = {}
    for id, seed_prefix in pairs({ play_button = "tao_dvd_play", discard_button = "tao_dvd_discard" }) do
        local btn = G.buttons:get_UIE_by_ID(id)
        if btn then
            if not btn.tao_dvd then Tao.funcs.dvd_hijack_button(btn, seed_prefix) end
            Tao.funcs.dvd_move_button(btn, seed_prefix, dt)
            buttons[#buttons + 1] = { elem = btn, seed = seed_prefix }
        end
    end

    if buttons[1] and buttons[2] then
        Tao.funcs.dvd_resolve_button_collision(buttons[1].elem, buttons[2].elem, buttons[1].seed, buttons[2].seed)
    end

    for _, b in ipairs(buttons) do
        Tao.funcs.dvd_apply_position(b.elem)
    end
end
SMODS.Atlas{
    key = 'sans_anim_atlas',
    path = 'blind_sans.png',
    px = 34,
    py = 34,
    atlas_table = 'ANIMATION_ATLAS',
    frames = 42,
}

-- bad time guy
local SansBlind = SMODS.Blind{
    key = 'sans',
    atlas = 'sans_anim_atlas',
    pos = {x = 0, y = 0},
    dollars = 100,
    discovered = true,
    boss = { min = 0 },
    boss_colour = HEX('000000'),
    flat_chips = 1, -- the easiest blind i said
    loc_txt = {
        name = 'Sans',
        text = {
            "The easiest",
            "blind"
        }
    },
}

-- freezes only once set_blind fires for real, so G.STATE is settled by the time sans takes over
local sans_blind_set_blind = Blind.set_blind
function Blind:set_blind(blind, reset, silent)
    sans_blind_set_blind(self, blind, reset, silent)

    if blind and blind.flat_chips and not reset then
        self.chips = blind.flat_chips
        self.chip_text = number_format(self.chips)
        if G.HUD_blind then G.HUD_blind:recalculate(false) end
    end

    if blind and blind.key == SansBlind.key and not reset and not SANS.state then
        SANS.StartIntroAnim()
    end
end

