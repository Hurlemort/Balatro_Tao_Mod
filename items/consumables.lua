SMODS.Atlas{
    key = "consumables",
    path = "consumables.png",
    px = 71,
    py = 95
}

SMODS.Sound({
    key = "diceshard",
    path = "diceshard.ogg",
})

SMODS.Consumable{
    key = "glutton",
    set = "Spectral",
    object_type = "Consumable",
    name = "glutton",
    pos = {x=0, y=1},
    atlas = "consumables",
    unlocked = true,
    discovered = true,
    cost = 6,
    config = {mult = 2},
    loc_txt = {
        name = "Glutton",
        text={
            "{X:dark_edition,C:white}X#1#{} {C:attention,E:1}all the values{}",
            "of a {C:attention}random{} Joker,",
            "{C:mult}destroys{} {C:attention}all{} other Jokers"
        },
    },

    loc_vars = function(self, info_queue, card)
        return {vars = {(card.ability or self.config).mult}}
    end,

    use = function(self, card, area, copier)
        local jokers = G.jokers.cards
        local count = #jokers
        if count == 0 then return end

        -- Pick random joker
        local double_idx = math.floor(pseudorandom("glutton") * count) + 1
        local double_joker = jokers[double_idx]
        Tao.funcs.multiply(double_joker, card.ability.mult)
        for i = #jokers, 1, -1 do
            local j = jokers[i]
            if j ~= double_joker and not SMODS.is_eternal(j) then
                j:start_dissolve()
            end
        end
        G.E_MANAGER:add_event(Event({
            func = function()
                double_joker:juice_up(0.8, 0.8)
                card_eval_status_text(
                    double_joker, 'extra', nil, nil, nil,
                    { message = localize("k_upgrade_ex"), colour = G.C.ATTENTION }
                )
                return true
            end
        }))
    end,

    can_use = function(self, card)
        return #G.jokers.cards >= 1
    end,
}

SMODS.Consumable{
    key = "arrow",
    set = "Spectral",
    object_type = "Consumable",
    name = "arrow",
    pos = {x=1, y=1},
    atlas = "consumables",
    unlocked = true,
    discovered = true,
    cost = 6,
    config = {extra = {odds = 2, mult = 2, joker_select = 1}},
    loc_txt = {
        name = "Arrow",
        text={
            "{C:green}#1# in #2#{} chance",
            "to {X:dark_edition,C:white}X#3#{} {C:attention,E:1}all the values{}",
            "of up to {C:attention}#4# selected{} Joker,",
            "otherwise, {C:mult}destroys{} it"
        },
    },

    loc_vars = function(self, info_queue, card)
        return {vars = {G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.mult, card.ability.extra.joker_select}}
    end,

    use = function(self, card, area, copier)
        -- gather selected jokers
        local selected_jokers = {}
        for _, v in ipairs(G.jokers.cards) do
            if v.highlighted then
                selected_jokers[#selected_jokers+1] = v
            end
        end

        -- process up to joker_select jokers (matches can_use)
        if #selected_jokers > 0 and #selected_jokers <= card.ability.extra.joker_select then
            for _, joker in ipairs(selected_jokers) do
                local success = pseudorandom('arrow') < (G.GAME.probabilities.normal / card.ability.extra.odds)
                if success then
                    Tao.funcs.multiply(joker, card.ability.extra.mult)

                    -- popup on the affected Joker
                    G.E_MANAGER:add_event(Event({
                        func = function()
                            joker:juice_up(0.8, 0.8)
                            card_eval_status_text(
                                joker, 'extra', nil, nil, nil,
                                { message = localize("k_upgrade_ex"), colour = G.C.ATTENTION }
                            )
                            return true
                        end
                    }))
                else
                    if not SMODS.is_eternal(joker) then
                        -- show message first, then remove the card
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                joker:juice_up(0.8, 0.8)
                                card_eval_status_text(
                                    joker, 'extra', nil, nil, nil,
                                    { message = "Destroyed", colour = G.C.MULT }
                                )
                                return true
                            end
                        }))
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                joker:start_dissolve()
                                return true
                            end
                        }))
                    end
                end
            end
            return true -- SMODS knows that the consumable was used
        end
    end,

    can_use = function(self, card)
        -- allow using when 1..joker_select jokers are selected (matches 'use')
        local n = 0
        for _, v in ipairs(G.jokers.cards) do
            if v.highlighted then n = n + 1 end
        end
        return n > 0 and n <= card.ability.extra.joker_select
    end,
}


SMODS.Consumable{
    key = "boon",
    set = "Tarot",
    object_type = "Consumable",
    name = "boon",
    pos = {x = 0, y = 0},
	atlas = "consumables",
    unlocked = true,
    discovered = true,
    cost = 4,

    loc_txt = {
        name = "Tao's Boon",
        text={
        "Creates a random",
        "{C:attention}Tao Joker{}",
        "{C:inactive}(must have room){}",
        },
    },
	
    -- deferred like vanilla Judgement so the consumable plays its use animation before the joker pops in
    use = function(self, card, area, copier)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('timpani')
                local joker = create_card("tao_joker_pool_legendary", G.jokers, nil, nil, nil, nil, nil, 'boon')
                joker:add_to_deck()
                G.jokers:emplace(joker)
                if card and card.juice_up then card:juice_up(0.3, 0.5) end
                card_eval_status_text(joker, 'extra', nil, nil, nil,
                    { message = localize('k_plus_joker'), colour = G.C.BLUE })
                return true
            end
        }))
        delay(0.6)
    end,

    can_use = function(self, card)
        return #G.jokers.cards < G.jokers.config.card_limit
	end,
}

SMODS.Consumable{
    key = "dilemma",
    set = "Tarot",
    object_type = "Consumable",
    name = "dilemma",
    config = {extra = {odds = 1000, money = 6283758}},
	pos = {x = 1, y = 0},
	atlas = "consumables",
    unlocked = true,
    discovered = true,
    cost = 4,

    loc_txt = {
        name = "Gambler's Dilemma",
        text={
        "{C:green}#1# in #2#{} chance",
        " to gain {C:money}$#3#{}",
        },
    },
	
	loc_vars = function(self, info_queue, card)
        return {vars = {G.GAME.probabilities.normal, card.ability.extra.odds, card.ability.extra.money}}
    end,

    use = function(self, card, area, copier)
        if pseudorandom('dilemma') < (G.GAME.probabilities.normal / card.ability.extra.odds) then
            ease_dollars(card.ability.extra.money)
        else
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
                attention_text({
                    text = localize('k_nope_ex'),
                    scale = 1.3, 
                    hold = 1.4,
                    major = card,
                    backdrop_colour = G.C.SECONDARY_SET.Tarot,
                    align = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and 'tm' or 'cm',
                    offset = {x = 0, y = (G.STATE == G.STATES.TAROT_PACK or G.STATE == G.STATES.SPECTRAL_PACK) and -0.2 or 0},
                    silent = true
                    })
                    G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.06*G.SETTINGS.GAMESPEED, blockable = false, blocking = false, func = function()
                        play_sound('tarot2', 0.76, 0.4);return true end}))
                    play_sound('tarot2', 1, 0.4)
                    card:juice_up(0.3, 0.5)
            return true end }))
        end
    end,

    can_use = function(self, card)
        return true
	end,
}

SMODS.Consumable{
    key = "dice_shard",
    set = "Tarot",
    object_type = "Consumable",
    name = "dice_shard",
    pos = {x = 2, y = 0},
    atlas = "consumables",
    unlocked = true,
    discovered = true,
    cost = 4,

    loc_txt = {
        name = "Dice Shard",
        text={
        "Rerolls selected Card",
        "into a {C:attention}random{} one",
        "of the same {C:attention}type/rarity{}",
        "{C:inactive}(Works on Jokers, Consumeables and Playing Cards){}",
        },
    },

    use = function(self, card, area, copier)
        -- skips `card`: the shard is highlighted itself while being used, so it would target itself
        local target, target_area
        for _, a in ipairs({ G.jokers, G.consumeables, G.hand }) do
            if a and a.cards then
                for _, v in ipairs(a.cards) do
                    if v.highlighted and v ~= card then
                        target = v
                        target_area = a
                        break
                    end
                end
            end
            if target then break end
        end
        if not target then return end

        play_sound("tao_diceshard")

        -- flip -> reroll hidden -> flip back; 0.1s/step so it still finishes if used from a pack
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                target:flip()
                play_sound('tarot2', 0.8, 0.6)
                return true
            end
        }))

        if target_area == G.jokers then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.1,
                func = function()
                    local new_key = Tao.funcs.random_joker_of_rarity(target.config.center.rarity, nil, 'dice_shard')
                    target:set_ability(G.P_CENTERS[new_key], nil, true)
                    target:set_cost()
                    return true
                end
            }))
        elseif target_area == G.consumeables then
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.1,
                func = function()
                    local new_key = Tao.funcs.random_consumable_of_set(target.config.center.set, 'dice_shard')
                    target:set_ability(G.P_CENTERS[new_key], nil, true)
                    target:set_cost()
                    return true
                end
            }))
        else
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.1,
                func = function()
                    local new_suit = pseudorandom_element(SMODS.Suits, pseudoseed('dice_shard_suit'))
                    local new_rank = pseudorandom_element(SMODS.Ranks, pseudoseed('dice_shard_rank'))
                    local new_seal = SMODS.poll_seal({key = 'dice_shard_seal'})
                    local new_edition = SMODS.poll_edition({key = 'dice_shard_edition'})
                    local new_enhance_key = SMODS.poll_enhancement({key = 'dice_shard_enhancement'})
                    assert(SMODS.change_base(target, new_suit.key, new_rank.key))
                    target:set_seal(new_seal, true, true)
                    target:set_edition(new_edition, true, true)
                    target:set_ability(new_enhance_key and G.P_CENTERS[new_enhance_key] or G.P_CENTERS.c_base, nil, true)
                    return true
                end
            }))
        end

        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                target:flip()
                play_sound('tarot2', 1.2, 0.6)
                target:juice_up(0.8, 0.8)
                card_eval_status_text(
                    target, 'extra', nil, nil, nil,
                    { message = localize("k_upgrade_ex"), colour = G.C.SECONDARY_SET.Tarot }
                )
                return true
            end
        }))
        return true
    end,

    can_use = function(self, card)
        local n = 0
        for _, a in ipairs({ G.jokers, G.consumeables, G.hand }) do
            if a and a.cards then
                for _, v in ipairs(a.cards) do
                    if v.highlighted and v ~= card then n = n + 1 end
                end
            end
        end
        return n == 1
    end
}

SMODS.Consumable{
    key = "eternal_dice_shard",
    set = "Spectral",
    object_type = "Consumable",
    name = "eternal_dice_shard",
    pos = {x = 2, y = 1},
    atlas = "consumables",
    unlocked = true,
    discovered = true,
    cost = 6,
    config = {extra = {odds = 4}},

    loc_txt = {
        name = "Eternal Dice Shard",
        text={
        "Rerolls selected Joker into a",
        "{C:attention}higher rarity{} one",
        "{C:inactive}(another Legendary if already Legendary){}",
        "{C:green}#1# in #2#{} chance to destroy it",
        },
    },

    loc_vars = function(self, info_queue, card)
        return {vars = {G.GAME.probabilities.normal, card.ability.extra.odds}}
    end,

    use = function(self, card, area, copier)
        local target
        for _, v in ipairs(G.jokers.cards) do
            if v.highlighted then
                target = v
                break
            end
        end
        if not target then return end

        play_sound("tao_diceshard")
        local rarity = target.config.center.rarity
        local target_rarity = math.min(rarity + 1, 4)

        -- destroy and reroll are exclusive: a proc destroys the joker instead of upgrading it
        if pseudorandom('eternal_dice_shard_destroy') < G.GAME.probabilities.normal / card.ability.extra.odds then
            if not SMODS.is_eternal(target) then
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.1,
                    func = function()
                        target:juice_up(0.8, 0.8)
                        card_eval_status_text(
                            target, 'extra', nil, nil, nil,
                            { message = "Destroyed", colour = G.C.MULT }
                        )
                        return true
                    end
                }))
                G.E_MANAGER:add_event(Event({
                    func = function()
                        target:start_dissolve()
                        return true
                    end
                }))
            end
            return true
        end

        -- flip -> reroll hidden -> flip back; 0.1s/step so it still finishes if used from a pack
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                target:flip()
                play_sound('tarot2', 0.8, 0.6)
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                local new_key = Tao.funcs.random_joker_of_rarity(target_rarity, target.config.center.key, 'eternal_dice_shard')
                target:set_ability(G.P_CENTERS[new_key], nil, true)
                target:set_cost()
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                target:flip()
                play_sound('tarot2', 1.2, 0.6)
                target:juice_up(0.8, 0.8)
                card_eval_status_text(
                    target, 'extra', nil, nil, nil,
                    { message = localize("k_upgrade_ex"), colour = G.C.SECONDARY_SET.Spectral }
                )
                return true
            end
        }))
        return true
    end,

    can_use = function(self, card)
        local n = 0
        for _, v in ipairs(G.jokers.cards) do
            if v.highlighted then n = n + 1 end
        end
        return n == 1
    end,
}

SMODS.Consumable{
    key = "mukbang",
    set = "Spectral",
    object_type = "Consumable",
    name = "mukbang",
    pos = {x = 3, y = 1},
    atlas = "consumables",
    unlocked = true,
    discovered = true,
    cost = 4,
    config = {extra = {edition_key = "e_tao_saliva"}},

    loc_txt = {
        name = "Mukbang",
        text={
        "Removes all modifiers from",
        "{C:attention}1 selected card{},",
        "then applies {C:dark_edition}Saliva{} to it",
        "{C:inactive}(Card must already be modified){}",
        },
    },

    loc_vars = function(self, info_queue, card)
        info_queue[#info_queue + 1] = G.P_CENTERS[card.ability.extra.edition_key]
    end,

    use = function(self, card, area, copier)
        local target
        for _, v in ipairs(G.hand.cards) do
            if v.highlighted then
                target = v
                break
            end
        end
        if not target then return end

        G.E_MANAGER:add_event(Event({
            func = function()
                target:set_seal(nil, true, true)
                target:set_ability(G.P_CENTERS.c_base, nil, true)
                target:set_edition(card.ability.extra.edition_key, true, true)
                target:juice_up(0.5, 0.5)
                card_eval_status_text(
                    target, 'extra', nil, nil, nil,
                    { message = localize("k_upgrade_ex"), colour = G.C.DARK_EDITION }
                )
                return true
            end
        }))
        return true
    end,

    can_use = function(self, card)
        local target
        local n = 0
        for _, v in ipairs(G.hand.cards) do
            if v.highlighted then
                n = n + 1
                target = v
            end
        end
        if n ~= 1 then return false end
        return target.seal ~= nil or target.edition ~= nil or target.config.center.key ~= 'c_base'
    end,
}

SMODS.Consumable{
    key = "cult",
    set = "Tarot",
    object_type = "Consumable",
    name = "cult",
    pos = {x = 3, y = 0},   
    atlas = "consumables",
    unlocked = true,
    discovered = true,
    cost = 4,
    config = { max_highlighted = 2 },

    loc_txt = {
        name = "Cult",
        text = {
            "Converts up to",
            "{C:attention}#1#{} selected cards",
            "to a {V:1}6 of #2#{}",
        },
    },

    loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability and card.ability.consumeable) or self.config
        return { vars = { cfg.max_highlighted, localize('Diamonds', 'suits_plural'), colours = { G.C.SUITS.Diamonds } } }
    end,

    -- same beat as vanilla suit-conversion tarots: flip down, change, flip back, then a beat to look at it
    use = function(self, card, area, copier)
        local targets = {}
        for _, v in ipairs(G.hand.highlighted) do targets[#targets + 1] = v end
        if not targets[1] then return end

        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.4, func = function()
            play_sound('tarot1')
            card:juice_up(0.3, 0.5)
            return true
        end }))

        for i = 1, #targets do
            local percent = 1.15 - (i - 0.999) / (#targets - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.15, func = function()
                targets[i]:flip(); play_sound('card1', percent); targets[i]:juice_up(0.3, 0.3)
                return true
            end }))
        end
        delay(0.2)

        for i = 1, #targets do
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.1, func = function()
                assert(SMODS.change_base(targets[i], 'Diamonds', '6'))
                return true
            end }))
        end

        for i = 1, #targets do
            local percent = 0.85 + (i - 0.999) / (#targets - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.15, func = function()
                targets[i]:flip(); play_sound('tarot2', percent, 0.6); targets[i]:juice_up(0.3, 0.3)
                return true
            end }))
        end

        -- hold on the result so it's readable when used from inside a booster pack
        G.E_MANAGER:add_event(Event({ trigger = 'after', delay = 0.1, func = function()
            G.hand:unhighlight_all()
            return true
        end }))
        delay(0.5)
    end,

    can_use = function(self, card)
        if not (G.hand and G.hand.highlighted) then return false end
        local n = #G.hand.highlighted
        return n >= 1 and n <= card.ability.consumeable.max_highlighted
    end,
}
