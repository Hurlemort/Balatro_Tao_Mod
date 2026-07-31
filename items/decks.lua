SMODS.Atlas{
    key = "decks",
    path = "decks.png",
    px = 71,
    py = 95
}

-- raw weights, not percentages - poll_rarity normalises by their total (vanilla: .7/.25/.05/0)
LOST_DECK_RARITY_WEIGHTS = {
    Common    = 0.7,
    Uncommon  = 0.25,
    Rare      = 0.10,
    Legendary = 0.02,
}

local function tao_is_lost_deck()
    local center = G.GAME and G.GAME.selected_back and G.GAME.selected_back.effect
        and G.GAME.selected_back.effect.center
    return center ~= nil and center.key == "b_tao_lost"
end

-- get_weight runs on every roll, so gating on the deck leaves other decks untouched
for rarity_key, lost_weight in pairs(LOST_DECK_RARITY_WEIGHTS) do
    SMODS.Rarity:take_ownership(rarity_key, {
        pools = (rarity_key == "Legendary") and { ["Joker"] = true } or nil, -- only Legendary is missing from the Joker pool
        get_weight = function(self, weight, object_type)
            if object_type and object_type.key == "Joker" and tao_is_lost_deck() then
                return lost_weight
            end
            return weight
        end,
    }, true)
end

-- spectral packs default to 0.3 weight (0.07 Mega) vs ~4 for Arcana/Celestial
LOST_DECK_SPECTRAL_PACK_MULT = 4

SMODS.Booster:take_ownership_by_kind("Spectral", {
    get_weight = function(self)
        local w = self.weight or 1
        if tao_is_lost_deck() then return w * LOST_DECK_SPECTRAL_PACK_MULT end
        return w
    end,
}, true)

-- 1 hand, eternal ED6, custom rarity weights (legendaries in shop), spectral cards + packs
SMODS.Back{
    key = "lost",
    pos = {x = 0, y = 0},
    atlas = "decks",
    unlocked = true,
    discovered = true,
    config = {
        hands = -3,        -- base starting hands is 4
        spectral_rate = 2, -- same value Ghost Deck uses; vanilla Back:apply reads this (default is 0)
    },

    loc_txt = {
        name = "Lost Deck",
        text = {
            "Starts with {C:attention}1{} hand",
            "and an {C:mult}Eternal{} {C:dark_edition}Eternal D6{}",
            "{C:legendary}Legendary{} Jokers and {C:spectral}Spectral{} cards",
            "can appear in the {C:attention}shop{}",
            "{C:attention}Higher{} chances for {C:attention,E:1}Rare{} Jokers",
        },
    },

    apply = function(self)
        G.E_MANAGER:add_event(Event({
            func = function()
                local center_key
                for key, center in pairs(G.P_CENTERS) do
                    if center.set == 'Joker' and center.original_key == 'ED6' then
                        center_key = key
                        break
                    end
                end
                if center_key then
                    local card = create_card('Joker', G.jokers, nil, nil, nil, nil, center_key, 'deck')
                    card:add_to_deck()
                    G.jokers:emplace(card)
                    card:set_eternal(true)
                    card:start_materialize() -- tuff function name
                end
                return true
            end
        }))
    end,
}
