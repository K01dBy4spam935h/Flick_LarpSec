--[[
    LarpSec · ESP + Radar + Arrows + Chams (Highlight)
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera
local CoreGui          = game:GetService("CoreGui")

local ESP = {}

ESP.Config = {
    Enabled     = true,
    Boxes       = true,
    Names       = true,
    Distance    = true,
    Tracers     = false,
    TracerFrom  = "Bottom",
    MaxDistance = 800,
    Color       = Color3.fromRGB(74, 144, 226), -- boxes/tracers
    NameColor   = Color3.fromRGB(255, 255, 255),
    DistColor   = Color3.fromRGB(200, 200, 210),
    Chams       = false,
    ChamsColor  = Color3.fromRGB(74, 144, 226),
    ChamsFill   = 0.45,
    ChamsOutline= true,
    Radar       = false,
    RadarSize   = 140,
    Arrows      = false,
    Font        = "UI", -- Drawing font: UI, System, Plex, Monospace
    NameOrigin  = "Username", -- Username | DisplayName
    ColorMode   = "Static", -- Static | Rainbow
    RainbowSpeed= 0.15,
}

local drawings = {}
local chamsMap = {} -- [player] = Highlight
local radarGui, radarFrame
local radarDots = {}

local FONT_MAP = {
    UI = 0,
    System = 1,
    Plex = 2,
    Monospace = 3,
}

local function getChar(p) return p and p.Character end
local function getHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function getRoot(c)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
end

local function rainbowColor()
    local h = (tick() * ESP.Config.RainbowSpeed) % 1
    return Color3.fromHSV(h, 0.9, 1)
end

local function activeColor(base)
    if ESP.Config.ColorMode == "Rainbow" then
        return rainbowColor()
    end
    return base
end

local function ensureDraw(plr)
    if drawings[plr] then return drawings[plr] end
    local t = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        dist = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
        arrow = Drawing.new("Triangle"),
    }
    t.box.Thickness = 1
    t.box.Filled = false
    t.box.Visible = false
    t.name.Size = 14
    t.name.Center = true
    t.name.Outline = true
    t.name.Visible = false
    t.dist.Size = 13
    t.dist.Center = true
    t.dist.Outline = true
    t.dist.Visible = false
    t.tracer.Thickness = 1
    t.tracer.Visible = false
    t.arrow.Filled = true
    t.arrow.Thickness = 1
    t.arrow.Visible = false
    drawings[plr] = t
    return t
end

local function hideDraw(t)
    if not t then return end
    t.box.Visible = false
    t.name.Visible = false
    t.dist.Visible = false
    t.tracer.Visible = false
    t.arrow.Visible = false
end

local function clearChams(plr)
    local h = chamsMap[plr]
    if h then
        pcall(function() h:Destroy() end)
        chamsMap[plr] = nil
    end
end

local function applyChams(plr)
    if not ESP.Config.Chams or not ESP.Config.Enabled then
        clearChams(plr)
        return
    end
    local char = getChar(plr)
    if not char then clearChams(plr) return end

    local hl = chamsMap[plr]
    if not hl or not hl.Parent then
        clearChams(plr)
        hl = Instance.new("Highlight")
        hl.Name = "LarpSecChams"
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillTransparency = ESP.Config.ChamsFill
        hl.OutlineTransparency = ESP.Config.ChamsOutline and 0 or 1
        hl.Parent = char
        chamsMap[plr] = hl
    end
    hl.Adornee = char
    local c = activeColor(ESP.Config.ChamsColor)
    hl.FillColor = c
    hl.OutlineColor = Color3.new(
        math.min(1, c.R + 0.25),
        math.min(1, c.G + 0.25),
        math.min(1, c.B + 0.25)
    )
    hl.FillTransparency = ESP.Config.ChamsFill
    hl.OutlineTransparency = ESP.Config.ChamsOutline and 0 or 1
end

local function ensureRadar()
    if radarGui then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "LarpSecRadar"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = CoreGui end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    radarGui = gui

    local size = ESP.Config.RadarSize
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, size, 0, size)
    frame.Position = UDim2.new(1, -size - 16, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 70)
    stroke.Thickness = 1
    stroke.Parent = frame
    radarFrame = frame

    local center = Instance.new("Frame")
    center.Size = UDim2.new(0, 6, 0, 6)
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Position = UDim2.new(0.5, 0, 0.5, 0)
    center.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    center.BorderSizePixel = 0
    center.Parent = frame
    Instance.new("UICorner", center).CornerRadius = UDim.new(1, 0)

    local dragging, dragStart, startPos
    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = frame.Position
        end
    end)
    frame.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

local function updateRadar()
    ensureRadar()
    radarGui.Enabled = ESP.Config.Radar
    if not ESP.Config.Radar then return end
    local myRoot = getRoot(LocalPlayer.Character)
    if not myRoot or not Camera then return end
    local look = Camera.CFrame.LookVector
    local yaw = math.atan2(look.X, look.Z)
    local range = 200
    local half = ESP.Config.RadarSize / 2
    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local root = getRoot(getChar(plr))
        local hum = getHum(getChar(plr))
        if not root or not hum or hum.Health <= 0 then continue end
        seen[plr] = true
        local rel = root.Position - myRoot.Position
        local rx = rel.X * math.cos(yaw) - rel.Z * math.sin(yaw)
        local rz = rel.X * math.sin(yaw) + rel.Z * math.cos(yaw)
        local nx = (rx / range) * (half - 6)
        local ny = (-rz / range) * (half - 6)
        local dist = math.sqrt(nx * nx + ny * ny)
        if dist > half - 6 then
            local s = (half - 6) / dist
            nx, ny = nx * s, ny * s
        end
        local dot = radarDots[plr]
        if not dot then
            dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 5, 0, 5)
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.BorderSizePixel = 0
            dot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
            Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
            dot.Parent = radarFrame
            radarDots[plr] = dot
        end
        dot.Position = UDim2.new(0.5, nx, 0.5, ny)
        dot.Visible = true
    end
    for plr, dot in pairs(radarDots) do
        if not seen[plr] then dot.Visible = false end
    end
end

local function arrowFor(plr, t, root, col)
    if not ESP.Config.Arrows then
        t.arrow.Visible = false
        return
    end
    local sp, onScreen = Camera:WorldToViewportPoint(root.Position)
    if onScreen and sp.Z > 0 then
        t.arrow.Visible = false
        return
    end
    local viewport = Camera.ViewportSize
    local cx, cy = viewport.X / 2, viewport.Y / 2
    local dir = Vector2.new(sp.X - cx, sp.Y - cy)
    if sp.Z < 0 then dir = -dir end
    if dir.Magnitude < 1 then dir = Vector2.new(0, -1) end
    dir = dir.Unit
    local radius = math.min(cx, cy) * 0.42
    local pos = Vector2.new(cx, cy) + dir * radius
    local ang = math.atan2(dir.Y, dir.X)
    local size = 8
    t.arrow.PointA = pos
    t.arrow.PointB = pos + Vector2.new(math.cos(ang + 2.5), math.sin(ang + 2.5)) * size
    t.arrow.PointC = pos + Vector2.new(math.cos(ang - 2.5), math.sin(ang - 2.5)) * size
    t.arrow.Color = col
    t.arrow.Visible = true
end

function ESP.Init()
    RunService.RenderStepped:Connect(function()
        if ESP.Config.Radar then updateRadar() elseif radarGui then radarGui.Enabled = false end

        local fontId = FONT_MAP[ESP.Config.Font] or 0
        local boxCol = activeColor(ESP.Config.Color)

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr == LocalPlayer then continue end
            local t = ensureDraw(plr)
            local char = getChar(plr)
            local hum = getHum(char)
            local root = getRoot(char)
            if not ESP.Config.Enabled or not char or not hum or hum.Health <= 0 or not root then
                hideDraw(t)
                clearChams(plr)
                continue
            end
            local dist = 0
            local myRoot = getRoot(LocalPlayer.Character)
            if myRoot then dist = (root.Position - myRoot.Position).Magnitude end
            if dist > ESP.Config.MaxDistance then
                hideDraw(t)
                clearChams(plr)
                continue
            end

            applyChams(plr)

            local top = root.Position + Vector3.new(0, 3, 0)
            local bottom = root.Position - Vector3.new(0, 3, 0)
            local sp, on = Camera:WorldToViewportPoint(root.Position)
            local topS = Camera:WorldToViewportPoint(top)
            local botS = Camera:WorldToViewportPoint(bottom)
            local h = math.abs(topS.Y - botS.Y)
            local w = h * 0.6

            if ESP.Config.Boxes and on and sp.Z > 0 then
                t.box.Size = Vector2.new(w, h)
                t.box.Position = Vector2.new(sp.X - w / 2, sp.Y - h / 2)
                t.box.Color = boxCol
                t.box.Visible = true
            else
                t.box.Visible = false
            end

            if ESP.Config.Names and on and sp.Z > 0 then
                local label = plr.Name
                if ESP.Config.NameOrigin == "DisplayName" then
                    label = plr.DisplayName or plr.Name
                end
                t.name.Text = label
                t.name.Position = Vector2.new(sp.X, sp.Y - h / 2 - 14)
                t.name.Color = activeColor(ESP.Config.NameColor)
                pcall(function() t.name.Font = fontId end)
                t.name.Visible = true
            else
                t.name.Visible = false
            end

            if ESP.Config.Distance and on and sp.Z > 0 then
                t.dist.Text = string.format("%dm", math.floor(dist))
                t.dist.Position = Vector2.new(sp.X, sp.Y + h / 2 + 2)
                t.dist.Color = activeColor(ESP.Config.DistColor)
                pcall(function() t.dist.Font = fontId end)
                t.dist.Visible = true
            else
                t.dist.Visible = false
            end

            if ESP.Config.Tracers and on and sp.Z > 0 then
                local from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                if ESP.Config.TracerFrom == "Center" then
                    from = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                elseif ESP.Config.TracerFrom == "Mouse" then
                    from = UserInputService:GetMouseLocation()
                elseif ESP.Config.TracerFrom == "Top" then
                    from = Vector2.new(Camera.ViewportSize.X / 2, 0)
                end
                t.tracer.From = from
                t.tracer.To = Vector2.new(sp.X, sp.Y)
                t.tracer.Color = boxCol
                t.tracer.Visible = true
            else
                t.tracer.Visible = false
            end

            arrowFor(plr, t, root, boxCol)
        end
    end)

    Players.PlayerRemoving:Connect(function(plr)
        local t = drawings[plr]
        if t then
            for _, d in pairs(t) do pcall(function() d:Remove() end) end
            drawings[plr] = nil
        end
        clearChams(plr)
        if radarDots[plr] then
            radarDots[plr]:Destroy()
            radarDots[plr] = nil
        end
    end)
end

return ESP
