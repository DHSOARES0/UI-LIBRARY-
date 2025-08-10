--[[
	KoltESP Library
	Author: [YourName]
	Description:
	- Modular, address-oriented ESP Library for Roblox objects (Model, BasePart, etc).
	- Easily extensible, configurable, and supports multiple ESP types.
	- Usage: Kolt:AddEsp{...}, Kolt:Destroy(espObj), Kolt:Modify{...}
]]

local Kolt = {}
Kolt.__index = Kolt

------------------------------------------------------------
-- UTILS
------------------------------------------------------------
local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

local function getPartPos(obj, origin)
	if not obj then return nil end
	if obj:IsA("BasePart") then
		if origin == "Top" then return obj.Position + Vector3.new(0, obj.Size.Y / 2, 0)
		elseif origin == "Bottom" then return obj.Position - Vector3.new(0, obj.Size.Y / 2, 0)
		else return obj.Position end
	elseif obj:IsA("Model") then
		local p = obj:GetPrimaryPartCFrame() and obj.PrimaryPart.Position or obj:GetModelCFrame().p
		return p
	end
	return nil
end

------------------------------------------------------------
-- ESP OBJECT
------------------------------------------------------------
local ESP = {}
ESP.__index = ESP

function ESP:Destroy()
	if self._cleanup then
		for _, v in ipairs(self._cleanup) do
			pcall(function() v:Destroy() end)
		end
	end
	self._removed = true
end

function ESP:Modify(props)
	for k, v in pairs(props) do
		self.Config[k] = v
	end
end

------------------------------------------------------------
-- ESP TYPES
------------------------------------------------------------

local function CreateTracer(target, config)
	local tracer = Drawing.new("Line")
	tracer.Visible = true
	tracer.Color = config.Color or Color3.new(1,1,1)
	tracer.Thickness = config.Thickness or 2
	tracer.Transparency = config.Opacity or 1

	local origin = config.Origin or "Bottom"
	local function update()
		if not target or not target.Parent then tracer.Visible = false return end
		local partPos = getPartPos(target, origin)
		if not partPos then tracer.Visible = false return end
		local screenPos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(partPos)
		if onScreen then
			tracer.To = Vector2.new(screenPos.X, screenPos.Y)
			local fromVec
			if origin == "Top" then fromVec = Vector2.new(screenPos.X, 0)
			elseif origin == "Center" then fromVec = Vector2.new(workspace.CurrentCamera.ViewportSize.X/2, workspace.CurrentCamera.ViewportSize.Y/2)
			else fromVec = Vector2.new(screenPos.X, workspace.CurrentCamera.ViewportSize.Y) end
			tracer.From = fromVec
			tracer.Visible = true
		else
			tracer.Visible = false
		end
	end

	local conn = game:GetService("RunService").RenderStepped:Connect(update)
	return tracer, {tracer, conn}
end

local function CreateHighlight(target, config)
	local highlight = Instance.new("Highlight")
	highlight.Adornee = target
	highlight.Parent = game.CoreGui

	highlight.FillColor = config.FillColor or Color3.new(1,1,1)
	highlight.OutlineColor = config.OutlineColor or Color3.new(0,0,0)
	highlight.FillTransparency = 1 - (config.FillOpacity or 0.5)
	highlight.OutlineTransparency = 1 - (config.OutlineOpacity or 1)

	highlight.Fill = config.Fill ~= false
	highlight.Outline = config.Outline ~= false

	return highlight, {highlight}
end

local function CreateName(target, config)
	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.Adornee = target
	billboard.Parent = game.CoreGui

	local text = Instance.new("TextLabel")
	text.Parent = billboard
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = config.Color or Color3.new(1,1,1)
	text.Text = config.Name or target.Name
	text.TextStrokeTransparency = 0.5
	text.Font = config.Font or Enum.Font.Gotham
	text.TextScaled = true

	return billboard, {billboard, text}
end

local function CreateDistance(target, config)
	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 100, 0, 20)
	billboard.Adornee = target
	billboard.Parent = game.CoreGui

	local text = Instance.new("TextLabel")
	text.Parent = billboard
	text.Size = UDim2.new(1, 0, 1, 0)
	text.BackgroundTransparency = 1
	text.TextColor3 = config.Color or Color3.new(1,1,1)
	text.TextStrokeTransparency = 0.6
	text.Font = Enum.Font.Gotham
	text.TextScaled = true

	local function update()
		if not target or not target.Parent then billboard.Enabled = false return end
		local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root then
			local dist = (getPartPos(target, "Center") - root.Position).Magnitude
			text.Text = ("%.1fm"):format(dist)
			billboard.Enabled = true
		else
			billboard.Enabled = false
		end
	end

	local conn = game:GetService("RunService").RenderStepped:Connect(update)
	return billboard, {billboard, text, conn}
end

------------------------------------------------------------
-- KOLT LIBRARY CORE
------------------------------------------------------------

Kolt._espList = {}

function Kolt:AddEsp(tbl)
	-- tbl: {Tracer = {...}, Highlight = {...}, Name = {...}, Distance = {...}}
	local target = tbl.Target
	assert(target, "Target (Model/BasePart) is required!")

	local espObjs = {}
	if tbl.Tracer then
		local obj, cleanup = CreateTracer(target, tbl.Tracer)
		table.insert(espObjs, setmetatable({
			Type = "Tracer",
			Target = target,
			Config = deepCopy(tbl.Tracer),
			Obj = obj,
			_cleanup = cleanup,
		}, ESP))
	end
	if tbl.Highlight then
		local obj, cleanup = CreateHighlight(target, tbl.Highlight)
		table.insert(espObjs, setmetatable({
			Type = "Highlight",
			Target = target,
			Config = deepCopy(tbl.Highlight),
			Obj = obj,
			_cleanup = cleanup,
		}, ESP))
	end
	if tbl.Name then
		local obj, cleanup = CreateName(target, tbl.Name)
		table.insert(espObjs, setmetatable({
			Type = "Name",
			Target = target,
			Config = deepCopy(tbl.Name),
			Obj = obj,
			_cleanup = cleanup,
		}, ESP))
	end
	if tbl.Distance then
		local obj, cleanup = CreateDistance(target, tbl.Distance)
		table.insert(espObjs, setmetatable({
			Type = "Distance",
			Target = target,
			Config = deepCopy(tbl.Distance),
			Obj = obj,
			_cleanup = cleanup,
		}, ESP))
	end
	for _, espObj in ipairs(espObjs) do
		table.insert(self._espList, espObj)
	end
	return espObjs
end

function Kolt:Destroy(espObj)
	if type(espObj) == "table" then
		if espObj.Destroy then
			espObj:Destroy()
		else
			for _, v in ipairs(espObj) do
				if v.Destroy then v:Destroy() end
			end
		end
	end
end

function Kolt:Modify(espObj, props)
	if type(espObj) == "table" and espObj.Modify then
		espObj:Modify(props)
	end
end

------------------------------------------------------------
-- USAGE EXAMPLES
------------------------------------------------------------

--[[
local myEsp = Kolt:AddEsp{
	Target = workspace.Part,
	Tracer = {Color = Color3.new(1,0,0), Origin = "Bottom", Opacity = 0.8},
	Highlight = {Outline = true, Fill = true, OutlineColor = Color3.new(0,0,0), FillColor = Color3.new(1,1,1), OutlineOpacity = 0.7, FillOpacity = 0.5},
	Name = {Name = "example", Color = Color3.new(1,1,0)},
	Distance = {Color = Color3.new(0,1,0)},
}
Kolt:Destroy(myEsp)
]]

return Kolt
