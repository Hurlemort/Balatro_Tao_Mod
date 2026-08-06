-- Custom SMODS achievements

SMODS.Achievement({
    key = "beat_sans",
    loc_txt = {
        name = "LV 20",
        description = { "FIGHT Sans till the end"},
    },
    unlock_condition = function(self, args)
        if args.type == self.key then return true end
    end,
})

SMODS.Achievement({
    key = "spare_sans",
    loc_txt = {
        name = "The Jimbo Parable",
        description = { "SPARE Sans"},
    },
    unlock_condition = function(self, args)
        if args.type == self.key then return true end
    end,
})
