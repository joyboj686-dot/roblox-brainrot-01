-- EconomyService: coins, $/s ticking, sell, rebirth multiplier.
-- One job: own every player's money state and the earnings tick.

local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.shared.Config)

local EconomyService = {}
EconomyService.data = {} -- [player] = { coins, lifetime, rebirths }

local function get(player)
	local d = EconomyService.data[player]
	if not d then
		d = { coins = Config.START_COINS, lifetime = 0, rebirths = 0 }
		EconomyService.data[player] = d
	end
	return d
end

-- Add coins; lifetime only counts coins actually earned (not spent), and
-- is used toward the rebirth threshold.
function EconomyService.add(player, amount, countsLifetime)
	local d = get(player)
	d.coins += amount
	if countsLifetime then
		d.lifetime += amount
	end
	return d.coins
end

function EconomyService.spend(player, amount)
	local d = get(player)
	if d.coins < amount then
		return false
	end
	d.coins -= amount
	return true
end

function EconomyService.coins(player)
	return get(player).coins
end

-- The $/s for one brainrot = roster.rate * mutation.mult * rebirth multiplier.
function EconomyService.effectiveRate(player, rosterRate, mutationMult)
	local d = get(player)
	local mult = (Config.REBIRTH_MULT ^ d.rebirths)
	return rosterRate * mutationMult * mult
end

-- Sell a brainrot back for 50% of its cost.
function EconomyService.sellValue(cost)
	return math.floor(cost * Config.SELL_RATE)
end

function EconomyService.rebirth(player)
	local d = get(player)
	if d.lifetime < Config.REBIRTH_NEED then
		return false
	end
	d.rebirths += 1
	d.lifetime = 0
	d.coins = Config.START_COINS
	return true
end

return EconomyService