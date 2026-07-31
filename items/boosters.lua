-- Booster Atlas
SMODS.Atlas{
    key = 'boosters',
    path = 'boosters.png',
    px = 71,
    py = 96,
}

SMODS.Sound({
    key = "taomusic", 
    path = "taomusic.ogg",
    pitch = 1,
    volume = 1,
    select_music_track = function()
        if G.STATE == G.STATES.SMODS_BOOSTER_OPENED then
            if G.pack_cards
                and G.pack_cards.cards
                and G.pack_cards.cards[1]
                and G.pack_cards.cards[1].config
                and G.pack_cards.cards[1].config.center
                and G.pack_cards.cards[1].config.center.mod
                and G.pack_cards.cards[1].config.center.mod.id 
                and G.pack_cards.cards[1].config.center.mod.id == "tao" then
		        return true 
            end
        end
	end,
})

-- Booster Pack 1
SMODS.Booster{
    key = 'tao_pack',
    group_key = "k_tao_booster_group",
    atlas = 'boosters', 
    pos = { x = 0, y = 0 },
    discovered = true,
    loc_txt= {
    name = 'Tao Pack',
        text = {
            "Pick {C:attention}#1#{} card out",
            "of {C:attention}#2#{} Tao jokers!",
            "{C:inactive}({}{X:legendary,C:white}Legendary{}{C:inactive} Jokers excluded){}"
            },
        group_name = {"Tao Pack"},
    },
    
    draw_hand = false,
    config = {
        extra = 3,
        choose = 1, 
    },

    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.choose, card.ability.extra } }
    end,

    weight = 1,
    cost = 4,
    kind = "TaoPack",
    
    create_card = function(self, card, i)
        ease_background_colour(HEX("a348e8"))
        return SMODS.create_card({
            set = "tao_joker_pool",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
        })
    end,
    select_card = 'jokers',

    in_pool = function() return true end
}

-- Booster Pack 2
SMODS.Booster{
    key = 'menacing_tao_pack',
    group_key = "k_tao_booster_group",
    atlas = 'boosters', 
    pos = { x = 1, y = 0 },
    discovered = true,
    loc_txt= {
        name = 'Menacing Tao Pack',
        text = {
            "Pick {C:attention}#1#{} card out",
            "of {C:attention}#2#{} Tao jokers!",
            "{C:inactive}({}{X:legendary,C:white}Legendary{}{C:inactive} Jokers excluded){}"
        },
        group_name = {"Tao Pack"},
    },
    
    draw_hand = false,
    config = {
        extra = 5,
        choose = 1, 
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.choose, card.ability.extra } }
    end,
    weight = 1,
    cost = 6,
    kind = "TaoPack",
    
    create_card = function(self, card, i)
        ease_background_colour(HEX("a348e8"))
        return SMODS.create_card({
            set = "tao_joker_pool",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
        })
    end,
    select_card = 'jokers',

    in_pool = function() return true end
}

-- Booster Pack 3
SMODS.Booster{
    key = 'skibidi_tao_pack',
    group_key = "k_tao_booster_group",
    atlas = 'boosters', 
    pos = { x = 2, y = 0 },
    discovered = true,
    loc_txt= {
        name = 'Skibidi Tao Pack',
        text = {
            "Pick {C:attention}#1#{} card out",
            "of {C:attention}#2#{} Tao jokers!",
            "{C:inactive}({}{X:legendary,C:white}Legendary{}{C:inactive} Jokers excluded){}"
        },
        group_name = {"Tao Pack"},
    },
    
    draw_hand = false,
    config = {
        extra = 5,
        choose = 2, 
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.choose, card.ability.extra } }
    end,
    weight = 0.66,
    cost = 8,
    kind = "TaoPack",
    
    create_card = function(self, card, i)
        ease_background_colour(HEX("a348e8"))
        return SMODS.create_card({
            set = "tao_joker_pool",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
        })
    end,
    select_card = 'jokers',

    in_pool = function() return true end
}

-- Booster Pack 4
SMODS.Booster{
    key = 'dumbass_pack',
    group_key = "k_tao_booster_group",
    atlas = 'boosters', 
    pos = { x = 3, y = 0 },
    discovered = true,
    loc_txt= {
        name = 'Dumbass Pack',
        text = {
            "Pick {C:attention}#1#{} card out",
            "of {C:attention}#2#{} Tao jokers!",
        },
        group_name = {"Tao Pack"},
    },
    
    draw_hand = false,
    config = {
        extra = 1,
        choose = 1, 
    },
    loc_vars = function(self, info_queue, card)
        return { vars = { card.ability.choose, card.ability.extra } }
    end,
    weight = 1,
    cost = 4,
    kind = "TaoPack",
    
    create_card = function(self, card, i)
        ease_background_colour(HEX("a348e8"))
        return SMODS.create_card({
            set = "tao_joker_pool_legendary",
            area = G.pack_cards,
            skip_materialize = true,
            soulable = true,
        })
    end,
    select_card = 'jokers',

    in_pool = function() return true end
}