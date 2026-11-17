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

	-- Keep above the floor (floor top at Y = ancelance 0).
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