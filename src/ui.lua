--[[
    LarpSec - Flick v1 · UI
]]

local UI = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local Themes = {
    Default = {
        Background = Color3.fromRGB(21, 21, 21),
        Groupbox   = Color3.fromRGB(30, 30, 30),
        Border     = Color3.fromRGB(46, 46, 46),
        Accent     = Color3.fromRGB(74, 144, 226),
        Text       = Color3.fromRGB(255, 255, 255),
        GradA      = Color3.fromRGB(28, 28, 32),
        GradB      = Color3.fromRGB(38, 48, 68),
        AnimA      = Color3.fromRGB(20, 24, 40),
        AnimB      = Color3.fromRGB(40, 50, 90),
    },
    Ubuntu = {
        Background = Color3.fromRGB(44, 0, 30),
        Groupbox   = Color3.fromRGB(60, 20, 40),
        Border     = Color3.fromRGB(120, 50, 30),
        Accent     = Color3.fromRGB(233, 84, 32),
        Text       = Color3.fromRGB(255, 240, 230),
        GradA      = Color3.fromRGB(60, 20, 40),
        GradB      = Color3.fromRGB(140, 50, 20),
        AnimA      = Color3.fromRGB(50, 10, 30),
        AnimB      = Color3.fromRGB(160, 60, 20),
    },
    Tokyo = {
        Background = Color3.fromRGB(26, 27, 38),
        Groupbox   = Color3.fromRGB(36, 40, 59),
        Border     = Color3.fromRGB(65, 72, 104),
        Accent     = Color3.fromRGB(122, 162, 247),
        Text       = Color3.fromRGB(192, 202, 245),
        GradA      = Color3.fromRGB(36, 40, 59),
        GradB      = Color3.fromRGB(80, 50, 120),
        AnimA      = Color3.fromRGB(30, 35, 70),
        AnimB      = Color3.fromRGB(90, 50, 140),
    },
    Blossom = {
        Background = Color3.fromRGB(40, 28, 36),
        Groupbox   = Color3.fromRGB(58, 40, 50),
        Border     = Color3.fromRGB(120, 70, 90),
        Accent     = Color3.fromRGB(255, 140, 180),
        Text       = Color3.fromRGB(255, 230, 240),
        GradA      = Color3.fromRGB(58, 40, 50),
        GradB      = Color3.fromRGB(120, 50, 80),
        AnimA      = Color3.fromRGB(50, 30, 45),
        AnimB      = Color3.fromRGB(140, 60, 100),
    },
    Midnight = {
        Background = Color3.fromRGB(8, 10, 24),
        Groupbox   = Color3.fromRGB(16, 20, 40),
        Border     = Color3.fromRGB(40, 55, 100),
        Accent     = Color3.fromRGB(90, 130, 255),
        Text       = Color3.fromRGB(210, 220, 255),
        GradA      = Color3.fromRGB(16, 20, 40),
        GradB      = Color3.fromRGB(40, 25, 70),
        AnimA      = Color3.fromRGB(10, 15, 40),
        AnimB      = Color3.fromRGB(50, 30, 100),
    },
    Dark = {
        Background = Color3.fromRGB(8, 8, 8),
        Groupbox   = Color3.fromRGB(18, 18, 18),
        Border     = Color3.fromRGB(36, 36, 36),
        Accent     = Color3.fromRGB(200, 200, 200),
        Text       = Color3.fromRGB(230, 230, 230),
        GradA      = Color3.fromRGB(18, 18, 18),
        GradB      = Color3.fromRGB(40, 40, 40),
        AnimA      = Color3.fromRGB(12, 12, 12),
        AnimB      = Color3.fromRGB(45, 45, 45),
    },
    Hacker = {
        Background = Color3.fromRGB(4, 12, 4),
        Groupbox   = Color3.fromRGB(10, 24, 10),
        Border     = Color3.fromRGB(20, 70, 20),
        Accent     = Color3.fromRGB(0, 255, 70),
        Text       = Color3.fromRGB(180, 255, 180),
        GradA      = Color3.fromRGB(10, 24, 10),
        GradB      = Color3.fromRGB(15, 55, 20),
        AnimA      = Color3.fromRGB(5, 20, 5),
        AnimB      = Color3.fromRGB(20, 80, 25),
    },
}

local UI_FONTS = {
    "Gotham", "GothamBold", "SourceSans", "SourceSansBold",
    "Code", "Fantasy", "Arcade", "Bodoni", "Garamond", "Oswald"
}

local function getExecutorName()
    local name
    pcall(function()
        if identifyexecutor then
            name = identifyexecutor()
        end
    end)
    if not name or name == "" then
        pcall(function()
            if getexecutorname then name = getexecutorname() end
        end)
    end
    if not name or name == "" then
        pcall(function()
            if syn and syn.request then name = "Synapse" end
        end)
    end
    if not name or name == "" then name = "Unknown" end
    return tostring(name)
end

local function applyGradient(frame, theme, rot)
    if not frame then return end
    local g = frame:FindFirstChildOfClass("UIGradient")
    if not g then
        g = Instance.new("UIGradient")
        g.Parent = frame
    end
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.GradA),
        ColorSequenceKeypoint.new(1, theme.GradB),
    })
    g.Rotation = rot or 90
end

local animToken = 0
local function startAnimatedBackground(window, theme)
    animToken = animToken + 1
    local token = animToken
    local root = window.Frame
    if not root then return end
    -- gradient lives ON the window frame so it is actually visible
    root.BackgroundColor3 = Color3.new(1, 1, 1)
    local g = root:FindFirstChild("WindowGrad")
    if not g then
        g = Instance.new("UIGradient")
        g.Name = "WindowGrad"
        g.Parent = root
    end
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, theme.AnimA),
        ColorSequenceKeypoint.new(0.5, theme.GradA),
        ColorSequenceKeypoint.new(1, theme.AnimB),
    })
    task.spawn(function()
        local rot = 0
        while token == animToken and root.Parent do
            rot = (rot + 0.4) % 360
            g.Rotation = rot
            task.wait(0.03)
        end
    end)
end

local function applyTheme(window, themeName, fontName)
    local theme = Themes[themeName] or Themes.Default
    pcall(function()
        local root = window.Frame
        if not root then return end
        startAnimatedBackground(window, theme)
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("Frame") then
                local n = d.Name:lower()
                if n:find("group") or n:find("box") or n:find("content") or n:find("sidebar") then
                    d.BackgroundColor3 = theme.Groupbox
                    applyGradient(d, theme, 90)
                end
                if n:find("fill") or n:find("bar") or n == "sliderfill" or n == "accent" then
                    d.BackgroundColor3 = theme.Accent
                    local gr = d:FindFirstChildOfClass("UIGradient")
                    if not gr then
                        gr = Instance.new("UIGradient")
                        gr.Parent = d
                    end
                    gr.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, theme.Accent),
                        ColorSequenceKeypoint.new(1, Color3.new(
                            math.min(1, theme.Accent.R + 0.25),
                            math.min(1, theme.Accent.G + 0.2),
                            math.min(1, theme.Accent.B + 0.15)
                        )),
                    })
                end
            end
            if d:IsA("UIStroke") then
                d.Color = theme.Border
            end
            if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                if d.TextColor3.R > 0.45 then
                    d.TextColor3 = theme.Text
                end
                if fontName then
                    pcall(function() d.Font = Enum.Font[fontName] end)
                end
            end
        end
    end)
end

local function openColorPicker(parentGui, current, onChange)
    local existing = parentGui:FindFirstChild("ColorPickerPopup")
    if existing then existing:Destroy() end

    local popup = Instance.new("Frame")
    popup.Name = "ColorPickerPopup"
    popup.Size = UDim2.new(0, 240, 0, 230)
    popup.Position = UDim2.new(0.5, -120, 0.5, -115)
    popup.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    popup.BorderSizePixel = 0
    popup.ZIndex = 80
    popup.Parent = parentGui
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 6)

    local h, s, v = Color3.toHSV(current or Color3.fromRGB(74, 144, 226))
    local mode = "Static"

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -12, 0, 18)
    title.Position = UDim2.new(0, 8, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "HSV Color Canvas"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextSize = 12
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 81
    title.Parent = popup

    local sv = Instance.new("ImageButton")
    sv.Size = UDim2.new(0, 170, 0, 120)
    sv.Position = UDim2.new(0, 10, 0, 28)
    sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    sv.BorderSizePixel = 0
    sv.ZIndex = 81
    sv.AutoButtonColor = false
    sv.Parent = popup

    local white = Instance.new("Frame")
    white.Size = UDim2.new(1, 0, 1, 0)
    white.BackgroundColor3 = Color3.new(1, 1, 1)
    white.BorderSizePixel = 0
    white.ZIndex = 82
    white.Parent = sv
    local wg = Instance.new("UIGradient")
    wg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1),
    })
    wg.Parent = white

    local black = Instance.new("Frame")
    black.Size = UDim2.new(1, 0, 1, 0)
    black.BackgroundColor3 = Color3.new(0, 0, 0)
    black.BorderSizePixel = 0
    black.ZIndex = 83
    black.Parent = sv
    local bg = Instance.new("UIGradient")
    bg.Rotation = 90
    bg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0),
    })
    bg.Parent = black

    local hueBar = Instance.new("ImageButton")
    hueBar.Size = UDim2.new(0, 18, 0, 120)
    hueBar.Position = UDim2.new(0, 190, 0, 28)
    hueBar.BorderSizePixel = 0
    hueBar.ZIndex = 81
    hueBar.AutoButtonColor = false
    hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
    hueBar.Parent = popup
    local hg = Instance.new("UIGradient")
    hg.Rotation = 90
    local keys = {}
    for i = 0, 6 do
        table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
    end
    hg.Color = ColorSequence.new(keys)
    hg.Parent = hueBar

    local staticStrip = Instance.new("Frame")
    staticStrip.Size = UDim2.new(0, 200, 0, 10)
    staticStrip.Position = UDim2.new(0, 10, 0, 154)
    staticStrip.BorderSizePixel = 0
    staticStrip.ZIndex = 81
    staticStrip.BackgroundColor3 = Color3.new(1, 1, 1)
    staticStrip.Parent = popup
    local sg = Instance.new("UIGradient")
    local sk = {}
    for i = 0, 6 do
        table.insert(sk, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 0.85, 1)))
    end
    sg.Color = ColorSequence.new(sk)
    sg.Parent = staticStrip

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 36, 0, 18)
    preview.Position = UDim2.new(0, 10, 0, 172)
    preview.BorderSizePixel = 0
    preview.ZIndex = 81
    preview.BackgroundColor3 = Color3.fromHSV(h, s, v)
    preview.Parent = popup

    local hex = Instance.new("TextLabel")
    hex.Size = UDim2.new(0, 90, 0, 18)
    hex.Position = UDim2.new(0, 52, 0, 172)
    hex.BackgroundTransparency = 1
    hex.TextColor3 = Color3.new(1, 1, 1)
    hex.TextSize = 12
    hex.Font = Enum.Font.Code
    hex.TextXAlignment = Enum.TextXAlignment.Left
    hex.ZIndex = 81
    hex.Parent = popup

    local modeLbl = Instance.new("TextLabel")
    modeLbl.Size = UDim2.new(0, 80, 0, 18)
    modeLbl.Position = UDim2.new(0, 145, 0, 172)
    modeLbl.BackgroundTransparency = 1
    modeLbl.TextColor3 = Color3.fromRGB(180, 180, 200)
    modeLbl.TextSize = 11
    modeLbl.Font = Enum.Font.Gotham
    modeLbl.Text = mode
    modeLbl.ZIndex = 81
    modeLbl.Parent = popup

    local function emit()
        local c
        if mode == "Rainbow" then
            c = Color3.fromHSV((tick() * 0.2) % 1, 0.9, 1)
        elseif mode == "StaticRainbow" then
            c = Color3.fromRGB(255, 40, 180)
        else
            c = Color3.fromHSV(h, s, v)
        end
        preview.BackgroundColor3 = c
        hex.Text = string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
        modeLbl.Text = mode
        onChange(c, mode)
    end
    emit()

    local UIS = game:GetService("UserInputService")
    local dragSV, dragH
    local function pickSV(input)
        local rel = Vector2.new(input.Position.X, input.Position.Y) - sv.AbsolutePosition
        s = math.clamp(rel.X / sv.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp(rel.Y / sv.AbsoluteSize.Y, 0, 1)
        mode = "Static"
        emit()
    end
    local function pickH(input)
        local rel = (input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y
        h = math.clamp(rel, 0, 1)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        mode = "Static"
        emit()
    end
    sv.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragSV = true pickSV(i) end
    end)
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragH = true pickH(i) end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragSV, dragH = false, false end
    end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if dragSV then pickSV(i) end
        if dragH then pickH(i) end
    end)

    local function btn(text, x, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 52, 0, 22)
        b.Position = UDim2.new(0, x, 0, 198)
        b.BackgroundColor3 = Color3.fromRGB(40, 42, 55)
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 11
        b.Font = Enum.Font.Gotham
        b.ZIndex = 81
        b.Parent = popup
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(cb)
    end

    btn("RGB", 10, function()
        mode = "Static"
        local prim = {
            Color3.fromRGB(255, 40, 40),
            Color3.fromRGB(40, 255, 80),
            Color3.fromRGB(40, 120, 255),
            Color3.fromRGB(255, 220, 40),
        }
        local c = prim[((math.floor(tick()) % 4) + 1)]
        h, s, v = Color3.toHSV(c)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        emit()
    end)
    btn("Rainbow", 66, function()
        mode = "Rainbow"
        emit()
    end)
    btn("StaticR", 122, function()
        mode = "StaticRainbow"
        emit()
    end)
    btn("Close", 178, function()
        popup:Destroy()
    end)

    task.spawn(function()
        while popup.Parent do
            if mode == "Rainbow" then emit() end
            task.wait(0.05)
        end
    end)
end

function UI.Init(Silent, ESP, Anti, Perf, Config, KillSound)
    local Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/K01dBy4spam935h/Flick_LarpSec/main/src/library.lua"
    ))()

    local Lib = Library.new({
        Title = "LarpSec - Flick v1",
        ToggleKey = Enum.KeyCode.RightShift,
    })

    local Window = Lib:CreateWindow({
        Title = "LarpSec - Flick v1",
        Size = Vector2.new(620, 540),
    })

    local function guiRoot()
        return Lib.ScreenGui or game:GetService("CoreGui"):FindFirstChild("FlickLib")
    end

    local currentTheme = "Default"
    local currentUIFont = "Gotham"

    -- ── Main ────────────────────────────────────────────────
    local TabMain = Window:CreateTab("Main")
    local GBServer = TabMain:CreateGroupbox("Server", "Left")
    local GBAnti = TabMain:CreateGroupbox("Anti-Cheat", "Right")
    local GBPlayers = TabMain:CreateGroupbox("Players", "Left")

    local executorName = getExecutorName()
    GBServer:AddLabel("Executor: " .. executorName)
    GBServer:AddLabel("JobId: " .. tostring(game.JobId))
    local playersLabel = GBServer:AddLabel("Players: " .. tostring(#Players:GetPlayers()))
    local pingLabel = GBServer:AddLabel("Latency: -- ms")

    local statusLabel = GBAnti:AddLabel("AC: checking...")
    local function setStatusVisual(status)
        local text = "AC: " .. status
        if status == "bypassed" then
            text = "AC: BYPASSED"
        elseif status == "detected" then
            text = "AC: DETECTED"
        else
            text = "AC: ISSUE"
        end
        -- labels may not support color; text is enough
        pcall(function()
            if statusLabel and statusLabel.Set then statusLabel:Set(text) end
        end)
        -- try find text label under groupbox
        pcall(function()
            for _, d in ipairs(Window.Frame:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text:find("AC:") then
                    d.Text = text
                    if status == "bypassed" then
                        d.TextColor3 = Color3.fromRGB(80, 255, 120)
                    elseif status == "detected" then
                        d.TextColor3 = Color3.fromRGB(255, 70, 70)
                    else
                        d.TextColor3 = Color3.fromRGB(255, 170, 60)
                    end
                end
            end
        end)
    end

    task.defer(function()
        task.wait(2.5)
        setStatusVisual(Anti.GetStatus and Anti.GetStatus() or (Anti.IsBypassed and Anti.IsBypassed() and "bypassed" or "issue"))
    end)

    GBAnti:AddDropdown({
        Text = "Auto Resolve",
        Values = {"Run"},
        Default = "Run",
        Callback = function()
            local st = "issue"
            pcall(function()
                if Anti.Resolve then st = Anti.Resolve() else Anti.Init() st = Anti.GetStatus and Anti.GetStatus() or "issue" end
            end)
            setStatusVisual(st)
        end,
    })

    -- player list dropdown (names only in lib dropdown; avatars in side panel)
    local function playerNames()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            table.insert(list, string.format("%s (%s)", p.DisplayName, p.Name))
        end
        table.sort(list)
        if #list == 0 then list = { "none" } end
        return list
    end

    GBPlayers:AddDropdown({
        Text = "Player List",
        Values = playerNames(),
        Default = playerNames()[1],
        Callback = function() end,
    })

    -- avatar strip under main (custom frame)
    task.defer(function()
        local root = Window.Frame
        if not root then return end
        local strip = Instance.new("ScrollingFrame")
        strip.Name = "PlayerStrip"
        strip.Size = UDim2.new(1, -20, 0, 84)
        strip.Position = UDim2.new(0, 10, 1, -92)
        strip.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
        strip.BackgroundTransparency = 0.3
        strip.BorderSizePixel = 0
        strip.ScrollBarThickness = 4
        strip.CanvasSize = UDim2.new(0, 0, 0, 0)
        strip.ZIndex = 5
        strip.Parent = root
        Instance.new("UICorner", strip).CornerRadius = UDim.new(0, 4)
        local lay = Instance.new("UIListLayout")
        lay.FillDirection = Enum.FillDirection.Horizontal
        lay.Padding = UDim.new(0, 6)
        lay.Parent = strip
        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingTop = UDim.new(0, 6)
        pad.Parent = strip

        local function refreshStrip()
            for _, c in ipairs(strip:GetChildren()) do
                if c:IsA("Frame") then c:Destroy() end
            end
            local x = 0
            for _, p in ipairs(Players:GetPlayers()) do
                local cell = Instance.new("Frame")
                cell.Size = UDim2.new(0, 64, 0, 70)
                cell.BackgroundTransparency = 1
                cell.Parent = strip
                local img = Instance.new("ImageLabel")
                img.Size = UDim2.new(0, 44, 0, 44)
                img.Position = UDim2.new(0.5, -22, 0, 2)
                img.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
                img.BorderSizePixel = 0
                img.Parent = cell
                Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
                img.Image = string.format(
                    "rbxthumb://type=AvatarHeadShot&id=%d&w=48&h=48",
                    p.UserId
                )
                local nm = Instance.new("TextLabel")
                nm.Size = UDim2.new(1, 0, 0, 14)
                nm.Position = UDim2.new(0, 0, 0, 48)
                nm.BackgroundTransparency = 1
                nm.Text = p.DisplayName
                nm.TextColor3 = Color3.fromRGB(220, 220, 230)
                nm.TextSize = 10
                nm.Font = Enum.Font.Gotham
                nm.TextTruncate = Enum.TextTruncate.AtEnd
                nm.Parent = cell
                x = x + 70
            end
            strip.CanvasSize = UDim2.new(0, math.max(x, 100), 0, 0)
            pcall(function()
                if type(playersLabel) == "table" and playersLabel.Set then
                    playersLabel:Set("Players: " .. tostring(#Players:GetPlayers()))
                end
                for _, d in ipairs(root:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text:find("Players:") then
                        d.Text = "Players: " .. tostring(#Players:GetPlayers())
                    end
                end
            end)
        end
        refreshStrip()
        Players.PlayerAdded:Connect(function() task.defer(refreshStrip) end)
        Players.PlayerRemoving:Connect(function() task.defer(refreshStrip) end)

        task.spawn(function()
            while root.Parent do
                local ping = 0
                pcall(function()
                    ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
                end)
                pcall(function()
                    for _, d in ipairs(root:GetDescendants()) do
                        if d:IsA("TextLabel") and d.Text:find("Latency:") then
                            d.Text = "Latency: " .. tostring(ping) .. " ms"
                        end
                    end
                    if Anti and Anti.GetStatus then
                        setStatusVisual(Anti.GetStatus())
                    end
                end)
                task.wait(1)
            end
        end)
    end)

    -- ── Combat ──────────────────────────────────────────────
    local TabCombat = Window:CreateTab("Combat")
    local GBSilent = TabCombat:CreateGroupbox("Silent Aim", "Left")
    local GBBot = TabCombat:CreateGroupbox("Bots", "Right")

    GBSilent:AddToggle({Text = "Enabled", Default = Silent.Config.Enabled, Callback = function(v) Silent.Config.Enabled = v end})
    GBSilent:AddSlider({Text = "FOV", Min = 20, Max = 2000, Default = Silent.Config.FOV, Callback = function(v) Silent.Config.FOV = v end})
    GBSilent:AddSlider({Text = "Hit Chance", Min = 1, Max = 100, Default = Silent.Config.HitChance, Suffix = "%", Callback = function(v) Silent.Config.HitChance = v end})
    GBSilent:AddToggle({Text = "Show FOV", Default = Silent.Config.ShowFOV, Callback = function(v) Silent.Config.ShowFOV = v end})
    GBSilent:AddDropdown({
        Text = "Hit Part",
        Values = {"Torso", "Head", "HumanoidRootPart", "UpperTorso"},
        Default = "Torso",
        Callback = function(v)
            if v == "Torso" then Silent.Config.HitPart = "UpperTorso" Silent.Config.PreferTorso = true
            else Silent.Config.HitPart = v Silent.Config.PreferTorso = false end
        end,
    })
    GBSilent:AddToggle({Text = "Visible Check", Default = Silent.Config.VisibleCheck, Callback = function(v) Silent.Config.VisibleCheck = v end})
    GBSilent:AddToggle({Text = "Sticky Aim", Default = Silent.Config.Sticky, Callback = function(v) Silent.Config.Sticky = v end})
    GBSilent:AddDropdown({
        Text = "FOV Color Picker",
        Values = {"Open"},
        Default = "Open",
        Callback = function()
            local g = guiRoot()
            if g then openColorPicker(g, Silent.Config.FOVColor, function(c) Silent.Config.FOVColor = c end) end
        end,
    })

    GBBot:AddToggle({Text = "Triggerbot", Default = Silent.Config.Triggerbot, Callback = function(v) Silent.Config.Triggerbot = v end})
    GBBot:AddToggle({Text = "Auto Shoot", Default = Silent.Config.AutoShoot, Callback = function(v) Silent.Config.AutoShoot = v end})

    -- kill sound from user config
    if Config then
        local names = Config.GetKillSoundNames()
        local sel = Config.Get().selectedKillSound
        if not sel or sel == "" then sel = "Off" end
        GBBot:AddDropdown({
            Text = "Kill Sound",
            Values = names,
            Default = sel,
            Callback = function(name)
                Config.SetSelectedKillSound(name)
            end,
        })
        GBBot:AddDropdown({
            Text = "Preview Sound",
            Values = {"Play"},
            Default = "Play",
            Callback = function()
                if KillSound and KillSound.Preview then
                    KillSound.Preview()
                end
            end,
        })
    end

    -- ── Visuals ─────────────────────────────────────────────
    local TabVisuals = Window:CreateTab("Visuals")
    local GBWorld = TabVisuals:CreateGroupbox("World", "Left")
    local GBHud = TabVisuals:CreateGroupbox("HUD", "Right")

    GBWorld:AddToggle({Text = "Fullbright", Default = Perf.Config.Fullbright, Callback = function(v) Perf.Config.Fullbright = v Perf.Refresh() end})
    GBWorld:AddToggle({Text = "Fog", Default = Perf.Config.FogEnabled, Callback = function(v) Perf.Config.FogEnabled = v Perf.Refresh() end})
    GBWorld:AddSlider({Text = "Fog End", Min = 50, Max = 2000, Default = Perf.Config.FogEnd, Callback = function(v) Perf.Config.FogEnd = v Perf.Refresh() end})
    GBWorld:AddSlider({Text = "Stretch Res", Min = 10, Max = 20, Default = 10, Callback = function(v) Perf.Config.Stretch = v / 10 end})
    GBWorld:AddToggle({Text = "Third Person", Default = false, Callback = function(v) Perf.SetThirdPerson(v) end})

    GBHud:AddToggle({Text = "Radar", Default = ESP.Config.Radar, Callback = function(v) ESP.Config.Radar = v end})
    GBHud:AddToggle({Text = "Arrows", Default = ESP.Config.Arrows, Callback = function(v) ESP.Config.Arrows = v end})
    GBHud:AddDropdown({Text = "Crosshair", Values = {"Default", "Cross", "Dot", "Off"}, Default = "Default", Callback = function(v) Perf.SetCrosshair(v) end})
    GBHud:AddToggle({Text = "FPS / Ping", Default = Perf.Config.ShowFPS, Callback = function(v) Perf.Config.ShowFPS = v end})

    -- ── ESP ─────────────────────────────────────────────────
    local TabESP = Window:CreateTab("ESP")
    local GBESP = TabESP:CreateGroupbox("ESP", "Left")
    local GBStyle = TabESP:CreateGroupbox("Style", "Right")

    GBESP:AddToggle({Text = "Enabled", Default = ESP.Config.Enabled, Callback = function(v) ESP.Config.Enabled = v end})
    GBESP:AddToggle({Text = "Boxes", Default = ESP.Config.Boxes, Callback = function(v) ESP.Config.Boxes = v end})
    GBESP:AddToggle({Text = "Names", Default = ESP.Config.Names, Callback = function(v) ESP.Config.Names = v end})
    GBESP:AddToggle({Text = "Distance", Default = ESP.Config.Distance, Callback = function(v) ESP.Config.Distance = v end})
    GBESP:AddToggle({Text = "Tracers", Default = ESP.Config.Tracers, Callback = function(v) ESP.Config.Tracers = v end})
    GBESP:AddToggle({Text = "Chams", Default = ESP.Config.Chams, Callback = function(v) ESP.Config.Chams = v end})
    GBESP:AddToggle({Text = "Chams Outline", Default = true, Callback = function(v) ESP.Config.ChamsOutline = v end})
    GBESP:AddSlider({Text = "Chams Fill", Min = 0, Max = 90, Default = 45, Callback = function(v) ESP.Config.ChamsFill = v / 100 end})

    GBStyle:AddDropdown({
        Text = "Name Origin",
        Values = {"Username", "DisplayName"},
        Default = "Username",
        Callback = function(v) ESP.Config.NameOrigin = v end,
    })
    GBStyle:AddDropdown({
        Text = "ESP Font",
        Values = {"UI", "System", "Plex", "Monospace"},
        Default = "UI",
        Callback = function(v) ESP.Config.Font = v end,
    })
    GBStyle:AddDropdown({
        Text = "Color Mode",
        Values = {"Static", "Rainbow"},
        Default = "Static",
        Callback = function(v) ESP.Config.ColorMode = v end,
    })
    GBStyle:AddDropdown({
        Text = "Tracer Origin",
        Values = {"Bottom", "Center", "Mouse"},
        Default = ESP.Config.TracerFrom,
        Callback = function(v) ESP.Config.TracerFrom = v end,
    })
    GBStyle:AddSlider({Text = "Max Distance", Min = 100, Max = 2000, Default = ESP.Config.MaxDistance, Suffix = "m", Callback = function(v) ESP.Config.MaxDistance = v end})
    GBStyle:AddDropdown({
        Text = "Box/Tracer Color",
        Values = {"Open Picker"},
        Default = "Open Picker",
        Callback = function()
            local g = guiRoot()
            if g then openColorPicker(g, ESP.Config.Color, function(c, mode)
                ESP.Config.Color = c
                if mode == "Rainbow" then ESP.Config.ColorMode = "Rainbow" end
            end) end
        end,
    })
    GBStyle:AddDropdown({
        Text = "Name Color",
        Values = {"Open Picker"},
        Default = "Open Picker",
        Callback = function()
            local g = guiRoot()
            if g then openColorPicker(g, ESP.Config.NameColor, function(c) ESP.Config.NameColor = c end) end
        end,
    })
    GBStyle:AddDropdown({
        Text = "Distance Color",
        Values = {"Open Picker"},
        Default = "Open Picker",
        Callback = function()
            local g = guiRoot()
            if g then openColorPicker(g, ESP.Config.DistColor, function(c) ESP.Config.DistColor = c end) end
        end,
    })
    GBStyle:AddDropdown({
        Text = "Chams Color",
        Values = {"Open Picker"},
        Default = "Open Picker",
        Callback = function()
            local g = guiRoot()
            if g then openColorPicker(g, ESP.Config.ChamsColor, function(c) ESP.Config.ChamsColor = c end) end
        end,
    })

    -- ── Performance ─────────────────────────────────────────
    local TabPerf = Window:CreateTab("Performance")
    local GBPerf = TabPerf:CreateGroupbox("Optimize", "Left")
    local GBCull = TabPerf:CreateGroupbox("Culling", "Right")

    GBPerf:AddToggle({Text = "Optimize Lighting", Default = false, Callback = function(v) Perf.Config.OptimizeLighting = v Perf.Refresh() end})
    GBPerf:AddToggle({Text = "Optimize Textures", Default = false, Callback = function(v) Perf.Config.OptimizeTextures = v Perf.Refresh() end})
    GBPerf:AddToggle({Text = "Reduce Graphics", Default = false, Callback = function(v) Perf.Config.ReduceGraphics = v Perf.Refresh() end})
    GBPerf:AddToggle({Text = "Hide Shadows", Default = false, Callback = function(v) Perf.Config.HideShadows = v Perf.Refresh() end})
    GBPerf:AddToggle({Text = "Hide Particles", Default = false, Callback = function(v) Perf.Config.HideParticles = v Perf.Refresh() end})
    GBPerf:AddToggle({Text = "Optimize VFX", Default = false, Callback = function(v) Perf.Config.OptimizeVFX = v Perf.Refresh() end})
    GBCull:AddToggle({Text = "Culling", Default = false, Callback = function(v) Perf.Config.Culling = v Perf.Refresh() end})

    -- ── Config ──────────────────────────────────────────────
    local TabConfig = Window:CreateTab("Config")
    local GBTheme = TabConfig:CreateGroupbox("Theme", "Left")
    local GBFont = TabConfig:CreateGroupbox("Font", "Right")

    GBTheme:AddDropdown({
        Text = "Theme",
        Values = {"Default", "Ubuntu", "Tokyo", "Blossom", "Midnight", "Dark", "Hacker"},
        Default = "Default",
        Callback = function(name)
            currentTheme = name
            applyTheme(Window, name, currentUIFont)
        end,
    })
    GBFont:AddDropdown({
        Text = "UI Font",
        Values = UI_FONTS,
        Default = "Gotham",
        Callback = function(name)
            currentUIFont = name
            applyTheme(Window, currentTheme, name)
        end,
    })

    -- ── Beta ────────────────────────────────────────────────
    local TabBeta = Window:CreateTab("Beta")
    local GBBeta = TabBeta:CreateGroupbox("Experimental", "Left")
    GBBeta:AddToggle({Text = "No Reload", Default = Silent.Config.NoReload, Callback = function(v) Silent.Config.NoReload = v end})

    -- ── Info ────────────────────────────────────────────────
    local TabInfo = Window:CreateTab("Info")
    local GBInfo = TabInfo:CreateGroupbox("Features", "Left")
    local GBNoRel = TabInfo:CreateGroupbox("No Reload", "Right")
    local GBCtl = TabInfo:CreateGroupbox("Controls", "Left")
    local GBSnd = TabInfo:CreateGroupbox("Kill Sounds", "Right")

    GBInfo:AddLabel("LarpSec - Flick v1")
    GBInfo:AddLabel("Triggerbot: crosshair hit")
    GBInfo:AddLabel("AutoShoot: FOV + visible")
    GBInfo:AddLabel("Culling: clutter/shadows/VFX")
    GBInfo:AddLabel("Chams: Highlight fill+outline")

    GBNoRel:AddLabel("Status: experimental")
    GBNoRel:AddLabel("Lever: config reloadTime")
    GBNoRel:AddLabel("Not proven live timer")
    GBNoRel:AddLabel("Respawn rebind flaky")

    GBCtl:AddLabel("RightShift · menu")
    GBCtl:AddLabel("Title bar · drag")

    GBSnd:AddLabel("IDs live in your config")
    GBSnd:AddLabel("getgenv LarpSecUserConfig")
    GBSnd:AddLabel("or LarpSec_config.json")
    GBSnd:AddLabel("No default sound shipped")

    Window.Frame.Visible = true
    applyTheme(Window, "Default", "Gotham")
end

return UI
