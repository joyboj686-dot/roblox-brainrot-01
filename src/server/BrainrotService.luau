-- BrainrotService: spawn brainrots, roll mutations, move them along the belt,
-- handle buy + place on pads, and sell. One job.

local RunService = game:GetService("RunService")
local Config = require(script.Parent.Parent.shared.Config)

local BrainrotService = {}
BrainrotService.brainrots = {} -- list of { model, def, mutation, pad, owner }
BrainrotService.beltPath = {} -- waypoints as Vector3 list

local mutationAccum = 0 -- cumulative weight table for rolling mutations

-- Precompute the cumulative weights of mutations once.
local weights = {}
for _, m in ipairs(Config.MUTATIONS) do
	weights[#weights + 1] = m.weight
end
mutationAccum = {}
local acc = 0
for i, w in ipairs(weights) do
	acc += w
	mutationAccum[i] = acc
end
BrainrotService.mutationAccum = mutationAccum

-- Pick a mutation at random using the weighted table.
function BrainrotService.rollMutation()
	local total = mutationAccum[#mutationAccum]
	local r = math.random() * total
	for i, cutoff in ipairs(mutationAccum) do
		if r <= cutoff then
			return Config.MUTATIONS[i]
		end
	end
	return Config.MUTATIONS[1]
end

-- Pick a random roster definition, weighted toward rarer as time passes.
function BrainrotService.rollRoster(elapsed)
	local rarityBias = math.clamp(elapsed / 300, 0, 1)
	-- bias toward higher rarities over time; pick from the pool.
	local pool = Config.ROSTER
	-- Simple escalating: sometimes upgrade to a rarer slot.
	local idx = math.random(#pool)
	local boost = math.floor(rarityBias * 5)
	idx = math.min(idx + boost, #pool)
	return pool[idx]
end

-- Build a simple model for one brainrot from its roster def and mutation.
-- Returns the Model root. Its colour shifts with the mutation.
function BrainrotService.buildModel(def, mutation)
	local model = Instance.new("Model")
	model.Name = def.name

	local body = Instance.new("Part")
	body.Anchored = false
	body.Size = Vector3.new(2.5, 3, 2.5)
	body.Material = Enum.Material.SmoothPlastic
	body.Shape = Enum.PartType.Block
	local baseColor = def.color
	if mutation.name == "GOLDEN" then
		baseColor = Color3.fromRGB(255, 200, 40)
	elseif mutation.name == "RAINBOW" then
		baseColor = Color3.fromRGB(255, 90, 200)
	elseif mutation.name == "VOID" then
		baseColor = Color3.fromRGB(40, 20, 80)
	end
	body.Color = baseColor
	body.Parent = model

	-- A little "face" accent on the front.
	local eye = Instance.new("Part")
	eye.Anchored = false
	eye.Size = Vector3.new(0.5, 0.6, 0.1)
	eye.Color = def.accent
	eye.Parent = model
	eye.CFrame = body.CFrame * CFrame.new(-0.4, 0.3, 1.3)

	local eye2 = eye:Clone()
	eye2.Parent = model
	eye2.CFrame = body.CFrame * CFrame.new(0.4, 0.3, 1.3)

	-- Weld eyes to body so they follow it.
	local weld1 = Instance.new("WeldConstraint")
	weld1.Part0 = body
	weld1.Part1 = eye
	weld1.Parent = model
	local weld2 = Instance.new("WeldConstraint")
	weld2.Part0 = body
	weld2.Part1 = eye2
	weld2.Parent = model

	model.PrimaryPart = body
	return model
end

return BrainrotService