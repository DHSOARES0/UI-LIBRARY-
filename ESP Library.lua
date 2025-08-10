--[[
    📦 ESP HUB LIBRARY
    ✅ Model & BasePart Support
    ✅ Tracer (Top / Center / Bottom)
    ✅ Highlight Outline
    ✅ Highlight Fill
    ✅ Name
    ✅ Distance (Value.m)
    📝 Hospede no GitHub e use:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/SEUUSER/SEUREPO/main/esp.lua"))()
--]]

local ESPHub = {}
ESPHub.__index = ESPHub

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
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

    -- Configurações padrão
    esp.Color = settings.Color or Color3.fromRGB(255, 255, 255)
    esp.TracerOrigin = settings.TracerOrigin or "Bottom" -- Top/Center/Bottom
    esp.ShowTracer = settings.ShowTracer or false
    esp.ShowOutline = settings.ShowOutline or false
    esp.ShowFill = settings.ShowFill or false
    esp.ShowName = settings.ShowName or false
    esp.ShowDistance = settings.ShowDistance or false

    -- Elementos Drawing
    esp.Tracer = Drawing.new("Line")
    esp.Tracer.Thickness = 1
    esp.Tracer.Color = esp.Color

    esp.Label = Drawing.new("Text")
    esp.Label.Size = 14
    esp.Label.Color = esp.Color
    esp.Label.Center = true
    esp.Label.Outline = true

    -- Chams (Highlight)
    if esp.ShowOutline or esp.ShowFill then
        local hl = Instance.new("Highlight")
        hl.Adornee = target
        hl.OutlineTransparency = esp.ShowOutline and 0 or 1
        hl.FillTransparency = esp.ShowFill and 0.5 or 1
        hl.OutlineColor = esp.Color
        hl.FillColor = esp.Color
        hl.Parent = target
        esp.Highlight = hl
    end

    -- Atualização RenderStepped
    esp.Connection = RunService.RenderStepped:Connect(function()
        esp:Update()
    end)

    return esp
end

function ESPHub:Update()
    if not self.Enabled or not self.Target then
        self.Tracer.Visible = false
        self.Label.Visible = false
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

    local screenPos, onScreen, depth = WorldToScreen(pos)

    if onScreen then
        -- Tracer
        if self.ShowTracer then
            self.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, originY)
            self.Tracer.To = screenPos
            self.Tracer.Visible = true
        else
            self.Tracer.Visible = false
        end

        -- Nome + Distância
        local text = ""
        if self.ShowName then
            text = self.Target.Name
        end
        if self.ShowDistance then
            local dist = (Camera.CFrame.Position - pos).Magnitude
            text = text .. string.format(" %.1fm", dist)
        end
        self.Label.Text = text
        self.Label.Position = screenPos - Vector2.new(0, 20)
        self.Label.Visible = (text ~= "")

    else
        self.Tracer.Visible = false
        self.Label.Visible = false
    end
end

function ESPHub:Remove()
    self.Enabled = false
    if self.Connection then
        self.Connection:Disconnect()
    end
    if self.Tracer then
        self.Tracer:Remove()
    end
    if self.Label then
        self.Label:Remove()
    end
    if self.Highlight then
        self.Highlight:Destroy()
    end
end

-- Criar "Gerenciador" estilo HUB
local Manager = {}
function Manager:New(...)
    return ESPHub:Create(...)
end

return Manager
