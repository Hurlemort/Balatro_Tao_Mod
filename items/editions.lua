-- Saliva: drifting Voronoi shader, sharp at centers, blurred at rims
SMODS.Sound({ key = "saliva", path = "saliva.ogg" })

SMODS.Shader({
    key = "saliva",
    path = "saliva.fs",
})

SMODS.Edition({
    key = "saliva",
    shader = "saliva",
    unlocked = true,
    discovered = true,
    in_shop = true,
    weight = 5,
    extra_cost = 3,
    apply_to_float = true,
    sound = { sound = "tao_saliva", per = 1.1, vol = 0.7 },

    loc_txt = {
        name = "Saliva",
        label = "Saliva",
        text = {
            "Gives {C:mult}+#1#{} Mult",
            "{C:inactive}({}{C:mult}+#2#^n{}{C:inactive} Mult where {}{C:attention}n{}",
            "{C:inactive}is the number of Saliva card(s) owned){}",
        },
    },

    loc_vars = function(self, info_queue, card)
        local base = Tao.funcs.saliva_base()
        local n = Tao.funcs.count_saliva_cards()
        return { vars = { base ^ n, base} }
    end,

    calculate = function(self, card, context)
        if
            (
                context.edition
                and context.cardarea == G.jokers
                and card.config.trigger
            ) or (
                context.main_scoring
                and context.cardarea == G.play
            )
        then
            local base = Tao.funcs.saliva_base()
            local n = Tao.funcs.count_saliva_cards()
            local amount = base ^ n
            return {
                mult = amount,
            }
        end
        if context.joker_main then
            card.config.trigger = true
        end
        if context.after then -- idk what this does...
            card.config.trigger = nil
        end
    end,
})
