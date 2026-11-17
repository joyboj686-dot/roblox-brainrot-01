-- BRAINROT RUSH: shared constants, roster and plaza layout.
-- Single source of truth for the game world, the economy and the roster.
-- Server, client and the screenshot renderer all read from this one module.

local Config = {}

-- Rarity ladder, cheapest/common first. Higher index = rarer = pricier + faster.
Config.RARITIES = {
	{ name = "Common", color = Color3.fromRGB(150, 160, 170) },
	{ name = "Rare", color = Color3.fromRGB(70, 140, 220) },
	{ name = "Epic", color = Color3.fromRGB(170, 70, 220) },
	{ name = "Legendary", color = Color3.fromRGB(230, 170, 30) },
	{ name = "Mythic", color = Color3.fromRGB(230, 70, 110) },
	{ name = "Brainrot God", color = Color3.fromRGB(30, 200, 220) },
}

-- 12 original absurd characters. Each: name, body colour, accent, rarity index,
-- cost (coins to buy), rate ($/s earned while on a pad).
Config.ROSTER = {
	{ name = "Sir Barksalot", color = Color3.fromRGB(210, 160, 90), accent = Color3.fromRGB(40, 40, 40), rarity = 1, cost = 30, rate = 5 },
	{ name = "Captain Croissant", color = Color3.fromRGB(230, 170, 80), accent = Color3.fromRGB(160, 100, 40), rarity = 1, cost = 40, rate = 6 },
	{ name = "DJ Pickle", color = Color3.fromRGB(130, 190, 90), accent = Color3.fromRGB(30, 120, 40), rarity = 2, cost = 90, rate = 12 },
	{ name = "Professor Noodle", color = Color3.fromRGB(240, 200, 140), accent = Color3.fromRGB(220, 160, 60), rarity = 2, cost = 120, rate = 16 },
	{ name = "Turbo Toilet", color = Color3.fromRGB(230, 230, 240), accent = Color3.fromRGB(40, 60, 80), rarity = 3, cost = 260, rate = 34 },
	{ name = "Banana Knight", color = Color3.fromRGB(250, 220, 70), accent = Color3.fromRGB(150, 120, 20), rarity = 3, cost = 320, rate = 42 },
	{ name = "Grandma Glizzy", color = Color3.fromRGB(240, 150, 150), accent = Color3.fromRGB(170, 60, 60), rarity = 3, cost = 400, rate = 52 },
	{ name = "Lord Llama Latte", color = Color3.fromRGB(230, 190, 150), accent = Color3.fromRGB(140, 100, 60), rarity = 4, cost = 850, rate = 105 },
	{ name = "Agent Avocado", color = Color3.fromRGB(90, 160, 80), accent = Color3.fromRGB(30, 70, 30), rarity = 4, cost = 1050, rate = 130 },
	{ name = "King Ketchup", color = Color3.fromRGB(210, 40, 40), accent = Color3.fromRGB(130, 20, 20), rarity = 5, cost = 2200, rate = 260 },
	{ name = "Quantum Quokka", color = Color3.fromRGB(120, 180, 230), accent = Color3.fromRGB(40, 80, 150), rarity = 5, cost = 2900, rate = 340 },
	{ name = "Baron von Burrito", color = Color3.fromRGB(200, 170, 120), accent = Color3.fromRGB(120, 90, 50), rarity = 6, cost = 5200, rate = 620 },
}

-- Mutation multipliers, rolled when a brainrot spawns on the belt.
Config.MUTATIONS = {
	{ name = "", mult = 1, weight = 100 },
	{ name = "GOLDEN", mult = 2, weight = 20 },
	{ name = "RAINBOW", mult = 5, weight = 7 },
	{ name = "VOID", mult = 10, weight = 2 },
}

-- Economy.
Config.START_COINS = 100
Config.SELL_RATE = 0.5
Config.REBIRTH_NEED = 1000000 -- lifetime earnings to unlock a rebirth
Config.REBIRTH_MULT = 2 -- permanent x2 earnings multiplier per rebirth
Config.TICK_INTERVAL = 1 -- money tick in seconds

-- The BRAINROT WAVE.
Config.WAVE_INTERVAL = 90 -- seconds between waves
Config.WAVE_WARNING = 10 -- seconds of warning before a wave sweeps
Config.WAVE_PENALTY = 0.25 -- lose 25% of coins if caught outside the safe zone
Config.WAVE_MIN_INTERVAL = 45 -- interval floor as waves get faster

-- Stealing.
Config.LOCK_DURATION = 30 -- seconds a base lock lasts once set
Config.LOCK_COOLDOWN = 60 -- seconds before the lock can be set again

-- Conveyor.
Config.BELT_SPEED = 3 -- studs per second base
Config.BELT_SPEED_GROWTH = 0.08 -- belt speeds up over time

-- ---------------------------------------------------------------------------
-- PLAZA LAYOUT. One data table describing the whole bright 3D world.
-- The server (WorldBuilder) builds real parts from it; the screenshot renderer
-- draws a faithful view from the same numbers.
-- Coordinates are in studs; X to the right, Z toward the viewer (screen up).
-- ---------------------------------------------------------------------------
Config.PLAZA = {
	floor = {
		position = Vector3.new(0, 0, 0),
		size = Vector3.new(200, 1, 140),
		color = Color3.fromRGB(210, 230, 150), -- bright pale grass
	},
	-- The Brainrot Belt: a raised loop of tiles where brainrots ride past.
	belt = {
		width = 10,
		height = 2,
		color = Color3.fromRGB(80, 80, 90),
		railColor = Color3.fromRGB(60, 60, 70),
		-- Loop of waypoints (X, Z). Brainrots travel along them in order.
		waypoints = {
			Vector3.new(-60, 2, -50),
			Vector3.new(60, 2, -50),
			Vector3.new(60, 2, -10),
			Vector3.new(0, 2, -10),
			Vector3.new(-60, 2, -10),
		},
	},
	-- The player's base: a raised plot with 8 pads. Safe zone for the wave.
	base = {
		position = Vector3.new(0, 0, 60),
		size = Vector3.new(70, 2, 40),
		color = Color3.fromRGB(120, 200, 120),
		padColor = Color3.fromRGB(200, 235, 200),
		pads = {
			Vector3.new(-24, 0, 52),
			Vector3.new(-8, 0, 52),
			Vector3.new(8, 0, 52),
			Vector3.new(24, 0, 52),
			Vector3.new(-24, 0, 68),
			Vector3.new(-8, 0, 68),
			Vector3.new(8, 0, 68),
			Vector3.new(24, 0, 68),
		},
		-- Safe-zone box the player must stand inside when the wave sweeps.
		safe = { size = Vector3.new(70, 20, 40) },
	},
	-- Decorative trees/rocks around the plaza.
	props = {
		{ kind = "tree", pos = Vector3.new(-70, 0, -60), color = Color3.fromRGB(90, 180, 90) },
		{ kind = "tree", pos = Vector3.new(70, 0, -60), color = Color3.fromRGB(90, 180, 90) },
		{ kind = "rock", pos = Vector3.new(-70, 0, 60), color = Color3.fromRGB(150, 150, 150) },
		{ kind = "rock", pos = Vector3.new(70, 0, 60), color = Color3.fromRGB(150, 150, 150) },
	},
	-- Where the player spawns.
	spawn = Vector3.new(0, 3, 62),
	-- Rival base (steal target in solo play).
	rival = {
		position = Vector3.new(0, 0, -85),
		size = Vector3.new(50, 2, 30),
		color = Color3.fromRGB(200, 130, 130),
		pads = {
			Vector3.new(-12, 0, -90),
			Vector3.new(0, 0, -90),
			Vector3.new(12, 0, -90),
		},
	},
}

return Config