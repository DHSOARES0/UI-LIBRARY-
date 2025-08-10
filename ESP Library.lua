--[[
    📦 ESP HUB LIBRARY (Refatorada)
    ✅ Nome customizável
    ✅ Distância abaixo do nome
    ✅ Cor e transparência individuais para Outline/Fill
    ✅ Apenas um Highlight para ambos os tipos
    📝 Hospede no GitHub e use:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/SEUUSER/SEUREPO/main/esp.lua"))()
--]]

local ESPHub = {}
ESPHub.__index = ESPHub

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

function ESPHub:Create(target, settings)
    assert(target, "Target inválido: forneça Model ou BasePart")
    settings = settings or {}

    local esp = setmetatable({}, ESPHub)
    esp.Target = target
    esp.Enabled = true

    -- Configurações
    esp.DisplayName = settings.DisplayName or target.Name
    esp.TracerOrigin = settings.TracerOrigin or "Bottom" -- Top / Center / Bottom
    esp.ShowTracer = settings.ShowTracer or false
    esp.ShowOutline = settings.ShowOutline or false
    esp.ShowFill = settings.ShowFill or false
    esp.ShowName = settings.ShowName or false
    esp.ShowDistance = settings.ShowDistance or false

    -- Cores e transparência individuais
    esp.OutlineColor = settings.OutlineColor or Color3.fromRGB(255, 255, 255)
    esp.FillColor = settings.FillColor or Color3.fromRGB(255, 255, 255)
    esp.OutlineTransparency = settings.OutlineTransparency or 0
    esp.FillTransparency = settings.FillTransparency or 0.5

    -- Drawing Objects
    esp.Tracer = Drawing.new("Line")
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = esp.OutlineColor

    esp.LabelName = Drawing.new("Text")
    esp.LabelName.Size = 14
    esp.LabelName.Color = esp.OutlineColor
    esp.LabelName.Center = true
    esp.LabelName.Outline = true

    esp.LabelDist = Drawing.new("Text")
    esp.LabelDist.Size = 13
    esp.LabelDist.Color = esp.OutlineColor
    esp.LabelDist.Center = true
    esp.LabelDist.Outline = true

    -- Highlight único
    if esp.ShowOutline or esp.ShowFill then
        local hl = Instance.new("Highlight")
        hl.Adornee = target
        hl.OutlineTransparency = esp.ShowOutline and esp.OutlineTransparency or 1
        hl.FillTransparency = esp.ShowFill and esp.FillTransparency or 1
        hl.OutlineColor = esp.OutlineColor
        hl.FillColor = esp.FillColor
        hl.Parent = target
        esp.Highlight = hl
    end

    -- Atualização
    esp.Connection = RunService.RenderStepped:Connect(function()
        esp:Update()
    end)

    return esp
end

function ESPHub:Update()
    if not self.Enabled or not self.Target then
        self.Tracer.Visible = false
        self.LabelName.Visible = false
        self.LabelDist.Visible = false
        return
    end

    local pos
    if self.Target:IsA("Model") then
        local primary = self.Target.PrimaryPart or self.Target:FindFirstChildWhichIsA("BasePart")
        if not primary then return end
        pos = primary.Position
    elseif self.Target:IsA("BasePart") then
        pos = self.Target.Position
    else
        return
    end

    local originY = Camera.ViewportSize.Y
    if self.TracerOrigin == "Top" then
        originY = 0
    elseif self.TracerOrigin == "Center" then
        originY = Camera.ViewportSize.Y / 2
    end

    local screenPos, onScreen = WorldToScreen(pos)

    if onScreen then
        -- Tracer
        if self.ShowTracer then
            self.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, originY)
            self.Tracer.To = screenPos
            self.Tracer.Visible = true
        else
            self.Tracer.Visible = false
        end

        -- Nome
        if self.ShowName then
            self.LabelName.Text = self.DisplayName
            self.LabelName.Position = screenPos - Vector2.new(0, 20)
            self.LabelName.Visible = true
        else
            self.LabelName.Visible = false
        end

        -- Distância
        if self.ShowDistance then
            local dist = (Camera.CFrame.Position - pos).Magnitude
            self.LabelDist.Text = string.format("%.1fm", dist)
            self.LabelDist.Position = screenPos - Vector2.new(0, 5)
            self.LabelDist.Visible = true
        else
            self.LabelDist.Visible = false
        end

    else
        self.Tracer.Visible = false
        self.LabelName.Visible = false
        self.LabelDist.Visible = false
    end
end

function ESPHub:Remove()
    self.Enabled = false
    if self.Connection then self.Connection:Disconnect() end
    if self.Tracer then self.Tracer:Remove() end
    if self.LabelName then self.LabelName:Remove() end
    if self.LabelDist then self.LabelDist:Remove() end
    if self.Highlight then self.Highlight:Destroy() end
end

-- HUB Manager
local Manager = {}
function Manager:New(...)
    return ESPHub:Create(...)
end

return Manager
