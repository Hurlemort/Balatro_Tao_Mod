-- GLOBALS

------------------------------------------------------------
-- Frame Cap
------------------------------------------------------------
-- sits below the display refresh so every frame finishes compositing before it is read
G.FPS_CAP = 120

------------------------------------------------------------
-- Screen Effects Registry
------------------------------------------------------------
-- entry needs is_active(), draw(canvas), remap_point(x,y); see blinds.lua
Tao.screen_effects = Tao.screen_effects or {}

function Tao.funcs.get_active_screen_effect()
    for _, effect in pairs(Tao.screen_effects) do
        if effect.is_active() then return effect end
    end
    return nil
end

------------------------------------------------------------
-- Table Multipliers
------------------------------------------------------------
-- recursively multiplies numbers, respecting blacklist
function Tao.funcs.multiply_table(tbl, multiplier)
    local new_table = {}
    for key, value in pairs(tbl) do
        if type(value) == "number" and not Tao.custom_tables.mult_blacklist[key] then
            if key == "x_chips" or key == "x_mult" then -- skip if 1
                if value ~= 0 and value ~= 1 then
                    new_table[key] = value * multiplier
                else
                    new_table[key] = value
                end
            else
                if value ~= 0 then
                    new_table[key] = value * multiplier
                else
                    new_table[key] = value
                end
            end
        elseif type(value) == "table" then
            new_table[key] = Tao.funcs.multiply_table(value, multiplier)
        else
            new_table[key] = value
        end
    end
    return new_table
end

-- multiplies ability (number or table)
function Tao.funcs.multiply(card, multiplier)
    if not card or not card.ability then return end

    if type(card.ability) == "table" then
        if card.ability.extra ~= nil then
            if type(card.ability.extra) == "table" then
                card.ability.extra = Tao.funcs.multiply_table(card.ability.extra, multiplier)
            elseif type(card.ability.extra) == "number" then
                local value = card.ability.extra
                if (value ~= 0 and value ~= 1) then
                    card.ability.extra = value * multiplier
                end
            end
        else
            card.ability = Tao.funcs.multiply_table(card.ability, multiplier)
        end
    elseif type(card.ability) == "number" then
        local value = card.ability
        if (value ~= 0 and value ~= 1) then
            card.ability = value * multiplier
        end
    end
end

-- centre of a card in screen pixels, for effects drawn straight to the screen
function Tao.funcs.card_screen_pos(card)
    return (card.VT.x + card.VT.w/2 + G.ROOM.T.x) * G.TILESIZE * G.TILESCALE,
           (card.VT.y + card.VT.h/2 + G.ROOM.T.y) * G.TILESIZE * G.TILESCALE
end

function Tao.funcs.get_id(card, area)
    for id, c in pairs(area) do
        if c == card then
            return id
        end
    end
end

-- true 6, or Oops! owned; use instead of get_id()==6
function Tao.funcs.is_it_a_six(card)
    if card:get_id() == 6 or #SMODS.find_card("j_tao_oops") > 0 then
        return true
    end
    return false
end

------------------------------------------------------------
-- Lagrange Reset
------------------------------------------------------------
function Tao.funcs.reset_lagrange()
    G.GAME.lagrange.rank = 'Ace'
    G.GAME.lagrange.suit = 'Spades'
    local valid_cards = {}
    for k, v in ipairs(G.playing_cards) do
        if SMODS.has_any_suit(v) and not SMODS.has_no_rank(v) then
            valid_cards[#valid_cards+1] = v
        end
    end
    if valid_cards[1] then 
        local card = pseudorandom_element(valid_cards, pseudoseed('lagrange'..G.GAME.round_resets.ante))
        G.GAME.lagrange.rank = card.base.value
        G.GAME.lagrange.suit = card.base.suit
        G.GAME.lagrange.id = card.base.id
    end
end

------------------------------------------------------------
-- Joker rarity rerolling
------------------------------------------------------------
-- rarity here is a 0..1 roll threshold + legendary flag, not 1-4 (see get_current_pool)
function Tao.funcs.rarity_pool_args(rarity)
    if rarity == 4 then return 1, true end  -- legendary flag bypasses the threshold entirely
    if rarity == 3 then return 1, false end -- > 0.95
    if rarity == 2 then return 0.8, false end -- > 0.7 and <= 0.95
    return 0, false                           -- <= 0.7 (common)
end

function Tao.funcs.random_joker_of_rarity(rarity, skip_key, seed_key)
    local rarity_arg, legendary_arg = Tao.funcs.rarity_pool_args(rarity)
    local _pool, _pool_key = get_current_pool('Joker', rarity_arg, legendary_arg, seed_key)

    local key = pseudorandom_element(_pool, pseudoseed(_pool_key))
    local it = 1
    while (key == 'UNAVAILABLE' or key == skip_key) and it < 30 do
        it = it + 1
        key = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
    end
    return key
end

function Tao.funcs.random_consumable_of_set(set, seed_key)
    local _pool, _pool_key = get_current_pool(set, nil, false, seed_key)
    local key = pseudorandom_element(_pool, pseudoseed(_pool_key))
    local it = 1
    while key == 'UNAVAILABLE' and it < 30 do
        it = it + 1
        key = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
    end
    return key
end

------------------------------------------------------------
-- Applied Value Sync
------------------------------------------------------------
-- tracks what a joker actually pushed into a global, so doubling and removal both settle up exactly

-- clamped so card_limit never drops below 0
function Tao.funcs.sync_joker_slots(card, target)
    if not (G.jokers and card.ability and card.ability.extra) then return end
    local applied = card.ability.extra.applied_slot or 0
    local base = G.jokers.config.card_limit - applied
    target = math.max(target, -base)
    if target ~= applied then
        G.jokers.config.card_limit = base + target
        card.ability.extra.applied_slot = target
    end
end

function Tao.funcs.clear_joker_slots(card)
    if not (card.ability and card.ability.extra) then return end
    if G.jokers then
        G.jokers.config.card_limit = G.jokers.config.card_limit - (card.ability.extra.applied_slot or 0)
    end
    card.ability.extra.applied_slot = 0
end

function Tao.funcs.sync_hand_size(card, target)
    if not (G.hand and card.ability and card.ability.extra) then return end
    local applied = card.ability.extra.applied_hand_size or 0
    if target ~= applied then
        G.hand:change_size(target - applied)
        card.ability.extra.applied_hand_size = target
    end
end

function Tao.funcs.clear_hand_size(card)
    if not (card.ability and card.ability.extra) then return end
    if G.hand then G.hand:change_size(-(card.ability.extra.applied_hand_size or 0)) end
    card.ability.extra.applied_hand_size = 0
end

-- sets round_resets.hands to target, leaving other sources of hands intact
function Tao.funcs.sync_round_hands(card, target)
    if not (G.GAME and G.GAME.round_resets and card.ability and card.ability.extra) then return end
    local applied = card.ability.extra.applied_hands or 0
    local base = G.GAME.round_resets.hands - applied
    local want = target - base
    if want ~= applied then
        G.GAME.round_resets.hands = base + want
        card.ability.extra.applied_hands = want
    end
end

function Tao.funcs.clear_round_hands(card)
    if not (card.ability and card.ability.extra) then return end
    if G.GAME and G.GAME.round_resets then
        G.GAME.round_resets.hands = G.GAME.round_resets.hands - (card.ability.extra.applied_hands or 0)
    end
    card.ability.extra.applied_hands = 0
end

LOST_DECK_MAX_HANDS = 1 -- the Lost Deck plays one hand a round, no matter who offers more

function Tao.funcs.is_lost_deck()
    local center = G.GAME and G.GAME.selected_back and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
    return center ~= nil and center.key == "b_tao_lost"
end

-- called from the patches that hand hands out, never on a timer
function Tao.funcs.clamp_lost_deck_hands()
    if not (G.GAME and G.GAME.current_round) then return end
    if not Tao.funcs.is_lost_deck() then return end
    if (G.GAME.current_round.hands_left or 0) > LOST_DECK_MAX_HANDS then
        G.GAME.current_round.hands_left = LOST_DECK_MAX_HANDS
    end
end

-- true while the joker is actually live, so update hooks don't re-apply on a debuffed card
function Tao.funcs.is_live_joker(card)
    return G.jokers and card.area == G.jokers and not card.debuff
end

------------------------------------------------------------
-- Multiplier Blacklist
------------------------------------------------------------
Tao.custom_tables.mult_blacklist = {
    perish_tally = true,
    id = true,
    suit_nominal = true,
    base_nominal = true,
    face_nominal = true,
    qty = true,
    h_x_chips = true,
    d_size = true,
    h_size = true,
    selected_d6_face = true,
    colour = true,
    suit_nominal_original = true,
    times_played = true,
    applied_slot = true,
    applied_hand_size = true,
    applied_hands = true,
    watched = true,
}

------------------------------------------------------------
-- Joker Ordering
------------------------------------------------------------
-- next order for a rarity, clamped below the next tier's lowest order
function Tao.funcs.next_joker_order(rarity)
    local same_rarity_max = 0
    local min_higher_rarity = math.huge
    for _, center in pairs(SMODS.Centers) do
        if center.set == 'Joker' and center.order then
            if center.rarity == rarity and center.order > same_rarity_max then
                same_rarity_max = center.order
            end
            if center.rarity and center.rarity > rarity and center.order < min_higher_rarity then
                min_higher_rarity = center.order
            end
        end
    end
    local order = same_rarity_max + 1
    if order >= min_higher_rarity then
        order = (same_rarity_max + min_higher_rarity) / 2
    end
    return order
end

------------------------------------------------------------
-- Saliva edition mult scaling (Olive Oil interaction)
------------------------------------------------------------
-- counts owned cards with the Saliva edition
function Tao.funcs.count_saliva_cards()
    local n = 0
    local function count_area(area)
        if area and area.cards then
            for _, c in ipairs(area.cards) do
                if c.edition and c.edition.key == 'e_tao_saliva' then n = n + 1 end
            end
        end
    end
    count_area(G.jokers)
    count_area(G.consumeables)
    if G.playing_cards then
        for _, c in ipairs(G.playing_cards) do
            if c.edition and c.edition.key == 'e_tao_saliva' then n = n + 1 end
        end
    end
    return n
end

-- Saliva's mult base: 2, or Olive Oil's alt_base if owned
function Tao.funcs.saliva_base()
    local oliveoil = SMODS.find_card("j_tao_oliveoil")
    local card = oliveoil and oliveoil[1]
    if card and card.ability and card.ability.extra and card.ability.extra.alt_base then
        return card.ability.extra.alt_base
    end
    return (G.P_CENTERS.e_tao_saliva.config.extra and G.P_CENTERS.e_tao_saliva.config.extra.mult_base) or 2
end

------------------------------------------------------------
-- Load Images n Gifs
------------------------------------------------------------

SMODS.Sound({
    key = "foxy",
    path = "foxy.ogg",
})

-- explosion gif is Delatrune's, logic taken from Yahimod's el wiwi
SMODS.Sound({
    key = "explosion",
    path = "explosion.ogg",
})


function play_effect(effect,posx,posy)
    if effect == "buzzcutgif" then
        play_sound("tao_flashbang")
        neweffect = 
            {
            name = "buzzcutgif",
            duration = 156,

            frame = 1,
            maxframe = 78,
            fps = 20,
            tfps = 0, -- ticks per frame per second


            xpos = posx,
            ypos = posy,
            xvel = 0,
            yvel = 0,
            }
        end
    if effect == "foxy" then
        play_sound("tao_foxy")
        neweffect =
            {
            name = "foxy",
            duration = 14,

            frame = 1,
            maxframe = 28,
            fps = 20,
            tfps = 0, -- ticks per frame per second


            xpos = posx,
            ypos = posy,
            xvel = 0,
            yvel = 0,
            }
    end
    if effect == "explosion" then
        play_sound("tao_explosion")
        neweffect =
            {
            name = "explosion",
            duration = 2,

            frame = 1,
            maxframe = 17,
            fps = 20,
            tfps = 0, -- ticks per frame per second

            xpos = posx,
            ypos = posy,
            xvel = 0,
            yvel = 0,
            }
    end
    table.insert(G.effectmanager,{neweffect})
end

-- function display_image(var,frames)
--     var = frames
--     return var
-- end

local foxy_timer = foxy_timer or 0

function Tao.funcs.update_effects_and_ticks(dt)
    -- tick based events
    if Tao.events.ticks == nil then Tao.events.ticks = 0 end
    if Tao.events.dtcounter == nil then Tao.events.dtcounter = 0 end
    Tao.events.dtcounter = Tao.events.dtcounter+dt

    if G.effectmanager then
        for i = #G.effectmanager, 1, -1 do
            local eff = G.effectmanager[i][1]

            -- update frame timing
            eff.tfps = eff.tfps + dt
            local frame_time = 1 / eff.fps
            while eff.tfps >= frame_time do
                eff.tfps = eff.tfps - frame_time
                eff.frame = eff.frame + 1
            end

            -- decrease duration
            eff.duration = eff.duration - dt

            -- remove when finished
            if eff.frame > eff.maxframe or eff.duration <= 0 then
                table.remove(G.effectmanager, i)
            end
        end
    end

    while Tao.events.dtcounter >= 0.010 do
        Tao.events.ticks = Tao.events.ticks + 1
        Tao.events.dtcounter = Tao.events.dtcounter - 0.010

        if G.ltg and G.ltg > 0 then
            G.ltg = G.ltg - 1
            tick_event("ltg",G.ltg)
        end
    end

    foxy_timer = (foxy_timer or 0) + dt
    if foxy_timer >= 1 then
        foxy_timer = 0
        if SMODS.pseudorandom_probability(card, 'foxy', G.GAME.probabilities.normal or 1, 7642) then
            play_effect("foxy",0,0)
        end
    end

    -- boss_math's blinking equation-input cursor (items/blinds.lua)
    Tao.funcs.update_equation_blink(dt)

    -- boss_dvd's bouncing play/discard buttons (items/blinds.lua)
    Tao.funcs.update_dvd_blind(dt)
end

function Tao.funcs.draw_overlays()
    local screen_w = love.graphics.getWidth()
    local screen_h = love.graphics.getHeight()

    function load_image(fn)
        local full_path = (Tao.path .. "customimages/" .. fn)
        local file_data = assert(NFS.newFileData(full_path),("Epic fail img"))
        local tempimagedata = assert(love.image.newImageData(file_data),("Epic fail img 2"))

        return (assert(love.graphics.newImage(tempimagedata),("Epic fail img 3")))
    end

    function load_spritesheet(fn, frame_w, frame_h, cols, rows)
        local full_path = (Tao.path .. "customimages/" .. fn)
        local file_data = assert(NFS.newFileData(full_path), "Epic fail gif")
        local tempimagedata = assert(love.image.newImageData(file_data), "Epic fail 2 gif")

        local tempimg = assert(love.graphics.newImage(tempimagedata), "Epic fail 3 gif")

        local spritesheet = {}
        for row = 0, rows - 1 do
            for col = 0, cols - 1 do
                local quad = love.graphics.newQuad(
                    col * frame_w,  -- x offset
                    row * frame_h,  -- y offset
                    frame_w, frame_h,
                    tempimg:getWidth(),
                    tempimg:getHeight()
                )
                table.insert(spritesheet, quad)
            end
        end
        return spritesheet
    end

    -- ltg
    if G.ltg and (G.ltg > 0) then
        if Tao.ltgimg == nil then Tao.ltgimg = load_image("ltg.jpg") end
        local alpha = (G.ltg - 1) / 59

        local img_w = 268
        local img_h = 268

        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(Tao.ltgimg, 0, 0, 0, screen_w / img_w, screen_h / img_h)
    end


    if G.effectmanager then
        --print("Effect manager has "..#G.effectmanager)
        for i = 1, #G.effectmanager do
            --print("G.effectmanager[i].name".. G.effectmanager[i][1].name)
            if G.effectmanager[i] ~= nil then
                local eff = G.effectmanager[i][1]

                if eff.name == "buzzcutgif" then
                    -- lazy load image + quads
                    if Tao.buzzcutgif == nil then
                        Tao.buzzcutgif = load_image("taobuzzcut.png")
                    end
                    if Tao.buzzcutgif_sprite == nil then
                        Tao.buzzcutgif_sprite = load_spritesheet("taobuzzcut.png", 800, 447, 6, 13) -- 6 cols, 13 rows
                    end

                    local imagetodraw = Tao.buzzcutgif
                    local quadtodraw  = Tao.buzzcutgif_sprite

                    local frame_w  = 800
                    local frame_h  = 442

                    local frame_index = math.max(1, math.min(eff.frame, #quadtodraw))

                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(
                        imagetodraw,
                        quadtodraw[frame_index],
                        0, 0,  -- top-left corner
                        0,     -- rotation
                        screen_w / frame_w,
                        screen_h / frame_h
                    )
                end

                if eff.name == "foxy" then
                    -- lazy load image + quads
                    if Tao.foxy == nil then
                        Tao.foxy = load_image("foxy_jumpscare.png")
                    end
                    if Tao.foxy_sprite == nil then
                        Tao.foxy_sprite = load_spritesheet("foxy_jumpscare.png", 250, 188, 7, 2) -- 6 cols, 13 rows, width: 250px, height: 188px
                    end

                    local imagetodraw = Tao.foxy
                    local quadtodraw  = Tao.foxy_sprite

                    local frame_w  = 250
                    local frame_h  = 188

                    local frame_index = math.max(1, math.min(eff.frame, #quadtodraw))

                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(
                        imagetodraw,
                        quadtodraw[frame_index],
                        0, 0,  -- top-left corner
                        0,     -- rotation
                        screen_w / frame_w,
                        screen_h / frame_h
                    )
                end

                if eff.name == "explosion" then
                    -- lazy load image + quads
                    if Tao.explosiongif == nil then
                        Tao.explosiongif = load_image("explosiongif.png")
                    end
                    if Tao.explosiongif_sprite == nil then
                        Tao.explosiongif_sprite = load_spritesheet("explosiongif.png", 200, 282, 1, 17) -- 1 col, 17 rows
                    end

                    local imagetodraw = Tao.explosiongif
                    local quadtodraw  = Tao.explosiongif_sprite

                    local frame_index = math.max(1, math.min(eff.frame, #quadtodraw))
                    local xscale, yscale = 2 * screen_w / 1920, 2 * screen_h / 1080 -- 2x size, keep it consistent across resolutions

                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.draw(
                        imagetodraw,
                        quadtodraw[frame_index],
                        eff.xpos - 100 * xscale, eff.ypos - 141 * yscale, -- center on the card
                        0,
                        xscale, yscale
                    )
                end
            end
        end
    end
end


------------------------------------------------------------
-- Angry Birds Joker: shared movie/audio state + hooks
------------------------------------------------------------
Tao.assets.angry_birds = {
    present = false, -- owned/shop/pack copy exists
    muted = false,
    video = nil,        -- shared video instance (visual + audio)
    video_canvas = nil, -- per-frame snapshot of the video
    started = false,    -- the video has been seen playing at least once
    finished = false,   -- the movie has run through once; mult stops growing from here
}

local function tao_angry_birds_temp_copy(dest, rel_source_path)
    if not love.filesystem.getInfo(dest) then
        local file_data = assert(NFS.read(Tao.path .. rel_source_path),
            "Failed to read " .. rel_source_path)
        love.filesystem.write(dest, file_data)
    end
end

local function tao_count_angry_birds()
    local count = 0
    for _, area in ipairs({ G.jokers, G.shop_jokers, G.pack_cards, G.title_top }) do
        if area and area.cards then
            for _, c in ipairs(area.cards) do
                if c.config and c.config.center and c.config.center.key == "j_tao_angrybirdsmovie" then
                    count = count + 1
                end
            end
        end
    end
    return count
end

-- true once the movie canvas exists and this sprite is showing it
local function tao_ab_showing(sprite)
    return sprite.tao_ab_video and Tao.assets.angry_birds.video_canvas
end

-- skip shader formatting
local abm_draw_shader = Sprite.draw_shader
function Sprite:draw_shader(_shader, _shadow_height, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
    if tao_ab_showing(self) then
        self:draw_self()
        return
    end
    abm_draw_shader(self, _shader, _shadow_height, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
end

local abm_draw_self = Sprite.draw_self
function Sprite:draw_self(overlay)
    if tao_ab_showing(self) then
        if not self.states.visible then return end
        if self.sprite_pos.x ~= self.sprite_pos_copy.x or self.sprite_pos.y ~= self.sprite_pos_copy.y then
            self:set_sprite_pos(self.sprite_pos)
        end
        prep_draw(self, 1)
        love.graphics.scale(1/(self.scale.x/self.VT.w), 1/(self.scale.y/self.VT.h))
        love.graphics.setColor(overlay or G.BRUTE_OVERLAY or G.C.WHITE)
        love.graphics.draw(Tao.assets.angry_birds.video_canvas, 0, 0, 0, self.VT.w/(self.T.w), self.VT.h/(self.T.h))
        love.graphics.pop()
        add_to_drawhash(self)
        self:draw_boundingrect()
        if self.shader_tab then love.graphics.setShader() end
        return
    end
    abm_draw_self(self, overlay)
end


local function tao_angry_birds_video()
    local ab = Tao.assets.angry_birds
    if not ab.video then
        local ok, err = pcall(function()
            tao_angry_birds_temp_copy("tao_angry_birds.ogv", "resources/angry_birds.ogv")
            ab.video = love.graphics.newVideo("tao_angry_birds.ogv")
            ab.video:play()
        end)
        if not ok then
            sendWarnMessage("Angry Birds video failed to load: " .. tostring(err), "Tao")
        end
    end
    return ab.video
end


local abm_click = Card.click
function Card:click()
    abm_click(self)
    if self.config and self.config.center and self.config.center.key == "j_tao_angrybirdsmovie" and self.area == G.jokers
        and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift")) then
        Tao.assets.angry_birds.muted = not Tao.assets.angry_birds.muted
        self:juice_up(0.3, 0.3)
    end
end


-- tracks presence, attaches shared video, loops it, drives volume/mute, grows mult until the movie ends
function Tao.funcs.update_angry_birds(dt)
    -- waits until the game is past loading
    if not G.STAGE or G.STATE == G.STATES.SPLASH then return end

    local ab = Tao.assets.angry_birds
    ab.present = tao_count_angry_birds() > 0

    if ab.present then
        for _, area in ipairs({ G.jokers, G.shop_jokers, G.pack_cards, G.title_top }) do
            if area and area.cards then
                for _, card in ipairs(area.cards) do
                    if card.config and card.config.center and card.config.center.key == "j_tao_angrybirdsmovie"
                        and card.children.center and card.children.center.atlas == G.ASSET_ATLAS["tao_angry_birds"]
                        and not card.children.center.tao_ab_video then
                        if tao_angry_birds_video() then
                            card.children.center.tao_ab_video = true
                        end
                    end
                end
            end
        end
    end

    if ab.video then
        local ok, src = pcall(function() return ab.video:getSource() end)
        if ok and src then
            src:setVolume(ab.muted and 0 or (G.SETTINGS.SOUND.volume / 100) * (G.SETTINGS.SOUND.music_volume / 100))
        elseif not ok then
            ab.video = nil
        end
    end

    -- the movie only ever plays forward; starting over means building a new video
    if ab.video then
        if ab.present then
            local ok_play, playing = pcall(function() return ab.video:isPlaying() end)
            if ok_play then
                if playing then
                    ab.started = true
                elseif ab.started then
                    -- credits rolled: the picture holds on its last frame and the mult stops growing
                    if not ab.finished then
                        ab.finished = true
                        check_for_unlock({ type = "ach_tao_angry_birds_movie" })
                    end
                else
                    pcall(function() ab.video:play() end)
                end
            end
        elseif ab.started then
            -- no copy left on screen: drop the video so the next one starts from the beginning
            pcall(function() ab.video:pause() end)
            pcall(function() ab.video:release() end)
            ab.video = nil
            ab.video_last_frame_idx = nil
            ab.started = false
            ab.finished = false
        end
    end

    -- '' fades the music out through the game's own track logic
    if ab.present then
        G.video_soundtrack = ''
        -- every copy shares one watch time, while xmult stays per-card
        local watchers = {}
        for _, card in ipairs(G.jokers and G.jokers.cards or {}) do
            if card.config and card.config.center and card.config.center.key == "j_tao_angrybirdsmovie" then
                watchers[#watchers + 1] = card
            end
        end
        if watchers[1] then
            local watched = 0
            for _, card in ipairs(watchers) do
                watched = math.max(watched, card.ability.extra.watched or 0)
            end
            if not ab.finished then watched = watched + dt end
            for _, card in ipairs(watchers) do
                card.ability.extra.watched = watched
                card.ability.extra.xmult = 1 + watched * card.ability.extra.xmult_mod
            end
        end
    elseif G.video_soundtrack == '' then
        G.video_soundtrack = nil
    end
end

-- renders the video to a dedicated canvas once per frame
function Tao.funcs.draw_angry_birds_canvas()
    if not G.STAGE or G.STATE == G.STATES.SPLASH then return end

    local ab = Tao.assets.angry_birds
    if ab.video then
        if not ab.video_canvas then
            ab.video_canvas = love.graphics.newCanvas(168, 94)
        end

        -- only resamples when the video's 9fps timeline advances a frame
        local VIDEO_SRC_FPS = 9
        local ok_tell, pos = pcall(function() return ab.video:tell() end)
        if not ok_tell then return end
        local frame_idx = math.floor(pos * VIDEO_SRC_FPS)
        if ab.video_last_frame_idx ~= frame_idx then
            ab.video_last_frame_idx = frame_idx
            love.graphics.push('all')
            love.graphics.setCanvas(ab.video_canvas)
            love.graphics.clear(0, 0, 0, 1)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(ab.video, 0, 0)
            love.graphics.pop()
        end
    end
end

-- runs vanilla update, then Tao's tick/effect logic, then Angry Birds upkeep
local upd = Game.update
function Game:update(dt)
    upd(self, dt)
    Tao.funcs.update_effects_and_ticks(dt)
    Tao.funcs.update_angry_birds(dt)
end

-- Angry Birds canvas draws before Balatro's own pass; overlays draw last
local drawhook = love.draw
function love.draw()
    Tao.funcs.draw_angry_birds_canvas()
    drawhook()
    Tao.funcs.draw_overlays()
end
