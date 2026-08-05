SMODS.Atlas{
    key = "jokers",
    path = "jokers.png",
    px = 71,
    py = 95
}

-- fallback sprite for previews; in play the card draws the video canvas
SMODS.Atlas{
    key = "angry_birds",
    path = "angry_birds.png",
    px = 168,
    py = 94
}

SMODS.Sound({
    key = "vineboom",
    path = "vineboom.ogg",
})

SMODS.Sound({
    key = "ambatakum",
    path = "ambatakum.ogg",
})

SMODS.Sound({
    key = "fantastic",
    path = "fantastic.ogg",
})

SMODS.Sound({
    key = "flashbang",
    path = "flashbang.ogg",
})

SMODS.Sound({
    key = "bogosbinted",
    path = "bogosbinted.ogg",
})

-- -- FINISHED, +10 mult for each scored stone card
SMODS.Joker{
    key = "giga_pierre",
    config = { extra = { mult = 10 } },
    pos = { x = 3, y = 0 },
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    soul_pos = nil,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    loc_txt = {
        name = 'Giga Pierre',
        text = {"Each scored {C:attention}Stone{} card",
                "gives {C:mult}+#1#{} mult"}
    },

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if SMODS.has_enhancement(context.other_card, "m_stone") and not context.other_card.debuffed then

                G.E_MANAGER:add_event(Event({
                    func = function()
                        G.ltg = 60
                        play_sound("tao_vineboom")
                        return true
                    end,
                }))

                return {
                    message = "Pierrin' my shi'",
                    colour = G.C.MULT,
                    mult = card.ability.extra.mult, -- Give +10 mult for each stone card scored
                    card = context.other_card,
                    remove_default_message = true,
                }
            end
        end
    end,

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult } }
    end
}
-- FINISHED
SMODS.Joker{
    key = "khaled",
    config={extra = {joker_slot = 1} },
    pos = { x = 6, y = 1 },
    soul_pos = nil,
    rarity = 1,
    cost = 3,
    blueprint_compat = false,
    eternal_compat = false,
    perishable_compat = false,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = "What does he even do?",
        text = {"{C:dark_edition}+#1#{} joker slot",
        "{C:inactive}What does he even do?{}"}
    },
    
    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.joker_slot} }
    end,

    add_to_deck = function(self, card, from_debuff)
        Tao.funcs.sync_joker_slots(card, card.ability.extra.joker_slot)
    end,

    remove_from_deck = function(self, card, from_debuff)
        Tao.funcs.clear_joker_slots(card)
	end,

    update = function(self, card, dt)
        if Tao.funcs.is_live_joker(card) then
            Tao.funcs.sync_joker_slots(card, card.ability.extra.joker_slot)
        end
    end,
}
-- FINISHED
SMODS.Joker{
    key = "owo3",
    config={extra = {odds = 3, money = 3} },
    pos = { x = 4, y = 1 },
    soul_pos = nil,
    rarity = 1,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = ":3",
        text = {
            "{C:green}#1# in #2#{} chance",
            "for each played {C:attention}3{}",
            "to give {C:money}$#3#{}"
        }
    },
    
    loc_vars = function(self, info_queue, card)
        return { vars = {G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.money } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:get_id() == 3 and not context.other_card.debuffed then -- if the played card is a non-debuffed 3
                if pseudorandom("owo3") < G.GAME.probabilities.normal / card.ability.extra.odds then -- if the random number is less than the chance
                    return {
                        dollars = card.ability.extra.money,
                    }
                end
            end
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = "flibidi",
    config={ },
    pos = { x = 5, y = 0 },
    soul_pos = nil,
    rarity = 1,
    cost = 6,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Flibidi',
        text = {"{C:tarot}The Fool{} can now remember",
                "{C:attention}any{} consumable card",
                "{C:inactive,s:0.7}Thanks to seacap54 for the code :){}"}
            },
            
    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.c_fool
    end
}
-- FINISHED
SMODS.Joker{
    key = 'School Grade',
    pos = {x = 5, y = 1},
    config = { extra = {chips = 0, additional = 16}},
    atlas = 'jokers',
    rarity = 1,
    cost = 4,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'School Grade',
        text = { "{C:chips}+#2#{} Chips for every",
                    "{C:attention}4{} in your full deck",
                    "{C:inactive}(Currently {C:chips}+#1#{} {C:inactive}Chips){}",
    },},

    loc_vars = function(self, info_queue, card)
        local count = 0
        if G.playing_cards then
            for _, c in ipairs(G.playing_cards) do
                if c.base.value == "4" then
                    count = count + 1
                end
            end
        end
        card.ability.extra.chips = (card.ability.extra.additional * count)
		return { vars = { card.ability.extra.chips, card.ability.extra.additional}}
	end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers and (card.ability.extra.chips > 0) then
            local rand = math.random(0, 20)
            local rand_color
            if rand <= 5 then
                rand_color = G.C.RED
            elseif rand <= 10 then
                rand_color = G.C.ATTENTION
            elseif rand <= 15 then
                rand_color = G.C.CHIPS
            else
                rand_color = G.C.GREEN
            end
            return
                {
                chips = card.ability.extra.chips,
                colour = rand_color
                }
        end
    end,
}
-- NOT FINISHED
SMODS.Joker{
    key = 'Five Big Booms',
    pos = {x = 9, y = 1},
    config = { extra = {mult = 0, mult_mod = 5}},
    atlas = 'jokers',
    rarity = 1,
    cost = 6,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Five Big Booms',
        text = {
            "This Joker gains {C:mult}+#2#{} Mult",
            "when a {C:attention}playing card{} is destroyed",
            "{C:inactive}(Currently {C:mult}+#1#{} {C:inactive}Mult){}"},
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult, card.ability.extra.mult_mod } }
    end,

    calculate = function(self, card, context)
        if context.remove_playing_cards then
            for i=1, #context.removed do
                card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
            return {
                message = "He gets five big booms!",
                colour = G.C.ATTENTION
            }
            end
        end
        if context.joker_main and context.cardarea == G.jokers and (card.ability.extra.mult > 0) then
            return {
                mult = card.ability.extra.mult,
            }
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = 'calliste',
    pos = {x = 2, y = 2},
    config = { extra = {}},
    atlas = 'jokers',
    rarity = 1,
    cost = 6,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Calliste',
        text = {
            "Applies a {C:attention}random{} card modifier",
            "to the {C:attention}last scoring card{}",
            "of each hand"},
    },

    loc_vars = function(self, info_queue, card)
        return nil
    end,

    -- fires once the hand has finished scoring, so the modifier lands for the next hand
    calculate = function(self, card, context)
        if context.after and context.cardarea == G.jokers and context.scoring_hand then
            local target = context.scoring_hand[#context.scoring_hand]
            if not target then return end

            local modifier_type = math.floor(pseudorandom("calliste") * 3)

            if modifier_type == 0 then
                local enhancement = pseudorandom_element(G.P_CENTER_POOLS["Enhanced"], pseudoseed("calliste")).key
                while G.P_CENTERS[enhancement].no_doe or G.GAME.banned_keys[enhancement] do
                    enhancement = pseudorandom_element(G.P_CENTER_POOLS["Enhanced"], pseudoseed("calliste")).key
                end
                target:set_ability(G.P_CENTERS[enhancement])

            elseif modifier_type == 1 then
                local edition = SMODS.poll_edition({guaranteed = true, key = "calliste"})
                target:set_edition(edition)

            elseif modifier_type == 2 then
                local seal = SMODS.poll_seal{guaranteed = true, key = "calliste"}
                target:set_seal(seal)
            end

            return {
                message = localize("k_upgrade_ex"),
                colour = G.C.ATTENTION,
                card = target
            }
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = 'ace_of_dick',
    pos = {x = 3, y = 2},
    config = { extra = {xmult = 1, xmult_mod = 0.1}},
    atlas = 'jokers',
    rarity = 1,
    cost = 6,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Ace of Dick',
        text = {
            "This Joker gains {X:mult,C:white}X#2#{} Mult",
            "for each {C:attention}Ace{} in your full deck",
            "{C:inactive}(Currently{} {X:mult,C:white}X#1#{} {C:inactive}Mult){}"
            },
    },

    loc_vars = function(self, info_queue, card)
        local count = 0
        if G.playing_cards then
            for _, c in ipairs(G.playing_cards) do
                if c.base.value == "Ace" then
                    count = count + 1
                end
            end
        end
        card.ability.extra.xmult = 1 + (card.ability.extra.xmult_mod * count)
        return { vars = { card.ability.extra.xmult, card.ability.extra.xmult_mod } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers then
            return {
                xmult = card.ability.extra.xmult,
            }
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = 'skibidi',
    pos = {x = 8, y = 2},
    config = { extra = {money_mod = 2}},
    atlas = 'jokers',
    rarity = 1,
    cost = 6,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Skibidi Joker',
        text = {
            "Earns {C:money}$#1#{} at the end of the round",
            "for each {C:attention}Tao{} Joker in your possession",
            "{C:inactive}(Currently {C:money}$#2#{}{C:inactive}){}"
            },
    },

    loc_vars = function(self, info_queue, card)
        local tao_jokers = 0
        local total_tao_jokers = 1
        if G.jokers then
            for i, joker in ipairs(G.jokers.cards) do
                if joker.config.center.pools and joker.config.center.pools.tao_joker_pool_legendary then -- use legendary cuz all joker have the legendary pool
                    tao_jokers = tao_jokers + 1
                end
            end
            total_tao_jokers = tao_jokers * card.ability.extra.money_mod
        end
        return { vars = { card.ability.extra.money_mod, total_tao_jokers} }
    end,

    calculate = function(self, card, context)
        if context.end_of_round and context.cardarea == G.jokers then
            local tao_jokers = 0
            for i, joker in ipairs(G.jokers.cards) do
                if joker.config.center.pools and joker.config.center.pools.tao_joker_pool_legendary then -- use legendary cuz all joker have the legendary pool
                    tao_jokers = tao_jokers + 1
                end
            end
            return {
                dollars = tao_jokers * card.ability.extra.money_mod,
            }
        end
    end,
}

SMODS.Joker{
    key = 'luminum',
    pos = {x = 6, y = 2},
    config = { extra = {repetitions = 1}},
    atlas = 'jokers',
    rarity = 1,
    cost = 4,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Luminum',
        text = {
            "Retriggers all gold card",
            "{C:attention}#1#{} time"
            },
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.repetitions} }
    end,

    calculate = function(self, card, context)
        if context.repetition and (context.cardarea == G.play or context.cardarea == G.hand) then
            if SMODS.has_enhancement(context.other_card, "m_gold") and not context.other_card.debuffed then
                return {
                    repetitions = 1
                }
            end
        end
    end
}

SMODS.Joker{
    key = 'ambatakum',
    pos = {x = 9, y = 2},
    config = { extra = {odds = 3}},
    atlas = 'jokers',
    rarity = 1,
    cost = 6,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Ambatakum',
        text = {
            "{C:green}#1# in #2#{} chance",
            "to add {C:attention}Foil{} to a random joker",
            "at the end of the round"
            },
    },

    loc_vars = function(self, info_queue, card)
        if not card.edition or (card.edition and not card.edition.foil) then
			info_queue[#info_queue + 1] = G.P_CENTERS.e_foil
        end
        return { vars = { G.GAME.probabilities.normal, card.ability.extra.odds} }
    end,

    calculate = function(self, card, context)
        if context.end_of_round and context.cardarea == G.jokers and (not card.edition or (card.edition and not card.edition.foil)) then
            if pseudorandom("ambatakum") < G.GAME.probabilities.normal / card.ability.extra.odds then
                local valid_jokers = {}
                for _, j in ipairs(G.jokers.cards) do
                    if not j.edition or (j.edition and not j.edition.foil) then
                        table.insert(valid_jokers, j)
                    end
                end
                if #valid_jokers > 0 then
                    local joker = pseudorandom_element(valid_jokers, pseudoseed('ambatakum_joker'))
                    play_sound("tao_ambatakum")
                    joker:set_edition("e_foil")
                    return {
                        message = "Ambatakum'd",
                        colour = G.C.EDITION,
                        card = joker,
                    }
                end
            end
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = 'serious',
    pos = {x = 2, y = 4},
    config = { extra = { chip_mult = 0.8 } },
    atlas = 'jokers',
    rarity = 1,
    cost = 6,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    unlocked = true,
    discovered = true,
    blueprint_compat = true, -- works or nah?
    eternal_compat = true,
    perishable_compat = true,

    loc_txt = {
        name = "It's not that serious bro",
        text = {
            "Each Blind requires",
            "{C:attention}X#1#{} chips",
            "to defeat"
        },
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.chip_mult } }
    end,

    -- fires once per new blind, after blind.chips is rolled; multiplying it here is the whole effect
    calculate = function(self, card, context)
        if context.setting_blind then
            G.GAME.blind.chips = math.floor(G.GAME.blind.chips * card.ability.extra.chip_mult)
            G.GAME.blind.chip_text = number_format(G.GAME.blind.chips)
            card:juice_up()
            play_sound('chips2')
            return {
                message = "It's not that serious!",
                colour = G.C.CHIPS
            }
        end
    end
}

SMODS.Joker{
    key = 'rock',
    pos = {x = 4, y = 4},
    config = {},
    atlas = 'jokers',
    rarity = 1,
    cost = 5,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = "Small Rock",
        text = {
            "Sell this card to turn {C:attention}all{}",
            "your playing cards into {C:attention}Stone Cards{}"
            },
    },

    loc_vars = function(self, info_queue, card)
		info_queue[#info_queue + 1] = G.P_CENTERS.m_stone
        return nil
    end,
 
    calculate = function(self, card, context)
        if context.selling_self then
            for _, c in ipairs(G.playing_cards) do
                c:set_ability(G.P_CENTERS["m_stone"], nil, true)
            end
            return {
                message = "Kayou",
                colour = G.C.ATTENTION,
            }
        end
    end,
}

SMODS.Joker{
    key = "diamond",
    config={},
    pos = { x = 2, y = 3 },
    soul_pos = nil,
    rarity = 1,
    cost = 5,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true, ["six"] = true},

    loc_txt= {
        name = 'Diamond of Sixes',
        text = {"Turns all scored {C:attention}6s{} into {V:1}#1#{}"}
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { localize('Diamonds', 'suits_plural'), colours = { G.C.SUITS.Diamonds } } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if Tao.funcs.is_it_a_six(context.other_card) and context.other_card.base.suit ~= 'Diamonds' then
                context.other_card:change_suit('Diamonds')
                return {
                    message = localize('k_upgrade_ex'),
                    colour = G.C.SUITS.Diamonds
                }
            end
        end
    end,
}
-- FINISHED; counter lives on ability table, so it survives hands/rounds/blinds/antes
SMODS.Joker{
    key = "Six Fingers",
    config = { extra = { count = 0, interval = 6 } },
    pos = { x = 9, y = 3 },
    soul_pos = nil,
    rarity = 1,
    cost = 4,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true, ["six"] = true},

    loc_txt= {
        name = 'Six Fingers',
        text = {
            "Turns every {C:attention}6th{} played",
            "card into a {C:attention}6{}",
            "{C:inactive}(Active in #1# cards){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.interval - card.ability.extra.count } }
    end,

    calculate = function(self, card, context)
        -- full_hand = all played cards, not just scored ones; context.after = right before they return to deck
        if context.after and context.cardarea == G.jokers and context.full_hand then
            for _, played_card in ipairs(context.full_hand) do
                card.ability.extra.count = card.ability.extra.count + 1
                if card.ability.extra.count >= card.ability.extra.interval then
                    card.ability.extra.count = 0
                    SMODS.change_base(played_card, played_card.base.suit, "6")
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            played_card:juice_up()
                            card_eval_status_text(played_card, 'extra', nil, nil, nil, { message = "6!", colour = G.C.ATTENTION })
                            return true
                        end
                    }))
                end
            end
        end
    end
}

-- FINISHED; passive: Saliva's mult base is read from here via Tao.funcs.saliva_base()
SMODS.Joker{
    key = "oliveoil",
    config = { extra = { alt_base = 3 } },
    pos = { x = 6, y = 4 },
    soul_pos = nil,
    rarity = 1,
    cost = 4,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Olive Oil',
        text = {
            "{C:dark_edition}Saliva{} cards give",
            "{C:mult}+#1#^n{} Mult instead of {C:mult}+#2#^n{} Mult"
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_tao_saliva
        local alt_base = (card and card.ability and card.ability.extra and card.ability.extra.alt_base)
            or self.config.extra.alt_base
        local mult_base = (G.P_CENTERS.e_tao_saliva.config.extra and G.P_CENTERS.e_tao_saliva.config.extra.mult_base) or 2
        return { vars = { alt_base, mult_base } }
    end,
}

-- FINISHED
SMODS.Joker{
    key = "D6",
    config = {},
    pos = { x = 7, y = 3 },
    soul_pos = nil,
    rarity = 1,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'D6',
        text = {"Creates a {C:tarot}Dice Shard{}",
                "at the end of the round",
                "{C:inactive}(Must have room)"}
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.c_tao_dice_shard
    end,

    calculate = function(self, card, context)
        if context.end_of_round and context.cardarea == G.jokers then
            if #G.consumeables.cards + G.GAME.consumeable_buffer >= G.consumeables.config.card_limit then
                return { message = localize('k_no_room_ex'), colour = G.C.RED }
            end
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0.0,
                func = function()
                    local shard = create_card(nil, G.consumeables, nil, nil, nil, nil, 'c_tao_dice_shard', 'D6')
                    shard:add_to_deck()
                    G.consumeables:emplace(shard)
                    G.GAME.consumeable_buffer = 0
                    return true
                end
            }))
            return {
                message = "Dice Shard!",
                colour = G.C.SECONDARY_SET.Tarot,
            }
        end
    end
}
-- FINISHED, Creates a tarot card if 2 or more face cards are scored in one hand
SMODS.Joker{
    key = "victor",
    config = {extra = {tarot = 1, face_cards = 2}},
    pos={ x = 4, y = 0 },
    rarity = 2,
    cost = 6,
    blueprint_compat=true,
    eternal_compat=true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect=nil,
    soul_pos=nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Victor',
        text = {
            "Creates {C:tarot}#1#{} Tarot card",
            "if {C:attention}first hand{} of round has",
            "{C:attention}#2#{} or more scoring face cards"
            }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.tarot, card.ability.extra.face_cards }}
    end,        

    calculate = function(self, card, context)
        -- things for card twitching
        local eval = function() return G.GAME.current_round.hands_played == 0 end

        -- checks if it has room for tarot
        local tarot_to_create = math.min(card.ability.extra.tarot or 0, G.consumeables.config.card_limit - #G.consumeables.cards)
        if tarot_to_create < 1 then return end
        
        -- shake yo booty
        if context.first_hand_drawn then
            juice_card_until(card, eval, true)
        end

        -- check how many face cards
        if context.joker_main and context.cardarea == G.jokers and G.GAME.current_round.hands_played == 0 then
            local current_faces = 0
            for _, v in pairs(context.scoring_hand) do
                if v:is_face() then
                    current_faces = current_faces + 1
                end
            end
            
            if current_faces >= card.ability.extra.face_cards and tarot_to_create then
            -- Create Tarot cards
                for i = 1, tarot_to_create do
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            local tarot_card = create_card('Tarot', G.consumeables, nil, nil, nil, nil, nil, 'car')
                            tarot_card:add_to_deck()
                            G.consumeables:emplace(tarot_card)
                            return true
                        end
                    }))
                end
                return {message = "Le Crouz'", colour = G.C.SECONDARY_SET.Tarot}
            end
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = "zagrub",
    config={ },
    pos = { x = 6, y = 0 },
    soul_pos = nil,
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Zagrub',
        text = {"Create a {C:dark_edition}negative{} {C:tarot}The Fool{}",
                "upon defeating {C:attention}Boss Blind{}"}
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.c_fool
        if not card.edition or (card.edition and not card.edition.negative) then
            info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        end
    end,

    calculate = function(self, card, context)
        if context.end_of_round and (G.GAME.blind:get_type() == 'Boss') and (context.cardarea == G.jokers) then
            local card = create_card(nil, G.consumeables, nil, nil, nil, nil, 'c_fool', 'Zagrub')
            card:set_edition("e_negative")
            card:add_to_deck()
            G.consumeables:emplace(card)
            return{
                message = "Bogos Binted?",
                colour = G.C.CHIPS,
                sound = "tao_bogosbinted",
            }
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = "burning_zamn",
    config={ extra = { mult = 1, mult_mod = 1 } },
    pos = { x = 7, y = 0 },
    soul_pos = nil,
    rarity = 2,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = "Burnin' Zamn",
        text = {"{C:attention}Face cards{} each give",
                "{C:mult}+#2#{} Mult when scored and",
                "increases this Joker's mult by {C:mult}+#1#{}",
                "{C:inactive}(Currently {C:mult}+#2#{} {C:inactive}Mult){}",
                "{C:inactive}(Resets after hand is played){}"}
    },

    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.mult_mod, card.ability.extra.mult} }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:is_face() and not context.other_card.debuffed then -- if the played card is a non-debuffed face card
                local return_mult = card.ability.extra.mult
                if not context.blueprint then
                    card.ability.extra.mult = card.ability.extra.mult + card.ability.extra.mult_mod
                end
                return {
                    mult = return_mult,
                }
            end
        end
        if context.after and (card.ability.extra.mult > 1) and not context.blueprint then
            card.ability.extra.mult = 1 -- Reset the multiplier after the hand is played
            return {
                message = localize('k_reset'),
                colour = G.C.ATTENTION
            }
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = "stargazer",
    config={ extra = { repetitions = 1, cost_mult = 1.5 } },
    pos = { x = 8, y = 0 },
    soul_pos = nil,
    rarity = 2,
    cost = 5,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = "Stargazer",
        text = {
            "Retriggers {C:attention}#1#{} times planet cards,",
            "{C:chips}Planet{} cards and {C:chips}Celestial Packs{}",
            "cost {C:attention}X#2#{} more",
            "{C:inactive,s:0.7}Thanks to seacap54 for the code :){}"}
    },

    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.repetitions, card.ability.extra.cost_mult} }
    end,
    
    calculate = function(self, card, context)
        if context.using_consumeable and context.consumeable and context.consumeable.ability.set == "Planet" then
            for i = 1, card.ability.extra.repetitions do
                context.consumeable:use_consumeable(context.area, context.copier)
            end
        end
    end
}
-- NOT FINISHED
SMODS.Joker{
    key = "Crouau",
    config = { extra = { mod_xmult = 0.2, total = 21, xmult = 1}},
    pos = { x = 9, y = 0 },
    soul_pos = nil,
    rarity = 2,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = "Crouau",
        text = {
            "This Joker gains {X:mult,C:white}X#1#{} Mult",
            "per {C:attention}consecutive{} hand played whose",
            "scored cards' value add up to at least {C:attention}#2#{},",
            "{C:inactive}(Currently{} {X:mult,C:white}X#3#{} {C:inactive}Mult){}",
            "{C:inactive,s:0.7}(Face cards count as 10, Aces count as 11){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.mod_xmult, card.ability.extra.total, card.ability.extra.xmult} }
    end,

    calculate = function(self, card, context)
        if context.joker_main and context.scoring_hand then
            -- Sum up the value of all cards in the scoring hand
            local total_value = 0
            for _, c in ipairs(context.scoring_hand) do
                if c:get_id() == 14 then
                    total_value = total_value + 11 -- Ace
                elseif c:is_face() then
                    total_value = total_value + 10 -- Face
                else
                    total_value = total_value + c:get_id()
                end
            end

            local _trigger = false
            if total_value >= card.ability.extra.total then
                _trigger = true
            end

            if _trigger then
                card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.mod_xmult
                return {
                    xmult = card.ability.extra.xmult,
                }
            elseif not _trigger and card.ability.extra.xmult > 1 then
                card.ability.extra.xmult = 1
                return {
                    message = "Reset",
                    colour = G.C.ATTENTION,
                }
            end
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = "Fatass",
    config={ extra = { xmult = 4, joker_slot = -1}},
    pos = { x = 7, y = 1 },
    soul_pos = nil,
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    display_size = {w = 2*71, h = 95},

    loc_txt= {
        name = "Fatass Joker",
        text = {"{X:mult,C:white}X#1#{} Mult,",
                "{C:dark_edition}#2#{} joker slot."}
    },     
    
    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.xmult, card.ability.extra.joker_slot } }
    end,

    add_to_deck = function(self, card, from_debuff)
        Tao.funcs.sync_joker_slots(card, card.ability.extra.joker_slot)
    end,

    remove_from_deck = function(self, card, from_debuff)
        Tao.funcs.clear_joker_slots(card)
    end,

    update = function(self, card, dt)
        if Tao.funcs.is_live_joker(card) then
            Tao.funcs.sync_joker_slots(card, card.ability.extra.joker_slot)
        end
    end,

    calculate = function(self,card,context)
        if context.joker_main and context.cardarea == G.jokers then
            return{
                card = card,
                xmult = card.ability.extra.xmult,
            }
        end
    end         
}
-- FINISHED
SMODS.Joker{
    key = "Lagrange",
    config={ extra = {hand_size_aug = 1}},
    pos = { x = 2, y = 1 },
    soul_pos = nil,
    rarity = 2,
    cost = 8,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = "Lagrange",
        text = {
            "This Joker gains {C:attention}+#1#{} hand size",
            "each time a {C:attention}#2#{} of {C:attention}#3#{} is scored",
            "{C:inactive}(Changes and resets when {}{C:attention}Boss Blind{}{C:inactive} is defeated){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        local rank = G.GAME.lagrange and G.GAME.lagrange.rank or "Ace"
        local suit = G.GAME.lagrange and G.GAME.lagrange.suit or "Spades"

        return { vars = {card.ability.extra.hand_size_aug, rank, suit} }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:get_id() == G.GAME.lagrange.id and context.other_card.base.suit == G.GAME.lagrange.suit then
                local total = (card.ability.extra.applied_hand_size or 0) + card.ability.extra.hand_size_aug
                Tao.funcs.sync_hand_size(card, total)
                G.GAME.lagrange.triggers = G.GAME.lagrange.triggers + 1
                return {
                    message = "Entonces",
                    color = G.C.ATTENTION
                }
            end
        end


        if context.end_of_round and (G.GAME.blind:get_type() == 'Boss') and context.cardarea == G.jokers then

            Tao.funcs.reset_lagrange()
            Tao.funcs.clear_hand_size(card)
            G.GAME.lagrange.triggers = 0

            return {
                message = localize("k_reset"),
                colour = G.C.ATTENTION,
            }
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        Tao.funcs.clear_hand_size(card)
    end,
}
-- FINISHED
SMODS.Joker{
    key = "award",
    config={ extra = { xmult = 1, xmult_mod = 0.5 } },
    pos = { x = 3, y = 1 },
    soul_pos = nil,
    rarity = 2,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = "Bare Minimum Award",
        text = {
            "{X:mult,C:white}X#2#{} Mult for every ante",
            "since the start of the game",
            "{C:inactive}(Currently {X:mult,C:white}X#1#{} {C:inactive}Mult){}",
            "{C:inactive,s:0.7}(Starts at {X:mult,C:white,s:0.7}X#3#{} {C:inactive,s:0.7}Mult){}",
        }
    },

    loc_vars = function(self, info_queue, card)
        card.ability.extra.xmult = card.ability.extra.xmult_mod + (G.GAME.round_resets.blind_ante * card.ability.extra.xmult_mod)
        local base = 2*card.ability.extra.xmult_mod
        return { vars = {card.ability.extra.xmult, card.ability.extra.xmult_mod, base} }
    end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers and (card.ability.extra.xmult>1) then
            return {
                xmult = card.ability.extra.xmult,
            }
        end
        if context.end_of_round and (G.GAME.blind:get_type() == 'Boss') and (context.cardarea == G.jokers) then
            return {
                message = localize('k_upgrade_ex'),
                colour = G.C.ATTENTION,
                card = card,
            }
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = "mcqueen",
    config={ extra = { repetitions = 1 } },
    pos = { x = 8, y = 1 },
    soul_pos = nil,
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = "Flash McQueen",
        text = {"{C:attention}Retriggers{} all",
                "played cards {C:attention}#1#{} time",
                "if hand played contains a {C:attention}Straight{}"}
    },

    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.repetitions} }
    end,

    calculate = function(self, card, context)
        if string.find(G.GAME.current_round.current_hand.handname,"Straight") and context.repetition and context.cardarea == G.play then
            return {
                message = localize('k_again_ex'),
                repetitions = card.ability.extra.repetitions
            }
        end
    end

}

SMODS.Joker{
    key = 'never_lose_hope',
    pos = {x = 4, y = 2},
    config = { extra = {xmult = 3, odds = 5, odds_mod = 1}},
    atlas = 'jokers',
    rarity = 2,
    cost = 6,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Never Lose Hope',
        text = {
            "{C:green}#1# in #2#{} chance",
            "to give {X:mult,C:white}X#3#{} Mult,",
            "odds increase by {C:green}#4#{}",
            "every {C:attention}failed{} trigger",
            },
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.xmult, card.ability.extra.odds_mod } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers then
            if pseudorandom("never_lose_hope") < G.GAME.probabilities.normal / card.ability.extra.odds then
                card.ability.extra.odds = card.ability.extra.base_odds
                return {
                    xmult = card.ability.extra.xmult,
                }
            else
                card.ability.extra.odds = math.max(1, card.ability.extra.odds - card.ability.extra.odds_mod)
                return {
                    message = localize("k_upgrade_ex"),
                    colour = G.C.ATTENTION
                }
            end
        end
    end,

    -- just to be sure
    add_to_deck = function(self, card, from_debuff)
        card.ability.extra.base_odds = card.ability.extra.odds
    end
}

SMODS.Joker{
    key = 'homeless',
    pos = {x = 7, y = 2},
    config = { extra = {xmult = 3}},
    atlas = 'jokers',
    rarity = 2,
    cost = 6,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Homeless Queen',
        text = {
            "{C:white,X:mult}X#1#{} Mult if played hand",
            "contains a {C:attention}single Queen{}",
            "{C:inactive,s:0.7}Please Jimbo, my Queen is kind of homeless{}"
            },
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult} }
    end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers then
            local queens = 0
            for _, c in ipairs(context.scoring_hand) do
                if c:get_id() == 12 then
                    queens = queens + 1
                end
            end
            if queens == 1 then
                return {
                    xmult = card.ability.extra.xmult
                }
            end
        end
    end
}

SMODS.Joker{
    key = 'duo',
    pos = {x = 3, y = 4},
    config = { extra = {odds = 3}},
    atlas = 'jokers',
    rarity = 2,
    cost = 8,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = "When you lowkey full of joy and whimsy but bro is full of malice and malevolence",
        text = {
            "Debuffs {C:attention}left{} Joker",
            "Retriggers {C:attention}1{} time the {C:attention}right{} Joker",
            "{C:inactive,s:0.7}(Only works if there is a Joker to the left){}"
            },
    },

    -- loc_vars = function(self, info_queue, card)
    --     return { vars = { G.GAME.probabilities.normal card.ability.extra.odds} }
    -- end,

    update = function(self, card, dt)
        if G.jokers then
            local self_id = Tao.funcs.get_id(card, G.jokers.cards)
            local left_joker = self_id and self_id > 1 and G.jokers.cards[self_id - 1] or nil

            if card.ability.extra.debuffed_joker and card.ability.extra.debuffed_joker ~= left_joker then
                card.ability.extra.debuffed_joker:set_debuff(false)
                card.ability.extra.debuffed_joker = nil
            end

            if left_joker then
                left_joker:set_debuff(true)
                card.ability.extra.debuffed_joker = left_joker
            end
        end
    end,

    -- joker retriggers use retrigger_joker_check
    calculate = function(self, card, context)
        if context.retrigger_joker_check and not context.retrigger_joker then -- guard stops infinite retrigger
            local self_id = Tao.funcs.get_id(card, G.jokers.cards)

            if self_id and Tao.funcs.get_id(context.other_card, G.jokers.cards) == self_id + 1 and not context.other_card.debuffed then
                return {
                    repetitions = 1,
                    message = localize("k_again_ex"),
                    colour = G.C.ATTENTION,
                }
            end
        end
    end,

    remove_from_deck = function(self, card, from_debuff)
        if card.ability.extra.debuffed_joker then
            card.ability.extra.debuffed_joker:set_debuff(false)
            card.ability.extra.debuffed_joker = nil
        end
    end,
}

SMODS.Joker{
    key = "oops",
    config={},
    pos = { x = 3, y = 3 },
    soul_pos = nil,
    rarity = 2,
    cost = 5,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true, ["six"] = true},

    loc_txt= {
        name = 'Oops! All 6s',
        text = {
            "All cards count as {C:attention}6s{}",
            "{C:inactive}(does not change your poker hand){}"
        }
    },
    -- loc_vars = function(self, info_queue, card)
    --     return { vars = {card.ability.extra.xmult} }
    -- end,

    -- calculate = function(self, card, context)
    --     return nil
    -- end,
}

SMODS.Joker{
    key = "sixseven",
    config={ extra = { xmult = 6.7} },
    pos = { x = 4, y = 3 },
    soul_pos = nil,
    rarity = 2,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true, ["six"] = true},

    loc_txt= {
        name = 'Six Seven',
        text = { "{X:mult,C:white}X#1#{} if played hand",
                    "contains a {C:attention}6{} and a {C:attention}7{}",
    },},

    loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.xmult}}
	end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers then
            local six = false
            local seven = false
            for _, c in ipairs(context.scoring_hand) do
                -- separate ifs not elseif, a 7 can also count as a six with Oops! active
                if not six and Tao.funcs.is_it_a_six(c) then
                    six = true
                end
                if not seven and c:get_id() == 7 then
                    seven = true
                end
            end
            if six and seven then
                return {
                    xmult = card.ability.extra.xmult,
                }
            end
        end
    end
}

SMODS.Joker{
    key = "handdrawn",
    config={ extra = { xmult = 1, xmult_mod = 0.2 } },
    pos = { x = 5, y = 3 },
    soul_pos = nil,
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true, ["six"] = true},

    loc_txt= {
        name = 'Hand-drawn Six',
        text = { "{X:mult,C:white}X#2#{} Mult for every",
                    "{C:attention}6{} in your full deck",
                    "{C:inactive}(Currently {X:mult,C:white}X#1#{}{C:inactive} Mult){}",
    },},

    loc_vars = function(self, info_queue, card)
        local count = 0
        if G.playing_cards then
            for _, c in ipairs(G.playing_cards) do
                if Tao.funcs.is_it_a_six(c) then
                    count = count + 1
                end
            end
        end
        card.ability.extra.xmult = (card.ability.extra.xmult_mod * count) + 1
		return { vars = { card.ability.extra.xmult, card.ability.extra.xmult_mod}}
	end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers and (card.ability.extra.xmult > 1) then
            return {
                xmult = card.ability.extra.xmult,
            }
        end
    end,
}
-- FINISHED
SMODS.Joker{
    key = "ED6",
    config = {},
    pos = { x = 8, y = 3 },
    soul_pos = nil,
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Eternal D6',
        text = {"Creates an {C:spectral}Eternal Dice Shard{}",
                "at the end of the round",
                "{C:inactive}(Must have room)"}
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.c_tao_eternal_dice_shard
    end,

    calculate = function(self, card, context)
        if context.end_of_round and context.cardarea == G.jokers then
            if #G.consumeables.cards + G.GAME.consumeable_buffer >= G.consumeables.config.card_limit then
                return { message = localize('k_no_room_ex'), colour = G.C.RED }
            end
            G.GAME.consumeable_buffer = G.GAME.consumeable_buffer + 1
            G.E_MANAGER:add_event(Event({
                trigger = 'before',
                delay = 0.0,
                func = function()
                    local shard = create_card(nil, G.consumeables, nil, nil, nil, nil, 'c_tao_eternal_dice_shard', 'Eternal D6')
                    shard:add_to_deck()
                    G.consumeables:emplace(shard)
                    G.GAME.consumeable_buffer = 0
                    return true
                end
            }))
            return {
                message = "Dice Shard!",
                colour = G.C.SECONDARY_SET.Spectral,
            }
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = "angrybirdsmovie",
    config = { extra = { xmult = 1, xmult_mod = 0.0025, watched = 0} },
    pos = { x = 0, y = 0 },
    soul_pos = nil,
    rarity = 2,
    cost = 6,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = "angry_birds",
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    display_size = {w = 126, h = 71},

    loc_txt = {
        name = "The_Angry_Birds_Movie_(2016).mp4",
        text = {
            "This Joker gains",
            "{X:mult,C:white}X#1#{} Mult per second",
            "until the movie ends",
            "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { string.format("%.4f", card.ability.extra.xmult_mod), card.ability.extra.xmult } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers then
            return {
                card = card,
                xmult = card.ability.extra.xmult,
            }
        end
    end
}
-- FINISHED
SMODS.Joker{
    key = "iris",
    config = { extra = {repetitions = 2,  hand_size_aug = 2}},
    pos = { x = 2, y = 0 },
    rarity = 3,
    cost = 8,
    blueprint_compat=true,
    eternal_compat=true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect=nil,
    soul_pos=nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= { 
        name = 'Iris',
        text = {"Retriggers all",
                "played cards {C:attention}#1#{} times,",
                "{C:attention}-#2#{} hand size"}
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.repetitions, card.ability.extra.hand_size_aug }}
    end,

    calculate = function(self,card,context)
        if context.repetition and context.cardarea == G.play then
            return {                             
                message = localize('k_again_ex'),
                repetitions = card.ability.extra.repetitions
            }
        end
    end,

    add_to_deck = function(self, card, from_debuff)
        Tao.funcs.sync_hand_size(card, -card.ability.extra.hand_size_aug)
    end,
    remove_from_deck = function(self, card, from_debuff)
        Tao.funcs.clear_hand_size(card)
    end,
    update = function(self, card, dt)
        if Tao.funcs.is_live_joker(card) then
            Tao.funcs.sync_hand_size(card, -card.ability.extra.hand_size_aug)
        end
    end
}

SMODS.Joker{
    key = 'fantastic',
    pos = {x = 5, y = 2},
    config = { extra = {money = 4, chips = 4, mult = 4, xmult = 1.4, triggered = false}},
    atlas = 'jokers',
    rarity = 3,
    cost = 8,
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},
    
    unlocked = true,
    discovered = true,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,

    loc_txt= {
        name = 'Fantastic Joker',
        text = {
            "Played {C:attention}4{} gives",
            "{C:money}$#1#{}, {C:chips}+#2#{} Chips, {C:mult}+#3#{} Mult, {X:mult,C:white}X#4#{} Mult",
            "when scored",
            },
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.money, card.ability.extra.chips, card.ability.extra.mult, card.ability.extra.xmult} }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if context.other_card:get_id() == 4 and not context.other_card.debuffed then

                if not card.ability.extra.triggered then
                    play_sound("tao_fantastic", 1, 1)
                    card.ability.extra.triggered = true
                end

                return {
                    dollars = card.ability.extra.money,
                    chips = card.ability.extra.chips,
                    mult = card.ability.extra.mult,
                    xmult = card.ability.extra.xmult
                }
            end
        end

        if context.after then
            card.ability.extra.triggered = false
        end
    end
}

SMODS.Joker{
    key = "accumulator",
    config={ extra = { base_reps = 1} },
    pos = { x = 6, y = 3 },
    soul_pos = nil,
    rarity = 3,
    cost = 8,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true, ["six"] = true},

    loc_txt= {
        name = 'Accumulator',
        text = {
            "Each scored {C:attention}6{} is retriggered",
            "{C:attention}#1#{} time more than the previous one",
    },},

    loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.base_reps} }
	end,

    -- retriggers scale with the card's position among the scored 6s: 1st once, 2nd twice, and so on
    calculate = function(self, card, context)
        if context.repetition and context.cardarea == G.play then
            if Tao.funcs.is_it_a_six(context.other_card) and not context.other_card.debuffed then
                local index = 0
                for _, c in ipairs(context.scoring_hand) do
                    if Tao.funcs.is_it_a_six(c) and not c.debuffed then
                        index = index + 1
                        if c == context.other_card then
                            return {
                                repetitions = card.ability.extra.base_reps * index,
                                message = "6!"
                            }
                        end
                    end
                end
            end
        end
    end
}
-- FINISHED; raises Mult via Talisman's e_mult
SMODS.Joker{
    key = "Terence",
    config = { extra = { mult_exp = 1.5, hands = 1 } },
    pos = { x = 5, y = 4 },
    soul_pos = nil,
    rarity = 3,
    cost = 7,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool"] = true, ["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Terence',
        text = {
            "{X:dark_edition,C:white}^#1#{} Mult.",
            "Sets your hands to {C:chips}#2#{}"
        }
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.mult_exp, card.ability.extra.hands } }
    end,

    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers then
            if to_big(SMODS.Scoring_Parameters.mult.current) > to_big(0) then -- a negative Mult would go NaN under ^1.5
                return {
                    e_mult = card.ability.extra.mult_exp,
                }
            end
        end
    end,

    add_to_deck = function(self, card, from_debuff)
        Tao.funcs.sync_round_hands(card, card.ability.extra.hands)
    end,

    remove_from_deck = function(self, card, from_debuff)
        Tao.funcs.clear_round_hands(card)
    end,

    update = function(self, card, dt)
        if Tao.funcs.is_live_joker(card) then
            Tao.funcs.sync_round_hands(card, card.ability.extra.hands)
        end
    end,
}



SMODS.Joker{
    key = "holy_six",
    config={ extra = { xmult = 6 } },
    pos = { x = 0, y = 3 },
    soul_pos = { x = 1, y = 3 },
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool_legendary"] = true, ["six"] = true},

    loc_txt= {
        name = 'Holy Six',
        text = {"Each scored {C:attention}6{} of {V:1}#2#{}",
                "gives {X:mult,C:white}X#1#{} Mult",}
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.extra.xmult, localize('Diamonds', 'suits_plural'), colours = { G.C.SUITS.Diamonds } } }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play then
            if Tao.funcs.is_it_a_six(context.other_card)
                and context.other_card:is_suit('Diamonds')
                and not context.other_card.debuffed then
                return {
                    xmult = card.ability.extra.xmult
                }
            end
        end
    end,
}
-- FINISHED
SMODS.Joker{
    key = "Tao",
    config={ extra = { aug = 2 } },
    pos = { x = 0, y = 0 },
    soul_pos = { x = 1, y = 0 },
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Tao',
        text = {"{X:dark_edition,C:white}X#1#{} {C:attention,E:1}all the values{}",
                "of the joker to the right",
                "upon defeating {C:attention}Boss Blind{}"}
    },

    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.aug} }
    end,

    calculate = function(self, card, context)
        if (context.end_of_round and not context.repetition and not context.individual) and G.GAME.blind and G.GAME.blind:get_type() == 'Boss'
        then
            -- Find Tao's index
            local tao_index = Tao.funcs.get_id(card, G.jokers.cards)
            -- for i, v in ipairs(G.jokers.cards) do
            --     if v == card then
            --         tao_index = i
            --         break
            --     end
            -- end

            -- Get the joker to the right
            local right_joker = G.jokers.cards[tao_index + 1] or nil
            if right_joker and right_joker ~= card then
                Tao.funcs.multiply(right_joker, card.ability.extra.aug)
                -- G.taobuzzcut = 156
                -- play_sound("tao_flashbang" ,1 ,1)
                play_effect("buzzcutgif",0,0)
                return {
                    message = "d(^_^)", 
                    colour = G.C.GREEN }
            else
                return {
                    message = "No friend ;-;",
                    colour = G.C.RED,
                }
            end
        end
    end,

}
-- FINISHED
SMODS.Joker{
    key = "peak",
    config={ extra = { odds = 4 } },
    pos = { x = 0, y = 2 },
    soul_pos = { x = 1, y = 2 },
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Peak',
        text = {
            "{C:green}#1# in #2#{} chance to make",
            "the {C:attention}Joker{} to the {C:attention}right{} {C:dark_edition,E:1}negative{}",
            "at the end of the round",
            "{C:inactive}({}{C:green}Probability{} {C:inactive}decreases for each{}",
            "{C:inactive}non-negative Joker owned){}",
            }
    },

    loc_vars = function(self, info_queue, card)
        if not card.edition or (card.edition and not card.edition.negative) then
			info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
        end
        local count = 0
        if G.jokers and G.jokers.cards then
            for i, v in ipairs(G.jokers.cards) do
                if not v.edition or (not v.edition.negative) then
                    count = count + 1
                end
            end
            card.ability.extra.odds = count
        else
            card.ability.extra.odds = 1
        end
        return { vars = {G.GAME.probabilities.normal, card.ability.extra.odds} }
    end,

    calculate = function(self, card, context)
        if (context.end_of_round and not context.repetition and not context.individual) and G.GAME.blind then
            if pseudorandom("peak") < G.GAME.probabilities.normal / card.ability.extra.odds then
                -- Find self's index
                local self_index = Tao.funcs.get_id(card, G.jokers.cards)
                -- for i, v in ipairs(G.jokers.cards) do
                --     if v == card then
                --         self_index = i
                --         break
                --     end
                -- end

                -- Get the joker to the right
                local right_joker = self_index and G.jokers.cards[self_index + 1] or nil
                if right_joker and right_joker ~= card then
                    -- Apply negative edition to the right joker
                    right_joker:set_edition("e_negative")
                    return {
                        message = "Peak Fiction",
                        colour = G.C.DARK_EDITION,
                        card = right_joker,
                    }
                end
            else
                return {
                    message = "Nuh uh!",
                    colour = G.C.RED,
                }
            end
        end
    end,
}
-- FINISHED
SMODS.Joker{
    key = "Magne",
    config={ extra = { mod_xmult = 0.5, xmult = 1} },
    pos = { x = 0, y = 1 },
    soul_pos = { x = 1, y = 1 },
    rarity = 4,
    cost = 20,
    blueprint_compat = true,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Magne',
        text = {"This Joker gains {X:mult,C:white}X#1#{} Mult",
                "each time a {C:attention}Queen{} is scored",
                "{C:inactive}(Currently {X:mult,C:white}X#2#{} {C:inactive}Mult){}"}
    },

    loc_vars = function(self, info_queue, card)
        return { vars = {card.ability.extra.mod_xmult, card.ability.extra.xmult} }
    end,

    calculate = function(self, card, context)
        if context.individual and context.cardarea == G.play and not context.blueprint then
            if context.other_card:get_id() == 12 and not context.other_card.debuffed then -- if the played card is a non-debuffed Queen
                card.ability.extra.xmult = card.ability.extra.xmult + card.ability.extra.mod_xmult
                return {
                    message = "Hougou!",
                    colour = G.C.ATTENTION,
                }
            end
        end
        if context.joker_main and context.cardarea == G.jokers and (card.ability.extra.xmult>1)  then
            return {
				xmult = card.ability.extra.xmult,
            }
        end
    end
}

-- FINISHED
SMODS.Joker{
    key = "Hurlemort",
    config = { extra = {} },
    pos = { x = 0, y = 4 },
    -- scales the soul glow to 0.75x whatever the vanilla wobble animation would be (final scale = 1 + scale_mod)
    soul_pos = {
        x = 1, y = 4,
        draw = function(card, scale_mod, rotate_mod)
            local soul, center = card.children.floating_sprite, card.children.center
            if not (soul and center) then return end
            local scaled_mod = (1 + scale_mod) * 0.75 - 1
            soul:draw_shader('dissolve', 0, nil, nil, center, scaled_mod, rotate_mod, nil, 0.1 + 0.03*math.sin(1.8*G.TIMERS.REAL), nil, 0.6)
            soul:draw_shader('dissolve', nil, nil, nil, center, scaled_mod, rotate_mod)
        end
    },
    rarity = 4,
    cost = 20,
    blueprint_compat = false,
    eternal_compat = true,
    perishable_compat = true,
    unlocked = true,
    discovered = true,
    effect = nil,
    atlas = 'jokers',
    pools = {["tao_joker_pool_legendary"] = true},

    loc_txt= {
        name = 'Hurlemort',
        text = {
            "All {C:attention}non-Tao{} Jokers",
            "become {C:dark_edition}Negative{}",
            "{C:inactive,s:0.7}(Art by Héroe Legendario){}"
        }
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS.e_negative
    end,

    -- re-checks each hand played, so jokers bought later get caught too
    calculate = function(self, card, context)
        if context.joker_main and context.cardarea == G.jokers and G.jokers and G.jokers.cards then
            for _, j in ipairs(G.jokers.cards) do
                if j.config and j.config.center and j.config.center.set == 'Joker'
                    and not j.config.center.key:find("^j_tao_")
                    and (not j.edition or not j.edition.negative) then
                    j:set_edition("e_negative", true, true)
                end
            end
        end
    end,
}
