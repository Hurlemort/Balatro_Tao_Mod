Tao = {
    funcs = {},
    custom_tables = {},
    images = {},
    events = {},
    assets = {},
}

local mod_path = "" .. SMODS.current_mod.path
Tao.path = mod_path
tao_config = SMODS.current_mod.config

SMODS.current_mod.optional_features = {
    retrigger_joker = true,
	post_trigger = true,
}

-- effect manager for particles etc (idk what this does lmao)
G.effectmanager = {}

-- Load globals
assert(SMODS.load_file("globals.lua"))()

-- Tao joker pools
SMODS.ObjectType({
	key = "tao_joker_pool",
	default = "j_reserved_parking",
	cards = {},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

SMODS.ObjectType({
	key = "tao_joker_pool_legendary",
	default = "j_reserved_parking",
	cards = {},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

SMODS.ObjectType({
	key = "six",
	default = "j_reserved_parking",
	cards = {},
	inject = function(self)
		SMODS.ObjectType.inject(self)
	end,
})

--Load item files
local files = NFS.getDirectoryItems(mod_path .. "items")
for _, file in ipairs(files) do
	if not file:match("%.lua$") then
		file = file .. ".lua"
	end
	print("[TAO] Loading lua file" .. file)
	local f, err = SMODS.load_file("items/" .. file)
	if err then
		error(err) 
	end
	f()
end

--Load lib files
local files = NFS.getDirectoryItems(mod_path .. "libs/")
for _, file in ipairs(files) do
	print("[TAO] Loading lib file " .. file)
	local f, err = SMODS.load_file("libs/" .. file)
	if err then
		error(err)
	end
	f()
end

-- Sans bossfight, fused in from its own old mod; loaded after globals.lua so its hooks wrap ours, freezing our own per-tick stuff during the fight
SANS = SANS or {}
SANS.path = mod_path .. "sans/"

--Load sans SansFight files
local files = NFS.getDirectoryItems(SANS.path .. "SansFight")
for _, file in ipairs(files) do
	if not file:match("%.lua$") then
		file = file .. ".lua"
	end
	print("[TAO][SANS] Loading lua file " .. file)
	local f, err = SMODS.load_file("sans/SansFight/" .. file)
	if err then
		error(err)
	end
	f()
end