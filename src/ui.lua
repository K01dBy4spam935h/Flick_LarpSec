--[[
    Flick · UI
    Combat / Visuals / ESP / Misc · topbar drag · correct selected tab
]]

local UI = {}

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local Theme = {
    Accent     = Color3.fromRGB(120, 90, 255),
    Background = Color3.fromRGB(15, 15, 20),
    Group      = Color3.fromRGB(20, 20, 26),
    Card       = Color3.fromRGB(28, 28, 36),
    Border     = Color3.fromRGB(40, 40, 50),
    Text       = Color3.fromRGB(235, 235, 245),
    TextDim    = Color3.fromRGB(140, 140, 155),
}

local COLORS = {
    {"Purple", Color3.fromRGB(120, 90, 255)},
    {"Cyan",   Color3.fromRGB(80, 200, 255)},
    {"Red",    Color3.fromRGB(255, 70, 70)},
    {"Green",  Color3.fromRGB(80, 255, 140)},
    {"White",  Color3.fromRGB(240, 240, 245)},
    {"Orange", Color3.fromRGB(255, 160, 60)},
}

function UI.Init(Silent, ESP, Anti, Perf)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FlickUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 480, 0, 560)
    Main.Position = UDim2.new(0.5, -240, 0.5, -280)
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Visible = false
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = Main

    -- TOP BAR
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 36)
    TopBar.BackgroundColor3 = Theme.Group
    TopBar.BorderSizePixel = 0
    TopBar.Parent = Main

    local accentLine = Instance.new("Frame")
    accentLine.Size = UDim2.new(1, 0, 0, 2)
    accentLine.BackgroundColor3 = Theme.Accent
    accentLine.BorderSizePixel = 0
    accentLine.Parent = TopBar

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "FLICK  ·  LARPSEC"
    title.TextColor3 = Theme.Text
    title.TextSize = 13
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = TopBar

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 28, 0, 22)
    close.Position = UDim2.new(1, -34, 0.5, -11)
    close.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    close.Text = "×"
    close.TextColor3 = Theme.TextDim
    close.TextSize = 16
    close.Font = Enum.Font.GothamBold
    close.Parent = TopBar
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 4)
    close.MouseButton1Click:Connect(function() Main.Visible = false end)

    -- TABS
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -16, 0, 28)
    TabBar.Position = UDim2.new(0, 8, 0, 42)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Main

    local tabBtns = {}
    local function MakeTab(name, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 108, 1, 0)
        b.Position = UDim2.new(0, (order - 1) * 114, 0, 0)
        b.BackgroundColor3 = Theme.Card
        b.Text = name
        b.TextColor3 = Theme.TextDim
        b.TextSize = 12
        b.Font = Enum.Font.GothamMedium
        b.Parent = TabBar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        tabBtns[name] = b
        return b
    end

    local TabCombat  = MakeTab("Combat", 1)
    local TabVisuals = MakeTab("Visuals", 2)
    local TabESP     = MakeTab("ESP", 3)
    local TabMisc    = MakeTab("Misc", 4)

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -16, 1, -84)
    Content.Position = UDim2.new(0, 8, 0, 76)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    local Pages = {}
    for _, name in ipairs({"Combat", "Visuals", "ESP", "Misc"}) do
        local p = Instance.new("ScrollingFrame")
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.ScrollBarThickness = 2
        p.ScrollBarImageColor3 = Theme.Accent
        p.CanvasSize = UDim2.new(0, 0, 0, 560)
        p.Visible = false
        p.Parent = Content
        Pages[name] = p
    end

    local function Switch(tab)
        for name, page in pairs(Pages) do
            page.Visible = (name == tab)
        end
        for name, btn in pairs(tabBtns) do
            if name == tab then
                btn.BackgroundColor3 = Theme.Accent
                btn.TextColor3 = Color3.new(1,1,1)
            else
                btn.BackgroundColor3 = Theme.Card
                btn.TextColor3 = Theme.TextDim
            end
        end
    end

    TabCombat.MouseButton1Click:Connect(function() Switch("Combat") end)
    TabVisuals.MouseButton1Click:Connect(function() Switch("Visuals") end)
    TabESP.MouseButton1Click:Connect(function() Switch("ESP") end)
    TabMisc.MouseButton1Click:Connect(function() Switch("Misc") end)

    -- set default selected state immediately
    Switch("Combat")

    local function Section(parent, text, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 20)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundTransparency = 1
        f.Parent = parent
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 1, 0)
        l.BackgroundTransparency = 1
        l.Text = text:upper()
        l.TextColor3 = Theme.Accent
        l.TextSize = 11
        l.Font = Enum.Font.GothamBold
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f
        return y + 24
    end

    local function Toggle(parent, text, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 30)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Theme.Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -52, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Text
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 34, 0, 17)
        btn.Position = UDim2.new(1, -44, 0.5, -8)
        btn.BackgroundColor3 = def and Theme.Accent or Color3.fromRGB(45, 45, 55)
        btn.Text = ""
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 13, 0, 13)
        knob.Position = def and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.BorderSizePixel = 0
        knob.Parent = btn
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = def
        btn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(btn, TweenInfo.new(0.12), {
                BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(45, 45, 55)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.12), {
                Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
            }):Play()
            cb(state)
        end)
        return y + 36
    end

    local function Slider(parent, text, min, max, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 46)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Theme.Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.65, 0, 0, 16)
        l.Position = UDim2.new(0, 10, 0, 5)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Text
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0.3, -10, 0, 16)
        val.Position = UDim2.new(0.7, 0, 0, 5)
        val.BackgroundTransparency = 1
        val.Text = tostring(def)
        val.TextColor3 = Theme.Accent
        val.TextSize = 12
        val.Font = Enum.Font.GothamMedium
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = f

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 5)
        bar.Position = UDim2.new(0, 10, 0, 30)
        bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        bar.BorderSizePixel = 0
        bar.Parent = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((def - min) / math.max(max - min, 1), 0, 1, 0)
        fill.BackgroundColor3 = Theme.Accent
        fill.BorderSizePixel = 0
        fill.Parent = bar
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local drag = false
        bar.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end
        end)
        bar.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local r = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                local v = math.floor(min + (max - min) * r + 0.5)
                fill.Size = UDim2.new(r, 0, 1, 0)
                val.Text = tostring(v)
                cb(v)
            end
        end)
        return y + 52
    end

    local function Drop(parent, text, opts, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 30)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Theme.Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.4, 0, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Text
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 140, 0, 22)
        btn.Position = UDim2.new(1, -150, 0.5, -11)
        btn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
        btn.Text = def
        btn.TextColor3 = Theme.Text
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local idx = 1
        for i, o in ipairs(opts) do
            if o == def then idx = i break end
        end
        btn.MouseButton1Click:Connect(function()
            idx = idx % #opts + 1
            btn.Text = opts[idx]
            cb(opts[idx])
        end)
        return y + 36
    end

    -- ── Combat ──
    local y = 0
    y = Section(Pages.Combat, "Silent Aim", y)
    y = Toggle(Pages.Combat, "Enabled", Silent.Config.Enabled, function(v) Silent.Config.Enabled = v end, y)
    y = Slider(Pages.Combat, "FOV", 20, 400, Silent.Config.FOV, function(v) Silent.Config.FOV = v end, y)
    y = Slider(Pages.Combat, "Hit Chance %", 1, 100, Silent.Config.HitChance, function(v) Silent.Config.HitChance = v end, y)
    y = Drop(Pages.Combat, "Hit Part", {"Head", "HumanoidRootPart", "UpperTorso"}, Silent.Config.HitPart, function(v) Silent.Config.HitPart = v end, y)
    y = Toggle(Pages.Combat, "Visible Check", Silent.Config.VisibleCheck, function(v) Silent.Config.VisibleCheck = v end, y)
    y = Toggle(Pages.Combat, "Sticky Aim", Silent.Config.Sticky, function(v) Silent.Config.Sticky = v end, y)
    y = Toggle(Pages.Combat, "Show FOV", Silent.Config.ShowFOV, function(v) Silent.Config.ShowFOV = v end, y)

    -- ── Visuals (world / perf) ──
    y = 0
    y = Section(Pages.Visuals, "Performance", y)
    y = Toggle(Pages.Visuals, "Performance Mode", Perf.Config.Enabled, function(v) Perf.SetEnabled(v) end, y)
    y = Toggle(Pages.Visuals, "FPS / Ping Counter", Perf.Config.ShowFPS, function(v) Perf.Config.ShowFPS = v end, y)
    y = Section(Pages.Visuals, "Info", y)
    local vinfo = Instance.new("TextLabel")
    vinfo.Size = UDim2.new(1, 0, 0, 50)
    vinfo.Position = UDim2.new(0, 0, 0, y)
    vinfo.BackgroundTransparency = 1
    vinfo.Text = "Perf mode lowers quality, disables shadows &\nparticles. Counter is free-draggable on screen."
    vinfo.TextColor3 = Theme.TextDim
    vinfo.TextSize = 11
    vinfo.Font = Enum.Font.Gotham
    vinfo.TextXAlignment = Enum.TextXAlignment.Left
    vinfo.Parent = Pages.Visuals

    -- ── ESP ──
    y = 0
    y = Section(Pages.ESP, "ESP", y)
    y = Toggle(Pages.ESP, "Enabled", ESP.Config.Enabled, function(v) ESP.Config.Enabled = v end, y)
    y = Toggle(Pages.ESP, "Boxes", ESP.Config.Boxes, function(v) ESP.Config.Boxes = v end, y)
    y = Toggle(Pages.ESP, "Names", ESP.Config.Names, function(v) ESP.Config.Names = v end, y)
    y = Toggle(Pages.ESP, "Distance", ESP.Config.Distance, function(v) ESP.Config.Distance = v end, y)
    y = Toggle(Pages.ESP, "Tracers", ESP.Config.Tracers, function(v) ESP.Config.Tracers = v end, y)
    y = Drop(Pages.ESP, "Tracer Origin", {"Bottom", "Center", "Mouse"}, ESP.Config.TracerFrom, function(v) ESP.Config.TracerFrom = v end, y)
    y = Slider(Pages.ESP, "Max Distance", 100, 2000, ESP.Config.MaxDistance, function(v) ESP.Config.MaxDistance = v end, y)

    local colorNames = {}
    for _, c in ipairs(COLORS) do table.insert(colorNames, c[1]) end
    y = Drop(Pages.ESP, "ESP Color", colorNames, "Purple", function(name)
        for _, c in ipairs(COLORS) do
            if c[1] == name then
                ESP.Config.Color = c[2]
                Silent.Config.FOVColor = c[2]
                break
            end
        end
    end, y)

    -- ── Misc ──
    y = 0
    y = Section(Pages.Misc, "Anti-Cheat", y)
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 56)
    status.Position = UDim2.new(0, 0, 0, y)
    status.BackgroundColor3 = Theme.Card
    status.BorderSizePixel = 0
    status.Text = "  Adonis Detected / Kill / indexInstance neutered\n  Heartbeat kept · Kick swallow · 4s watchdog\n  Status prints after ~3s on load"
    status.TextColor3 = Color3.fromRGB(120, 200, 140)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Center
    status.Parent = Pages.Misc
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 4)
    y = y + 66

    y = Section(Pages.Misc, "Controls", y)
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 40)
    info.Position = UDim2.new(0, 0, 0, y)
    info.BackgroundTransparency = 1
    info.Text = "RightShift · toggle menu\nDrag only from the top bar"
    info.TextColor3 = Theme.TextDim
    info.TextSize = 11
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Parent = Pages.Misc

    -- topbar drag only
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = Main.Position
        end
    end)
    TopBar.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    UserInputService.InputBegan:Connect(function(i, gp)
        if gp then return end
        if i.KeyCode == Enum.KeyCode.RightShift then
            Main.Visible = not Main.Visible
        end
    end)
end

return UI
