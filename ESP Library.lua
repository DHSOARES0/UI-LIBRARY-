-- DeltaEspHub - ESP Library orientada a endereço de objetos (Model/BasePart)
-- Suporte: Tracer (Top/Center/Bottom), HighlightOutline, HighlightFill, Name, Distance
-- Uso: loadstring(game:HttpGet("https://raw.githubusercontent.com/SeuUsuario/DeltaEspHub/main/DeltaEspHub.lua"))()

local DeltaEspHub = {
    _objects = {},
    _espTypes = {"Tracer", "HighlightOutline", "HighlightFill", "Name", "Distance"},
    _tracerOrigin = "Bottom", -- Opções: "Top", "Center", "Bottom"
    _espFolder = nil,
    _connections = {},
}

-- Utilitários internos
local function isBasePart(obj)
    return typeof(obj) == "Instance" and obj:IsA("BasePart")
end

local function isModel(obj)
    return typeof(obj) == "Instance" and obj:IsA("Model") and obj.PrimaryPart
end

local function getPosition(obj, origin)
    if isBasePart(obj) then
        local cf = obj.CFrame
        if origin == "Center" then
            return cf.Position
        elseif origin == "Top" then
            return (cf * CFrame.new(0, obj.Size.Y/2, 0)).Position
        elseif origin == "Bottom" then
            return (cf * CFrame.new(0, -obj.Size.Y/2, 0)).Position
        end
    elseif isModel(obj) then
        local pp = obj.PrimaryPart
        return getPosition(pp, origin)
    end
    return nil
end

-- ESP Functions
function DeltaEspHub:AddObject(obj)
    if not (isBasePart(obj) or isModel(obj)) then return end
    if self._objects[obj] then return end

    -- Cria tabela para armazenar os elementos de ESP desse objeto
    self._objects[obj] = {}

    -- Tracer
    if self.EnabledTypes.Tracer then
        local tracer = Drawing.new("Line")
        tracer.Color = Color3.fromRGB(255,255,255)
        tracer.Thickness = 2
        tracer.Visible = true
        self._objects[obj].Tracer = tracer
    end

    -- HighlightOutline
    if self.EnabledTypes.HighlightOutline or self.EnabledTypes.HighlightFill then
        local highlight = Instance.new("Highlight")
        highlight.Adornee = obj
        highlight.Parent = self._espFolder
        highlight.Enabled = true
        if self.EnabledTypes.HighlightOutline then
            highlight.OutlineColor = Color3.fromRGB(255,255,255)
            highlight.OutlineTransparency = 0
        else
            highlight.OutlineTransparency = 1
        end
        if self.EnabledTypes.HighlightFill then
            highlight.FillColor = Color3.fromRGB(255,255,255)
            highlight.FillTransparency = 0.5
        else
            highlight.FillTransparency = 1
        end
        self._objects[obj].Highlight = highlight
    end

    -- Name
    if self.EnabledTypes.Name then
        local nameDrawing = Drawing.new("Text")
        nameDrawing.Text = obj.Name
        nameDrawing.Size = 16
        nameDrawing.Color = Color3.fromRGB(255,255,255)
        nameDrawing.Outline = true
        nameDrawing.Visible = true
        self._objects[obj].Name = nameDrawing
    end

    -- Distance
    if self.EnabledTypes.Distance then
        local distDrawing = Drawing.new("Text")
        distDrawing.Text = "0m"
        distDrawing.Size = 14
        distDrawing.Color = Color3.fromRGB(0,255,127)
        distDrawing.Outline = true
        distDrawing.Visible = true
        self._objects[obj].Distance = distDrawing
    end
end

function DeltaEspHub:RemoveObject(obj)
    if not self._objects[obj] then return end
    for _, v in pairs(self._objects[obj]) do
        if typeof(v) == "Instance" and v.Destroy then
            v:Destroy()
        elseif typeof(v) == "table" and v.Remove then
            v:Remove()
        elseif typeof(v) == "userdata" and v.Remove then
            v:Remove()
        end
    end
    self._objects[obj] = nil
end

function DeltaEspHub:SetTracerOrigin(origin)
    if origin == "Top" or origin == "Center" or origin == "Bottom" then
        self._tracerOrigin = origin
    end
end

function DeltaEspHub:EnableEspType(espType)
    if table.find(self._espTypes, espType) then
        self.EnabledTypes[espType] = true
    end
end

function DeltaEspHub:DisableEspType(espType)
    if table.find(self._espTypes, espType) then
        self.EnabledTypes[espType] = false
    end
end

-- Atualização dos ESPs
function DeltaEspHub:Update()
    local camera = workspace.CurrentCamera
    local localPlayer = game.Players.LocalPlayer
    for obj, elements in pairs(self._objects) do
        local pos = getPosition(obj, self._tracerOrigin)
        if pos then
            local vec, onScreen = camera:WorldToViewportPoint(pos)
            -- Tracer
            if elements.Tracer then
                elements.Tracer.From = Vector2.new(vec.X, vec.Y)
                elements.Tracer.To = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                elements.Tracer.Visible = onScreen
            end
            -- Name
            if elements.Name then
                elements.Name.Position = Vector2.new(vec.X, vec.Y - 20)
                elements.Name.Visible = onScreen
            end
            -- Distance
            if elements.Distance and localPlayer and localPlayer.Character and localPlayer.Character.PrimaryPart then
                local dist = (localPlayer.Character.PrimaryPart.Position - pos).Magnitude
                elements.Distance.Text = string.format("%.1fm", dist)
                elements.Distance.Position = Vector2.new(vec.X, vec.Y + 10)
                elements.Distance.Visible = onScreen
            end
        end
    end
end

-- Inicialização
function DeltaEspHub:Init()
    self._espFolder = Instance.new("Folder")
    self._espFolder.Name = "DeltaEspHubFolder"
    self._espFolder.Parent = game.CoreGui

    self.EnabledTypes = {
        Tracer = true,
        HighlightOutline = false,
        HighlightFill = false,
        Name = true,
        Distance = true,
    }

    -- Atualização contínua
    local RunService = game:GetService("RunService")
    table.insert(self._connections, RunService.RenderStepped:Connect(function()
        self:Update()
    end))
end

function DeltaEspHub:Destroy()
    for obj in pairs(self._objects) do
        self:RemoveObject(obj)
    end
    if self._espFolder then
        self._espFolder:Destroy()
        self._espFolder = nil
    end
    for _, conn in ipairs(self._connections) do
        if conn and conn.Disconnect then
            conn:Disconnect()
        end
    end
    self._connections = {}
end

DeltaEspHub:Init()

return DeltaEspHub
