-- BRAINROT RUSH client: HUD, overlays, WASD + Space input, camera, feedback.
-- Reads state broadcast by the server via the UpdateState RemoteEvent.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local player = Players.LocalPlayer

-- Grab the server's remote folder.
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local updateEvent = remotes:WaitForChild("UpdateState")
local waveEvent = remotes:WaitForChild("WaveEvent")
local buyEvent = remotes:WaitForChild("BuyResult")
local sellEvent = remotes:WaitForChild("SellResult")
local lockEvent = remotes:WaitForChild("LockResult")
local stealEvent = remotes:WaitForChild("StealResult")

-- ---------------------------------------------------------------------------
-- Input: WASD + Space (read key state so Roblox's camera scripts don't eat it).
-- ---------------------------------------------------------------------------
local MOVE_SPEED = 22
local JUMP_SPEED = 22
local GRAVITY = 40
local velocity = Vector3.new(0, 0, 0)
local grounded = true

-- Move the local player's character block.
local function applyMovement(dt)
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local move = Vector3.new(0, 0, 0)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += Vector3.new(0, 0, -1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then move += Vector3.new(0, 0, 1) end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(-1, 0, 0) end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(1, 0, 0) end

	local pos = root.Position
	if move.Magnitude > 0 then
		move = move.Unit * MOVE_SPEED * dt
		pos += move
	end

	-- Jump: launch up when on the ground and Space pressed.
	if grounded and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		velocity = Vector3.new(0, JUMP_SPEED, 0)
		grounded = false
	end
	-- Apply gravity.
	velocity = Vector3.new(0, velocity.Y - GRAVITY * dt, 0)
	pos += Vector3.new(0, velocity.Y * dt, 0)

	-- Keep above the floor (floor top at Y = 1; keep the character just above).
	if pos.Y < 3 then
		pos = Vector3.new(pos.X, 3, pos.Z)
		velocity = Vector3.new(0, 0, 0)
		grounded = true
	end

	root.Position = pos
end

RunService.RenderStepped:Connect(function(dt)
	applyMovement(dt)
	-- Follow the character with the camera.
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			Camera.CFrame = CFrame.new(root.Position + Vector3.new(0, 10, 16), root.Position)
		end
	end
end)

-- ---------------------------------------------------------------------------
-- HUD: coins, $/s, rebirth, wave timer, lock, next-tier hint. Top-left corner.
-- ---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 10
gui.Parent = player:WaitForChild("PlayerGui")

local function makeLabel(parent, name, pos, size, text, color, fontSize)
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = pos
	l.Size = size
	l.Text = text
	l.TextColor3 = color
	l.TextSize = fontSize
	l.BackgroundTransparency = 1
	l.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextStrokeTransparency = 0.4
	l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	l.Parent = parent
	return l
end

local coinsLabel = makeLabel(gui, "Coins", UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.3, 0.05),
	"$0", Color3.fromRGB(255, 220, 60), 26)
local rateLabel = makeLabel(gui, "Rate", UDim2.fromScale(0.02, 0.075), UDim2.fromScale(0.3, 0.04),
	"$0/s", Color3.fromRGB(120, 255, 120), 18)
local rebirthLabel = makeLabel(gui, "Rebirths", UDim2.fromScale(0.02, 0.12), UDim2.fromScale(0.3, 0.04),
	"Rebirths: 0 (x1)", Color3.fromRGB(150, 180, 255), 16)
local waveLabel = makeLabel(gui, "Wave", UDim2.fromScale(0.02, 0.165), UDim2.fromScale(0.3, 0.04),
	"Wave in 90s", Color3.fromRGB(255, 160, 160), 16)
local lockLabel = makeLabel(gui, "Lock", UDim2.fromScale(0.02, 0.21), UDim2.fromScale(0.3, 0.04),
	"Base lock: READY (click B)", Color3.fromRGB(200, 200, 220), 14)
local hintLabel = makeLabel(gui, "Hint", UDim2.fromScale(0.02, 0.255), UDim2.fromScale(0.3, 0.05),
	"Next: save $30", Color3.fromRGB(255, 255, 255), 14)

-- State: keep the HUD in sync with the server broadcasts.
local state = {
	coins = Config.START_COINS,
	rate = 0,
	waveTimer = Config.WAVE_INTERVAL,
	waveCount = 0,
	elapsed = 0,
	lockedUntil = 0,
}

updateEvent.OnClientEvent:Connect(function(data)
	state.elapsed = data.elapsed
	state.waveTimer = data.waveTimer
	state.waveCount = data.waveCount
	local att = player:GetAttribute("coins")
	if att then
		state.coins = att
	end
	local attRate = player:GetAttribute("rate")
	if attRate then
		state.rate = attRate
	end
	-- Update the labels.
	coinsLabel.Text = "$" .. math.floor(state.coins)
	rateLabel.Text = "$" .. math.floor(state.rate) .. "/s"
	local reb = player:GetAttribute("rebirths") or 0
	local m = Config.REBIRTH_MULT ^ reb
	rebirthLabel.Text = "Rebirths: " .. tostring(reb) .. " (x" .. m .. ")"
	waveLabel.Text = "Wave " .. (state.waveCount + 1) .. " in " .. math.ceil(state.waveTimer) .. "s"
	-- Next tier hint.
	updateHint()
end)

-- Figure out the next affordable roster tier for the HUD hint.
local function updateHint()
	local nextDef = nil
	for _, def in ipairs(Config.ROSTER) do
		if def.cost > state.coins then
			nextDef = def
			break
		end
	end
	if nextDef then
		hintLabel.Text = "Next: " .. nextDef.name .. " — save $" .. nextDef.cost
	else
		hintLabel.Text = "All brainrots bought! Next: rebirth"
	end
end

-- Click a belt brainrot to buy it, or a placed one to sell it.
local Mouse = nil
local function raycastToThing()
	local char = player.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local dir = (Camera.CFrame.LookVector * 60)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { workspace:FindFirstChild("Base"), workspace:FindFirstChild("Belt"), workspace:FindFirstChild("RivalBase") }
	local result = workspace:Raycast(root.Position + Vector3.new(0, 3, 0), dir, params)
	return result
end

-- The brainrot model parts are clickable. They carry a BrIndex attribute
-- into the server's brainrot list. Left-click = buy/sell; right-click = steal.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local isLeft = input.UserInputType == Enum.UserInputType.MouseButton1
	local isRight = input.UserInputType == Enum.UserInputType.MouseButton2
	if not (isLeft or isRight) then return end
	local result = raycastToThing()
	if not result then return end
	local hit = result.Instance
	local model = hit:FindFirstAncestorOfClass("Model")
	if not model then return end
	local idx = model:GetAttribute("BrIndex")
	if idx then
		if isRight then
			stealEvent:FireServer(idx)
		else
			buyEvent:FireServer(idx)
		end
	end
end)

-- Feedback: transient status message at the bottom.
local statusLabel = makeLabel(gui, "Status", UDim2.fromScale(0.5, 0.85), UDim2.fromScale(0.6, 0.06),
	"", Color3.fromRGB(255, 255, 255), 18)
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.AnchorPoint = Vector2.new(0.5, 0.5)

local function say(msg)
	statusLabel.Text = msg
	task.delay(3, function()
		if statusLabel.Text == msg then
			statusLabel.Text = ""
		end
	end)
end

buyEvent.OnClientEvent:Connect(function(ok, reason)
	if ok then
		say("Bought a brainrot!")
	elseif reason == "NoFreePad" then
		say("No free pad on your base!")
	elseif reason == "TooPoor" then
		say("Not enough coins!")
	end
end)

lockEvent.OnClientEvent:Connect(function(ok)
	if ok then
		say("Base locked — stealers blocked for 30s!")
		lockLabel.Text = "Base lock: ACTIVE"
	else
		say("Lock on cooldown.")
	end
end)

stealEvent.OnClientEvent:Connect(function(ok, reason)
	if ok then
		say("You stole a brainrot — carry it home!")
	elseif reason == "Locked" then
		say("That base is locked!")
	elseif reason == "AlreadyCarrying" then
		say("You are already carrying one!")
	elseif reason == "NotPlaced" then
		say("Only steal placed brainrots!")
	end
end)

-- Wave events: warning banner and penalty notice.
local warning = makeLabel(gui, "Warning", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.6, 0.1),
	"", Color3.fromRGB(255, 90, 60), 34)
warning.AnchorPoint = Vector2.new(0.5, 0.5)
warning.TextXAlignment = Enum.TextXAlignment.Center
warning.Visible = false

waveEvent.OnClientEvent:Connect(function(kind, arg)
	if kind == "warning" then
		warning.Visible = true
		warning.Text = "BRAINROT WAVE IN " .. math.ceil(arg) .. "s — GET TO YOUR BASE!"
	elseif kind == "wave" then
		say("THE BRAINROT WAVE SWEEPS THE MAP!")
		warning.Visible = false
	elseif kind == "penalty" then
		say("Caught outside your base! Lost $" .. arg)
	end
end)

-- Keyboard shortcuts: B lock, R restart, S sell the looked-at brainrot.
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		lockEvent:FireServer()
	elseif input.KeyCode == Enum.KeyCode.R then
		-- Restart: respawn the character back at spawn.
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				root.Position = Config.PLAZA.spawn
			end
		end
	elseif input.KeyCode == Enum.KeyCode.S then
		-- Sell the brainrot currently being looked at (raycast a placed one).
		local result = raycastToThing()
		if result then
			local model = result.Instance:FindFirstAncestorOfClass("Model")
			if model then
				local idx = model:GetAttribute("BrIndex")
				if idx then
					sellEvent:FireServer(idx)
				end
			end
		end
	end
end)

-- ---------------------------------------------------------------------------
-- Start overlay: the goal + controls. Click anywhere to dismiss.
-- ---------------------------------------------------------------------------
local startGui = Instance.new("ScreenGui")
startGui.Name = "StartOverlay"
startGui.ResetOnSpawn = false
startGui.IgnoreGuiInset = true
startGui.DisplayOrder = 20
startGui.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
backdrop.BackgroundTransparency = 0.25
backdrop.Parent = startGui

local title = makeLabel(backdrop, "Title", UDim2.fromScale(0.5, 0.25), UDim2.fromScale(0.9, 0.15),
	"BRAINROT RUSH", Color3.fromRGB(255, 220, 60), 54)
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.TextXAlignment = Enum.TextXAlignment.Center

local goals = makeLabel(backdrop, "Goals", UDim2.fromScale(0.5, 0.45), UDim2.fromScale(0.9, 0.3),
	"Catch brainrots off the belt, place them on your base,\nand watch the money roll in!\nWave hits every 90s — stay inside your base.\nSteal rivals, set locks, REBIRTH past $1,000,000!",
	Color3.fromRGB(230, 240, 255), 20)
goals.AnchorPoint = Vector2.new(0.5, 0.5)
goals.TextXAlignment = Enum.TextXAlignment.Center
goals.TextYAlignment = Enum.TextYAlignment.Center

local controls = makeLabel(backdrop, "Controls", UDim2.fromScale(0.5, 0.78), UDim2.fromScale(0.9, 0.08),
	"WASD move • SPACE jump • Click buy • Right-click steal • S sell • B lock • R restart",
	Color3.fromRGB(170, 200, 255), 16)
controls.AnchorPoint = Vector2.new(0.5, 0.5)
controls.TextXAlignment = Enum.TextXAlignment.Center

backdrop.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startGui:Destroy()
	end
end)

-- ---------------------------------------------------------------------------
-- Rebirth overlay: shows once lifetime earnings pass the threshold.
-- Press R (already bound above) to restart for a permanent x2 multiplier.
-- ---------------------------------------------------------------------------
local rebirthGui = Instance.new("ScreenGui")
rebirthGui.Name = "RebirthOverlay"
rebirthGui.ResetOnSpawn = false
rebirthGui.IgnoreGuiInset = true
rebirthGui.DisplayOrder = 15
rebirthGui.Parent = player:WaitForChild("PlayerGui")

local rBackdrop = Instance.new("Frame")
rBackdrop.Size = UDim2.fromScale(1, 1)
rBackdrop.BackgroundColor3 = Color3.fromRGB(90, 20, 120)
rBackdrop.BackgroundTransparency = 0.3
rBackdrop.Parent = rebirthGui

local rTitle = makeLabel(rBackdrop, "RTitle", UDim2.fromScale(0.5, 0.35), UDim2.fromScale(0.9, 0.14),
	"REBIRTH READY!", Color3.fromRGB(255, 120, 220), 40)
rTitle.AnchorPoint = Vector2.new(0.5, 0.5)
rTitle.TextXAlignment = Enum.TextXAlignment.Center

local rText = makeLabel(rBackdrop, "RText", UDim2.fromScale(0.5, 0.55), UDim2.fromScale(0.9, 0.1),
	"Lifetime earnings hit $1,000,000!\nPress R to REBIRTH — reset coins for a permanent x2 multiplier!",
	Color3.fromRGB(255, 240, 255), 18)
rText.AnchorPoint = Vector2.new(0.5, 0.5)
rText.TextXAlignment = Enum.TextXAlignment.Center

rebirthGui.Visible = false

-- Watch the lifetime attribute; show the overlay when it crosses the mark.
local lastLifetime = 0
RunService.Heartbeat:Connect(function()
	local lifetime = player:GetAttribute("lifetime") or 0
	if lastLifetime < Config.REBIRTH_NEED and lifetime >= Config.REBIRTH_NEED then
		rebirthGui.Visible = true
	end
	if player:GetAttribute("rebirths") and player:GetAttribute("rebirths") ~= (player:GetAttribute("preRebirths") or 0) then
		rebirthGui.Visible = false
	end
	player:SetAttribute("preRebirths", player:GetAttribute("rebirths") or 0)
	lastLifetime = lifetime
end)