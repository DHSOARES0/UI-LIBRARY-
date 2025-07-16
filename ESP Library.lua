--[[ 
ESP Library aprimorada por dhsoares01 & Chat Copilot
• Suporte a Tracer (ESP Line), Outline, Box3D, Distance, Name, via Loadstring
• Design aprimorado, mais performance, mais legibilidade
--]]

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESP = {}
ESP.Objects = {}
ESP.Enabled = true

ESP.DefaultSettings = {
    Name = "ESP",
    ShowName = true,
    ShowDistance = true,
    ShowTracer = true,
    ShowOutline = true,
    ShowBox3D = true,
    Color = Color3.fromRGB(50, 200, 255)
}

local function IsOnScreen(pos)
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return onScreen, vec
end

local function CreateDrawing(class, props)
    local obj = Drawing.new(class)
    for i, v in pairs(props) do
        obj[i] = v
    end
    return obj
end

local function CreateBillboard(target, settings)
    local gui = Instance.new("BillboardGui")
    gui.Name = "_ESP_Billboard"
    gui.Size = UDim2.new(0, 120, 0, 45)
    gui.StudsOffset = Vector3.new(0, 3, 0)
    gui.AlwaysOnTop = true
    gui.Adornee = target
    gui.Parent = target

    local padding = Instance.new("UIListLayout")
    padding.FillDirection = Enum.FillDirection.Vertical
    padding.HorizontalAlignment = Enum.HorizontalAlignment.Center
    padding.VerticalAlignment = Enum.VerticalAlignment.Center
    padding.Parent = gui

    if settings.ShowName then
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "Name"
        nameLabel.Size = UDim2.new(1, 0, 0.5, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3 = settings.Color
        nameLabel.TextStrokeTransparency = 0.3
        nameLabel.TextStrokeColor3 = Color3.new(0,0,0)
        nameLabel.Text = settings.Name
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = gui
    end

    if settings.ShowDistance then
        local distLabel = Instance.new("TextLabel")
        distLabel.Name = "Distance"
        distLabel.Size = UDim2.new(1, 0, 0.5, 0)
        distLabel.BackgroundTransparency = 1
        distLabel.TextColor3 = settings.Color
        distLabel.TextStrokeTransparency = 0.3
        distLabel.TextStrokeColor3 = Color3.new(0,0,0)
        distLabel.Text = "0m"
        distLabel.TextScaled = true
        distLabel.Font = Enum.Font.Gotham
        distLabel.Parent = gui
    end

    return gui
end

function ESP:AddObject(target, settings)
    settings = setmetatable(settings or {}, { __index = self.DefaultSettings })
    if not target or not target:IsDescendantOf(workspace) then return end

    local espData = {
        Target = target,
        Settings = settings,
        Drawings = {},
        Highlight = nil,
        Billboard = nil
    }

    -- Tracer (ESP Line)
    if settings.ShowTracer then
        espData.Drawings.Tracer = CreateDrawing("Line", {
            Thickness = 2,
            Color = settings.Color,
            Transparency = 0.95,
            Visible = false
        })
    end

    -- Box 3D (apenas visual, baseado em distância)
    if settings.ShowBox3D then
        espData.Drawings.Box = CreateDrawing("Square", {
            Thickness = 2,
            Color = settings.Color,
            Transparency = 0.9,
            Filled = false,
            Visible = false
        })
    end

    -- Outline (Highlight melhorada)
    if settings.ShowOutline and (target:IsA("Model") or target:IsA("BasePart")) then
        local hl = Instance.new("Highlight")
        hl.Name = "_ESP_Highlight"
        hl.FillColor = settings.Color
        hl.OutlineColor = Color3.new(1,1,1) -- Outline branco para contraste
        hl.FillTransparency = 0.7
        hl.OutlineTransparency = 0.1
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Adornee = target
        hl.Parent = target
        espData.Highlight = hl
    end

    -- Billboard GUI para Name e Distance
    if settings.ShowName or settings.ShowDistance then
        local gui = CreateBillboard(target, settings)
        espData.Billboard = gui
    end

    table.insert(self.Objects, espData)
end

function ESP:Clear()
    for _, esp in pairs(self.Objects) do
        for _, draw in pairs(esp.Drawings) do
            draw:Remove()
        end
        if esp.Highlight then
            pcall(function() esp.Highlight:Destroy() end)
        end
        if esp.Billboard then
            pcall(function() esp.Billboard:Destroy() end)
        end
    end
    self.Objects = {}
end

RunService.RenderStepped:Connect(function()
    if not ESP.Enabled then return end
    for _, esp in pairs(ESP.Objects) do
        local target = esp.Target

        -- Suporte a modelos e parts
        local root
        if target:IsA("BasePart") then
            root = target
        elseif target:IsA("Model") then
            root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart")
        end
        if not root then continue end

        local onscreen, pos = IsOnScreen(root.Position)
        if not onscreen then
            for _, draw in pairs(esp.Drawings) do
                draw.Visible = false
            end
            continue
        end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        local settings = esp.Settings

        -- Tracer (do centro inferior da tela até o alvo)
        if settings.ShowTracer and esp.Drawings.Tracer then
            local line = esp.Drawings.Tracer
            line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 20)
            line.To = Vector2.new(pos.X, pos.Y)
            line.Color = settings.Color
            line.Visible = true
        end

        -- Box 3D (simples, visual)
        if settings.ShowBox3D and esp.Drawings.Box then
            local box = esp.Drawings.Box
            local size = Vector2.new(55 / (dist / 10), 90 / (dist / 10))
            box.Size = size
            box.Position = Vector2.new(pos.X - size.X / 2, pos.Y - size.Y / 2)
            box.Color = settings.Color
            box.Visible = true
        end

        -- Atualiza Highlight se necessário
        if settings.ShowOutline and (not esp.Highlight or not esp.Highlight.Parent) then
            local hl = Instance.new("Highlight")
            hl.Name = "_ESP_Highlight"
            hl.FillColor = settings.Color
            hl.OutlineColor = Color3.new(1,1,1)
            hl.FillTransparency = 0.7
            hl.OutlineTransparency = 0.1
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Adornee = target
            hl.Parent = target
            esp.Highlight = hl
        end

        -- Atualiza distância no Billboard
        if esp.Billboard then
            local dLabel = esp.Billboard:FindFirstChild("Distance")
            if dLabel then
                dLabel.Text = string.format("%.1f m", dist)
            end
        end
    end
end)

return ESP
