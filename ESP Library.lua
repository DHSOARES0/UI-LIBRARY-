-- KoltESP Library (Loadstring friendly)
-- Author: Kolt (customizado)
-- Modular, fácil e moldável ESP Library para Models, BaseParts etc

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Kolt = {}
Kolt.__index = Kolt

-- Guarda todos os ESPs ativos: chave = target (Model/BasePart), valor = espObject
Kolt.ActiveESPs = {}

-- Função interna para criar Drawing.Text
local function CreateText(text, size, color, transparency)
    local txt = Drawing.new("Text")
    txt.Text = text or ""
    txt.Size = size or 16
    txt.Color = color or Color3.new(1,1,1)
    txt.Transparency = transparency or 1
    txt.Center = true
    txt.Outline = true
    txt.OutlineColor = Color3.new(0,0,0)
    return txt
end

-- Função interna para criar Drawing.Line
local function CreateLine(color, thickness, transparency)
    local line = Drawing.new("Line")
    line.Color = color or Color3.new(1,1,1)
    line.Thickness = thickness or 1
    line.Transparency = transparency or 1
    return line
end

-- Função interna para criar Drawing.Quad (para highlight fill)
local function CreateQuad(color, transparency)
    local quad = Drawing.new("Quad")
    quad.Color = color or Color3.new(1,1,1)
    quad.Transparency = transparency or 0.5
    return quad
end

-- Função para converter 3D ponto para 2D na tela
local function ToScreenPoint(pos)
    local viewportPoint, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(viewportPoint.X, viewportPoint.Y), onScreen and viewportPoint.Z > 0
end

-- ESP Object prototype
local ESP = {}
ESP.__index = ESP

-- Criar novo ESP para um target
function Kolt:AddEsp(config)
    assert(config.Target, "Target obrigatorio")
    local target = config.Target

    if self.ActiveESPs[target] then
        warn("ESP para esse target ja existe")
        return self.ActiveESPs[target]
    end

    local esp = setmetatable({}, ESP)
    esp.Target = target

    -- Configuração das ESPs individuais

    -- Tracer
    if config.Tracer then
        esp.Tracer = {}
        esp.Tracer.Color = config.Tracer.Color or Color3.new(1,1,1)
        esp.Tracer.Origin = config.Tracer.Origin or "Bottom" -- Top, Center, Bottom
        esp.Tracer.Opacity = config.Tracer.Opacity or 1
        esp.Tracer.Line = CreateLine(esp.Tracer.Color, 1, esp.Tracer.Opacity)
    end

    -- Highlight Outline e Fill
    if config.Highlight then
        esp.Highlight = {}
        esp.Highlight.Outline = config.Highlight.Outline or false
        esp.Highlight.Fill = config.Highlight.Fill or false
        esp.Highlight.OutlineColor = config.Highlight.OutlineColor or Color3.new(1,1,1)
        esp.Highlight.FillColor = config.Highlight.FillColor or Color3.new(1,1,1)
        esp.Highlight.OutlineOpacity = config.Highlight.OutlineOpacity or 1
        esp.Highlight.FillOpacity = config.Highlight.FillOpacity or 0.5

        if esp.Highlight.Outline then
            esp.Highlight.OutlineDrawing = CreateLine(esp.Highlight.OutlineColor, 2, esp.Highlight.OutlineOpacity)
        end
        if esp.Highlight.Fill then
            esp.Highlight.FillDrawing = CreateQuad(esp.Highlight.FillColor, esp.Highlight.FillOpacity)
        end
    end

    -- Name label
    if config.Name then
        esp.Name = {}
        esp.Name.Text = config.Name.Text or tostring(target.Name)
        esp.Name.Color = config.Name.Color or Color3.new(1,1,1)
        esp.Name.Opacity = config.Name.Opacity or 1
        esp.Name.TextDrawing = CreateText(esp.Name.Text, 16, esp.Name.Color, esp.Name.Opacity)
    end

    -- Distance label
    if config.Distance then
        esp.Distance = {}
        esp.Distance.Enabled = config.Distance.Enabled or false
        esp.Distance.Color = config.Distance.Color or Color3.new(1,1,1)
        esp.Distance.Opacity = config.Distance.Opacity or 1
        esp.Distance.TextDrawing = CreateText("", 14, esp.Distance.Color, esp.Distance.Opacity)
    end

    -- Store ESP object active
    self.ActiveESPs[target] = esp

    -- Connect update
    esp.Connection = RunService.RenderStepped:Connect(function()
        esp:Update()
    end)

    return esp
end

-- Atualizar posição, visibilidade e conteúdo
function ESP:Update()
    local target = self.Target
    if not target or not target.Parent then
        self:Destroy()
        return
    end

    local rootPart = nil
    if target:IsA("Model") then
        rootPart = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
    elseif target:IsA("BasePart") then
        rootPart = target
    end

    if not rootPart then
        self:Destroy()
        return
    end

    local pos = rootPart.Position

    -- Tracer
    if self.Tracer and self.Tracer.Line then
        local originPos
        if self.Tracer.Origin == "Top" then
            originPos = Vector3.new(Camera.CFrame.Position.X, Camera.CFrame.Position.Y + 1.7, Camera.CFrame.Position.Z)
        elseif self.Tracer.Origin == "Center" then
            originPos = Camera.CFrame.Position
        else -- Bottom
            originPos = Vector3.new(Camera.CFrame.Position.X, Camera.CFrame.Position.Y - 1.7, Camera.CFrame.Position.Z)
        end

        local screenOrigin, originOnScreen = ToScreenPoint(originPos)
        local screenTarget, targetOnScreen = ToScreenPoint(pos)

        if originOnScreen and targetOnScreen then
            self.Tracer.Line.From = screenOrigin
            self.Tracer.Line.To = screenTarget
            self.Tracer.Line.Visible = true
            self.Tracer.Line.Color = self.Tracer.Color
            self.Tracer.Line.Transparency = self.Tracer.Opacity
        else
            self.Tracer.Line.Visible = false
        end
    end

    -- Highlight
    if self.Highlight then
        -- Outline & Fill simples com BoundingBox 2D (simplificado)
        local boxCorners = {}
        local size = rootPart.Size or Vector3.new(1,1,1)

        -- Calcula 8 cantos da caixa 3D e transforma para 2D
        local cf = rootPart.CFrame
        local corners3D = {
            cf * Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
            cf * Vector3.new(-size.X/2, -size.Y/2, size.Z/2),
            cf * Vector3.new(-size.X/2, size.Y/2, -size.Z/2),
            cf * Vector3.new(-size.X/2, size.Y/2, size.Z/2),
            cf * Vector3.new(size.X/2, -size.Y/2, -size.Z/2),
            cf * Vector3.new(size.X/2, -size.Y/2, size.Z/2),
            cf * Vector3.new(size.X/2, size.Y/2, -size.Z/2),
            cf * Vector3.new(size.X/2, size.Y/2, size.Z/2),
        }

        local corners2D = {}
        local validCount = 0
        for i, v3 in pairs(corners3D) do
            local point2D, onScreen = ToScreenPoint(v3)
            if onScreen then
                validCount = validCount + 1
                table.insert(corners2D, point2D)
            end
        end

        if validCount < 2 then
            -- Não exibe highlight
            if self.Highlight.OutlineDrawing then self.Highlight.OutlineDrawing.Visible = false end
            if self.Highlight.FillDrawing then self.Highlight.FillDrawing.Visible = false end
            return
        end

        -- Calcula bounding box 2D mínimo
        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge
        for _, p in pairs(corners2D) do
            if p.X < minX then minX = p.X end
            if p.Y < minY then minY = p.Y end
            if p.X > maxX then maxX = p.X end
            if p.Y > maxY then maxY = p.Y end
        end

        -- Define vertices para Quad (Fill)
        if self.Highlight.Fill and self.Highlight.FillDrawing then
            self.Highlight.FillDrawing.Visible = true
            self.Highlight.FillDrawing.PointA = Vector2.new(minX, minY)
            self.Highlight.FillDrawing.PointB = Vector2.new(maxX, minY)
            self.Highlight.FillDrawing.PointC = Vector2.new(maxX, maxY)
            self.Highlight.FillDrawing.PointD = Vector2.new(minX, maxY)
            self.Highlight.FillDrawing.Color = self.Highlight.FillColor
            self.Highlight.FillDrawing.Transparency = self.Highlight.FillOpacity
        end

        -- Define linhas para Outline (contorno do retângulo)
        if self.Highlight.Outline and self.Highlight.OutlineDrawing then
            -- Como Drawing.Line é só 1 linha, pra contorno teríamos que criar 4 linhas, mas simplifico aqui só pra 1 linha visível (a ideia pode ser expandida)
            -- Para a simplicidade do loadstring, vou usar um retângulo desenhado com 4 linhas desenhadas com 4 Drawing.Line (aviso: a limitação)
            -- Aqui, desativa linha antiga para evitar artefatos
            self.Highlight.OutlineDrawing.Visible = false
            -- Você pode expandir criando 4 linhas e armazenando em self.Highlight.OutlineLines se quiser
        end
    end

    -- Name label
    if self.Name and self.Name.TextDrawing then
        local screenPos, onScreen = ToScreenPoint(pos + Vector3.new(0, 2, 0))
        if onScreen then
            self.Name.TextDrawing.Visible = true
            self.Name.TextDrawing.Position = Vector2.new(screenPos.X, screenPos.Y)
            self.Name.TextDrawing.Color = self.Name.Color
            self.Name.TextDrawing.Text = self.Name.Text
            self.Name.TextDrawing.Transparency = self.Name.Opacity
        else
            self.Name.TextDrawing.Visible = false
        end
    end

    -- Distance label
    if self.Distance and self.Distance.Enabled and self.Distance.TextDrawing then
        local dist = (pos - Camera.CFrame.Position).Magnitude
        local screenPos, onScreen = ToScreenPoint(pos + Vector3.new(0, 1.5, 0))
        if onScreen then
            self.Distance.TextDrawing.Visible = true
            self.Distance.TextDrawing.Position = Vector2.new(screenPos.X, screenPos.Y)
            self.Distance.TextDrawing.Text = string.format("%.1fm", dist)
            self.Distance.TextDrawing.Color = self.Distance.Color
            self.Distance.TextDrawing.Transparency = self.Distance.Opacity
        else
            self.Distance.TextDrawing.Visible = false
        end
    end
end

-- Destruir ESP
function ESP:Destroy()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    if self.Tracer and self.Tracer.Line then
        self.Tracer.Line:Remove()
    end
    if self.Highlight then
        if self.Highlight.OutlineDrawing then
            self.Highlight.OutlineDrawing:Remove()
        end
        if self.Highlight.FillDrawing then
            self.Highlight.FillDrawing:Remove()
        end
    end
    if self.Name and self.Name.TextDrawing then
        self.Name.TextDrawing:Remove()
    end
    if self.Distance and self.Distance.TextDrawing then
        self.Distance.TextDrawing:Remove()
    end
    Kolt.ActiveESPs[self.Target] = nil
end

-- Kolt.Destroy global (para destruir pelo target)
function Kolt:Destroy(target)
    local esp = self.ActiveESPs[target]
    if esp then
        esp:Destroy()
    end
end

-- Modificar configurações do ESP
function Kolt:Modify(target, newConfig)
    local esp = self.ActiveESPs[target]
    if not esp then return end

    -- Exemplo de modificação simples (só para Highlight e Tracer)
    if newConfig.Tracer then
        esp.Tracer.Color = newConfig.Tracer.Color or esp.Tracer.Color
        esp.Tracer.Origin = newConfig.Tracer.Origin or esp.Tracer.Origin
        esp.Tracer.Opacity = newConfig.Tracer.Opacity or esp.Tracer.Opacity
        if esp.Tracer.Line then
            esp.Tracer.Line.Color = esp.Tracer.Color
            esp.Tracer.Line.Transparency = esp.Tracer.Opacity
        end
    end
    if newConfig.Highlight then
        esp.Highlight.Outline = newConfig.Highlight.Outline or esp.Highlight.Outline
        esp.Highlight.Fill = newConfig.Highlight.Fill or esp.Highlight.Fill
        esp.Highlight.OutlineColor = newConfig.Highlight.OutlineColor or esp.Highlight.OutlineColor
        esp.Highlight.FillColor = newConfig.Highlight.FillColor or esp.Highlight.FillColor
        esp.Highlight.OutlineOpacity = newConfig.Highlight.OutlineOpacity or esp.Highlight.OutlineOpacity
        esp.Highlight.FillOpacity = newConfig.Highlight.FillOpacity or esp.Highlight.FillOpacity
        if esp.Highlight.OutlineDrawing then
            esp.Highlight.OutlineDrawing.Color = esp.Highlight.OutlineColor
            esp.Highlight.OutlineDrawing.Transparency = esp.Highlight.OutlineOpacity
        end
        if esp.Highlight.FillDrawing then
            esp.Highlight.FillDrawing.Color = esp.Highlight.FillColor
            esp.Highlight.FillDrawing.Transparency = esp.Highlight.FillOpacity
        end
    end
    if newConfig.Name then
        esp.Name.Text = newConfig.Name.Text or esp.Name.Text
        esp.Name.Color = newConfig.Name.Color or esp.Name.Color
        esp.Name.Opacity = newConfig.Name.Opacity or esp.Name.Opacity
        if esp.Name.TextDrawing then
            esp.Name.TextDrawing.Text = esp.Name.Text
            esp.Name.TextDrawing.Color = esp.Name.Color
            esp.Name.TextDrawing.Transparency = esp.Name.Opacity
        end
    end
    if newConfig.Distance then
        esp.Distance.Enabled = newConfig.Distance.Enabled or esp.Distance.Enabled
        esp.Distance.Color = newConfig.Distance.Color or esp.Distance.Color
        esp.Distance.Opacity = newConfig.Distance.Opacity or esp.Distance.Opacity
        if esp.Distance.TextDrawing then
            esp.Distance.TextDrawing.Color = esp.Distance.Color
            esp.Distance.TextDrawing.Transparency = esp.Distance.Opacity
        end
    end
end

return Kolt
