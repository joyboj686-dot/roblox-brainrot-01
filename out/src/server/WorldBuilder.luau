-- WorldBuilder: builds the bright plaza from Config.PLAZA.
-- One job: turn the shared layout table into real anchored parts in Workspace.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local WorldBuilder = {}

local function part(parent, size, pos, color, name)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Locked = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.Position = pos
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Name = name or "Part"
	p.Parent = parent
	return p
end

function WorldBuilder.build(workspace)
	local pl = Config.PLAZA

	-- Bright floor.
	part(workspace, pl.floor.size, pl.floor.position, pl.floor.color, "Floor")

	-- Conveyor belt: a raised rectangular track plus a pair of rails.
	local bw = pl.belt.width
	local bt = pl.belt.height
	local beltHolder = Instance.new("Folder")
	beltHolder.Name = "Belt"
	beltHolder.Parent = workspace
	part(beltHolder, Vector3.new(132, bt, 44), Vector3.new(0, bt / 2, -30), pl.belt.color, "BeltTrack")
	-- Two rails along the belt edges.
	part(beltHolder, Vector3.new(132, 2, 1), Vector3.new(0, bt + 1, -52 + 1), pl.belt.railColor, "RailN")
	part(beltHolder, Vector3.new(132, 2, 1), Vector3.new(0, bt + 1, -8), pl.belt.railColor, "RailS")

	-- Player base: raised plot.
	local base = Instance.new("Folder")
	base.Name = "Base"
	base.Parent = workspace
	part(base, pl.base.size, pl.base.position + Vector3.new(0, 1, 0), pl.base.color, "BasePlot")
	-- 8 pads on top of the base.
	for i, padPos in ipairs(pl.base.pads) do
		part(base, Vector3.new(8, 1, 8), padPos + Vector3.new(0, 2, 0), pl.base.padColor, "Pad" .. i)
	end

	-- Rival base (steal target).
	local rival = Instance.new("Folder")
	rival.Name = "RivalBase"
	rival.Parent = workspace
	part(rival, pl.rival.size, pl.rival.position + Vector3.new(0, 1, 0), pl.rival.color, "RivalPlot")
	for i, padPos in ipairs(pl.rival.pads) do
		part(rival, Vector3.new(8, 1, 8), padPos + Vector3.new(0, 2, 0), pl.base.padColor, "Pad" .. i)
	end

	-- Decorative props: trees and rocks.
	for i, prop in ipairs(pl.props) do
		if prop.kind == "tree" then
			part(workspace, Vector3.new(6, 6, 2), prop.pos + Vector3.new(0, 3, 0), prop.color, "Tree" .. i)
			part(workspace, Vector3.new(1.5, 1, 1.5), prop.pos + Vector3.new(0, 1, 0), Color3.fromRGB(120, 80, 40), "Trunk" .. i)
		else
			part(workspace, Vector3.new(6, 3, 6), prop.pos + Vector3.new(0, 1.5, 0), prop.color, "Rock" .. i)
		end
	end

	-- Safe-zone visual for the wave (a translucent box over the base).
	local safe = part(workspace, pl.base.safe.size, pl.base.position + Vector3.new(0, 12, 0), Color3.fromRGB(120, 255, 120), "SafeZone")
	safe.Transparency = 0.75
	safe.CanCollide = false
	safe.Parent = workspace

	return beltHolder
end

return WorldBuilder