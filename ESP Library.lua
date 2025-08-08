--[[ 
    ESP LIBRARY - ORIENTADA A OBJETOS (Model / BasePart)

    ✅ Features:
    - Enable geral
    - Tracers
    - Highlights (Outline / Fill)
    - Nome acima da cabeça
    - Distância
    - Adição e modificação por referência direta (ex: workspace.Part)

    🔧 API:
    ESP.Settings.<Option> = true/false
    ESP:Add(target: Instance, name: string)
    ESP:Modify(target: Instance, config: table)

    🔁 Requer: RunService.RenderStepped
--]]

local ESP = {
    Settings = {
        Enable = true,
        EspTracer = true,
        EspHighlightOutline = true,
        EspHighlightFill = true,
        EspName = true,
        EspDistance = true
    },
    Targets = {}
}

local camera = workspace.CurrentCamera
local players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Util: Desenha texto 2D
local function createText()
    local txt = Drawing.new("Text")
    txt.Size = 13
    txt.Center = true
    txt.Outline = true
    txt.Visible = false
    txt.Color = Color3.new(1, 1, 1)
    return txt
end

-- Util: Desenha linha (tracer)
local function createLine()
    local line = Drawing.new("Line")
    line.Thickness = 1
    line.Transparency = 1
    line.Visible = false
    line.Color = Color3.new(1, 1, 1)
    return line
end

-- Util: Cria highlight
local function createHighlight(target)
    local hl = Instance.new("Highlight")
    hl.Adornee = target
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = true
    hl.Parent = target
    return hl
end

-- Adiciona objeto ao ESP
function ESP:Add(target: Instance, name: string)
    if not target or typeof(target) ~= "Instance" then return end
    if self.Targets[target] then return end

    local obj = {
        Target = target,
        Name = name or target.Name,
        Visible = true,
        Tracer = createLine(),
        Text = createText(),
        Highlight = nil
    }

    if target:IsA("Model") then
        obj.PrimaryPart = target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
    elseif target:IsA("BasePart") then
        obj.PrimaryPart = target
    end

    if obj.PrimaryPart and (ESP.Settings.EspHighlightOutline or ESP.Settings.EspHighlightFill) then
        obj.Highlight = createHighlight(target)
    end

    self.Targets[target] = obj
end

-- Modifica visibilidade/configuração de um target existente
function ESP:Modify(target: Instance, config: table)
    local obj = self.Targets[target]
    if not obj then return end
    for key, value in pairs(config) do
        obj[key] = value
    end
end

-- Remove target opcionalmente (não obrigatório, mas útil)
function ESP:Remove(target: Instance)
    local obj = self.Targets[target]
    if obj then
        if obj.Text then obj.Text:Remove() end
        if obj.Tracer then obj.Tracer:Remove() end
        if obj.Highlight then obj.Highlight:Destroy() end
        self.Targets[target] = nil
    end
end

-- Render Loop
RunService.RenderStepped:Connect(function()
    if not ESP.Settings.Enable then
        for _, obj in pairs(ESP.Targets) do
            if obj.Text then obj.Text.Visible = false end
            if obj.Tracer then obj.Tracer.Visible = false end
            if obj.Highlight then obj.Highlight.Enabled = false end
        end
        return
    end

    local camPos = camera.CFrame.Position

    for _, obj in pairs(ESP.Targets) do
        local part = obj.PrimaryPart
        if not (obj.Visible and part and part:IsDescendantOf(workspace)) then
            if obj.Text then obj.Text.Visible = false end
            if obj.Tracer then obj.Tracer.Visible = false end
            if obj.Highlight then obj.Highlight.Enabled = false end
            continue
        end

        local pos, onScreen = camera:WorldToViewportPoint(part.Position)
        if not onScreen then
            if obj.Text then obj.Text.Visible = false end
            if obj.Tracer then obj.Tracer.Visible = false end
            if obj.Highlight then obj.Highlight.Enabled = false end
            continue
        end

        -- Text (Name + Distance)
        if ESP.Settings.EspName or ESP.Settings.EspDistance then
            local dist = (camPos - part.Position).Magnitude
            local label = ""
            if ESP.Settings.EspName then label = label .. obj.Name end
            if ESP.Settings.EspDistance then label = label .. string.format(" [%.0f]", dist) end

            obj.Text.Text = label
            obj.Text.Position = Vector2.new(pos.X, pos.Y - 15)
            obj.Text.Visible = true
        else
            obj.Text.Visible = false
        end

        -- Tracer
        if ESP.Settings.EspTracer then
            obj.Tracer.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)
            obj.Tracer.To = Vector2.new(pos.X, pos.Y)
            obj.Tracer.Visible = true
        else
            obj.Tracer.Visible = false
        end

        -- Highlight
        if obj.Highlight then
            obj.Highlight.FillTransparency = ESP.Settings.EspHighlightFill and 0.5 or 1
            obj.Highlight.OutlineTransparency = ESP.Settings.EspHighlightOutline and 0 or 1
            obj.Highlight.Enabled = true
        end
    end
end)

return ESP
