-- StealService: STEALING. Players can carry a rival brainrot home, but a base
-- LOCK blocks stealing for 30s (cooldown 60s), and a stolen brainrot can be
-- re-stolen. One job: honest steal + lock state.

local Players = game:GetService("Players")
local Config = require(script.Parent.Parent.shared.Config)

local StealService = {}

-- Per-player lock state.
StealService.locks = {} -- [player] = { lockedUntil, cooldownUntil }
StealService.carried = {} -- [player] = brainrot entry being carried

local function lockState(player)
	local l = StealService.locks[player]
	if not l then
		l = { lockedUntil = 0, cooldownUntil = 0 }
		StealService.locks[player] = l
	end
	return l
end

function StealService.isLocked(player)
	local l = lockState(player)
	return os.clock() < l.lockedUntil
end

function StealService.lockCooldownLeft(player)
	local l = lockState(player)
	return math.max(0, l.cooldownUntil - os.clock())
end

-- Set the base lock. Only possible off cooldown. Returns true if set.
function StealService.setLock(player)
	local l = lockState(player)
	local now = os.clock()
	if now < l.cooldownUntil then
		return false
	end
	l.lockedUntil = now + Config.LOCK_DURATION
	l.cooldownUntil = now + Config.LOCK_DURATION + Config.LOCK_COOLDOWN
	return true
end

-- Can a player steal from a locked base? The player here is the *owner* whose
-- base lock matters (the defender). Locking blocks *others* from stealing.
function StealService.canStealFrom(owner)
	return not StealService.isLocked(owner)
end

-- Start carrying a brainrot. Returns false if the player already carries one.
function StealService.pickup(player, entry)
	if StealService.carried[player] then
		return false
	end
	StealService.carried[player] = entry
	entry.owner = player -- they now own (carry) it
	return true
end

function StealService.carriedEntry(player)
	return StealService.carried[player]
end

-- Drop the carried brainrot (e.g. it is placed on home pad).
function StealService.drop(player)
	StealService.carried[player] = nil
end

return StealService