-- WaveService: THE BRAINROT WAVE. Tracks the timer, warns 10s ahead,
-- sweeps the map, and takes 25% of coins from anyone outside the safe zone.

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WaveService = {}
WaveService.events = {} -- { onWarning, onWaveStart, onWaveEnd }

local state = {
	timeToWave = Config.WAVE_INTERVAL,
	waveCount = 0,
	active = false,
}

function WaveService.timer()
	return state.timeToWave
end

function WaveService.count()
	return state.waveCount
end

-- Player is safe if their torso is inside the base safe box.
local function inSafeZone(pos)
	local pl = Config.PLAZA
	local safe = pl.base.safe
	local center = pl.base.position + Vector3.new(0, 12, 0)
	local half = safe.size / 2
	local d = (pos - center)
	return math.abs(d.X) <= half.X and math.abs(d.Z) <= half.Z and pos.Y > -5
end

-- Each tick. dt seconds pass; returns events fired for the client.
function WaveService.step(dt, players, applyPenalty)
	if state.active then
		return "none"
	end
	local before = state.timeToWave
	state.timeToWave -= dt
	-- Fire warning when we cross into the warning window.
	if before > Config.WAVE_WARNING and state.timeToWave <= Config.WAVE_WARNING then
		return "warning"
	end
	if state.timeToWave <= 0 then
		WaveService.triggerWave(players, applyPenalty)
		return "wave"
	end
	return "none"
end

function WaveService.triggerWave(players, applyPenalty)
	state.waveCount += 1
	-- Determine the next interval (waves speed up each cycle).
	local interval = math.max(
		Config.WAVE_MIN_INTERVAL,
		Config.WAVE_INTERVAL - (state.waveCount - 1) * Config.WAVE_SHRINK
	)
	-- Apply the coin penalty to any player caught outside the safe zone.
	for _, player in ipairs(players) do
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root and not inSafeZone(root.Position) then
				applyPenalty(player)
			end
		end
	end
	state.timeToWave = interval
	state.active = true
end

-- The wave is a transient "sweep" that ends after a short moment.
function WaveService.endSweep()
	state.active = false
end

return WaveService