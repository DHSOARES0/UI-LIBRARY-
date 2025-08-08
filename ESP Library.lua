-- ESPModule.lua
-- Biblioteca de ESP orientada a endereço de objetos

local ESP = {}
ESP.__index = ESP

-- Configurações padrão
local DEFAULTS = {
    Tracer = { Enabled = true, Position = "Bottom", Color = Color3.fromRGB(255, 255, 255) },
    HighlightOutline = { Enabled = true, Color = Color3.fromRGB(255, 255, 0) },
    HighlightFill = { Enabled = true, Color = Color3.fromRGB(255, 255, 0), Transparency = 0.5 },
    Name = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) },
    Distance = { Enabled = true, Color = Color3.fromRGB(255, 255, 255) }
}

-- Armazena os ESPs ativos
ESP.Active = {}

-- Função para criar um Drawing Object de forma simples
local function CreateDrawing(Type, Props)
    local obj = Drawing.new(Type)
    for prop, val in pairs(Props) do
        obj[prop] = val
    end
    return obj
end

-- Função para adicionar um ESP a um objeto
function ESP:Add(target, opts)
    if not target or not target:IsA("BasePart") then return end
    opts = opts or {}

    local settings = {}
    for k,v in pairs(DEFAULTS) do
        settings[k] = table.clone(v)
        if opts[k] then
            for p, val in pairs(opts[k]) do
                settings[k][p] = val
            end
        end
    end

    local espData = {
        Target = target,
        Settings = settings,
        Drawing = {}
    }

    -- Tracer
    if settings.Tracer.Enabled then
        espData.Drawing.Tracer = CreateDrawing("Line", { Thickness = 1, Color = settings.Tracer.Color })
    end

    -- Nome
    if settings.Name.Enabled then
        espData.Drawing.Name = CreateDrawing("Text", { Size = 14, Center = true, Color = settings.Name.Color, Outline = true })
    end

    -- Distância
    if settings.Distance.Enabled then
        espData.Drawing.Distance = CreateDrawing("Text", { Size = 13, Center = true, Color = settings.Distance.Color, Outline = true })
    end

    -- Highlight
    if settings.HighlightOutline.Enabled or settings.HighlightFill.Enabled then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = target.Parent
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.FillColor = settings.HighlightFill.Color
        highlight.FillTransparency = settings.HighlightFill.Transparency
        highlight.OutlineColor = settings.HighlightOutline.Color
        highlight.OutlineTransparency = 0
        highlight.Parent = game.CoreGui
        espData.HighlightInstance = highlight
    end

    table.insert(self.Active, espData)
    return espData
end

-- Função para remover um ESP
function ESP:Remove(espData)
    for _, obj in pairs(espData.Drawing) do
        if obj.Remove then obj:Remove() end
    end
    if espData.HighlightInstance then
        espData.HighlightInstance:Destroy()
    end
end

-- Atualização em loop
game:GetService("RunService").RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    for _, espData in ipairs(ESP.Active) do
        local target = espData.Target
        if target and target.Parent then
            local pos, visible = cam:WorldToViewportPoint(target.Position)
            if visible then
                -- Tracer
                if espData.Drawing.Tracer then
                    local startPos
                    if espData.Settings.Tracer.Position == "Top" then
                        startPos = Vector2.new(cam.ViewportSize.X / 2, 0)
                    elseif espData.Settings.Tracer.Position == "Center" then
                        startPos = cam.ViewportSize / 2
                    else -- Bottom
                        startPos = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
                    end
                    espData.Drawing.Tracer.From = startPos
                    espData.Drawing.Tracer.To = Vector2.new(pos.X, pos.Y)
                    espData.Drawing.Tracer.Visible = true
                end

                -- Nome
                if espData.Drawing.Name then
                    espData.Drawing.Name.Position = Vector2.new(pos.X, pos.Y - 20)
                    espData.Drawing.Name.Text = target.Parent.Name
                    espData.Drawing.Name.Visible = true
                end

                -- Distância
                if espData.Drawing.Distance then
                    local distance = (cam.CFrame.Position - target.Position).Magnitude
                    espData.Drawing.Distance.Position = Vector2.new(pos.X, pos.Y - 5)
                    espData.Drawing.Distance.Text = string.format("%dm", math.floor(distance))
                    espData.Drawing.Distance.Visible = true
                end
            else
                for _, obj in pairs(espData.Drawing) do
                    obj.Visible = false
                end
            end
        else
            ESP:Remove(espData)
        end
    end
end)

return ESP
