-- BRAINROT RUSH server: game state machine. Owns the loop, fires RemoteEvents
-- to clients, and delegates each job to its module.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.Parent.shared.Config)
local WorldBuilder = require(script.WorldBuilder)
local Economy = require(script.EconomyService)
local Brainrot = require(script.BrainrotService)
local Wave = require(script.WaveService)
local Steal = require(script.StealService)

-- RemoteEvents published to clients.
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local updateEvent = makeRemote("UpdateState")
local waveEvent = makeRemote("WaveEvent")
local buyEvent = makeRemote("BuyResult")
local stealEvent = makeRemote("StealResult")

-- Build the world.
WorldBuilder.build(workspace)
Brainrot.beltPath = Config.PLAZA.belt.waypoints

-- Track per-player owned brainrots.
local owned = {} -- [player] = list of brainrot entries on their pads

local function owns(player)
	local list = owned[player] or {}
	owned[player] = list
	return list
end

-- Spawn some brainrots onto the belt at start.
local elapsed = 0
for i = 1, 6 do
	local def = Brainrot.rollRoster(0)
	local mut = Brainrot.rollMutation()
	Brainrot.spawnBelt(def, mut, Config.PLAZA.belt.waypoints)
end

-- Purchase handler: buy a brainrot off the belt.
buyEvent.OnServerEvent:Connect(function(player, index)
	local entry = Brainrot.brainrots[index]
	if not entry or entry.bought then
		return
	end
	local padPositions = Config.PLAZA.base.pads
	local ok, reason = Brainrot.buy(entry, player, padPositions, owns(player), function(cost)
		return Economy.spend(player, cost)
	end)
	if ok then
		local list = owns(player)
		list[#list + 1] = entry
		player:SetAttribute("coins", Economy.coins(player))
	end
	buyEvent:FireClient(player, ok, reason)
end)

-- Spawn a player with a colourful block body at the spawn point.
local function spawnCharacter(player)
	local char = Instance.new("Model")
	char.Name = "Character"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.Size = Vector3.new(2, 2, 2)
	root.Position = Config.PLAZA.spawn
	root.Transparency = 1
	root.Parent = char
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1.2, 2)
	head.Color = Color3.fromRGB(255, 220, 120)
	head.CFrame = root.CFrame * CFrame.new(0, 2, 0)
	head.Parent = char
	player.Character = char
	return char
end

Players.PlayerAdded:Connect(function(player)
	spawnCharacter(player)
	player:SetAttribute("coins", Config.START_COINS)
end)

-- STEAL + SELL handlers.
local sellEvent = makeRemote("SellResult")
local lockEvent = makeRemote("LockResult")

-- Sell: client tells us the brainrot index; we credit half its cost.
sellEvent.OnServerEvent:Connect(function(player, index)
	local entry = Brainrot.brainrots[index]
	if not entry or not entry.bought or entry.owner ~= player then
		return
	end
	local list = owns(player)
	for i, br in ipairs(list) do
		if br == entry then
			table.remove(list, i)
			break
		end
	end
	local value = Brainrot.sell(entry)
	Economy.add(player, value, false)
	player:SetAttribute("coins", Economy.coins(player))
	sellEvent:FireClient(player, value)
end)

-- Lock: set the base lock to block stealing.
lockEvent.OnServerEvent:Connect(function(player)
	local ok = Steal.setLock(player)
	lockEvent:FireClient(player, ok)
end)

-- The main loop: belt moves, brainrots spawn, money ticks, waves fire.
local moneyAccum = 0

RunService.Heartbeat:Connect(function(dt)
	elapsed += dt

	-- Advance every unbought belt brainrot.
	local speed = Config.BELT_SPEED + Config.BELT_SPEED_GROWTH * elapsed
	for _, entry in ipairs(Brainrot.brainrots) do
		if not entry.bought and not Steal.carriedEntry(entry.owner) then
			Brainrot.advance(entry, speed, dt)
		end
	end

	-- Periodically spawn a fresh brainrot onto the belt.
	if math.random() < dt * 0.5 then
		local def = Brainrot.rollRoster(elapsed)
		local mut = Brainrot.rollMutation()
		Brainrot.spawnBelt(def, mut, Config.PLAZA.belt.waypoints)
	end

	-- Money tick: every TICK_INTERVAL, add each pad brainrot's $/s.
	moneyAccum += dt
	if moneyAccum >= Config.TICK_INTERVAL then
		moneyAccum -= Config.TICK_INTERVAL
		for player, list in pairs(owned) do
			local gain = 0
			for _, br in ipairs(list) do
				gain += Economy.effectiveRate(player, br.def.rate, br.mutation.mult)
			end
			if gain > 0 then
				Economy.add(player, gain, true)
			end
			player:SetAttribute("coins", Economy.coins(player))
			player:SetAttribute("rate", gain)
		end
	end

	-- Wave step.
	local players = Players:GetPlayers()
	local waveOutcome = Wave.step(dt, players, function(player)
		-- penalty: lose 25% of current coins
		local coins = Economy.coins(player)
		local lost = math.floor(coins * Config.WAVE_PENALTY)
		Economy.add(player, -lost, false)
		player:SetAttribute("coins", Economy.coins(player))
		waveEvent:FireClient(player, "penalty", lost)
	end)
	if waveOutcome == "warning" then
		for _, p in ipairs(players) do
			waveEvent:FireClient(p, "warning", Wave.timer())
		end
	elseif waveOutcome == "wave" then
		for _, p in ipairs(players) do
			waveEvent:FireClient(p, "wave", Wave.count())
		end
	end

	-- Broadcast state to all clients.
	updateEvent:FireAllClients({
		coins = 0, -- per-player, set below
		elapsed = elapsed,
		waveTimer = Wave.timer(),
		waveCount = Wave.count(),
		beltSpeed = speed,
	})
end)

-- Clean up carried state on player leave.
Players.PlayerRemoving:Connect(function(player)
	Steal.drop(player)
	owned[player] = nil
end)