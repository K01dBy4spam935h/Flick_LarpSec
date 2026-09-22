--[[
    Flick · UI
    Dark purple theme · tabs · live config binding
]]

local UI = {}

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

local Accent     = Color3.fromRGB(140, 80, 255)
local Background = Color3.fromRGB(18, 18, 24)
local Card       = Color3.fromRGB(28, 28, 38)

function UI.Init(Silent, ESP)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FlickSilentUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 420, 0, 520)
    Main.Position = UDim2.new(0.5, -210, 0.5, -260)
    Main.BackgroundColor3 = Background
    Main.BorderSizePixel = 0
    Main.Visible = false
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 3)
    bar.BackgroundColor3 = Accent
    bar.BorderSizePixel = 0
    bar.Parent = Main

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 0, 40)
    title.Position = UDim2.new(0, 16, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "FLICK  ·  SILENT"
    title.TextColor3 = Color3.fromRGB(240, 240, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = Main

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 28, 0, 28)
    close.Position = UDim2.new(1, -36, 0, 14)
    close.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    close.Text = "×"
    close.TextColor3 = Color3.fromRGB(200, 200, 210)
    close.TextSize = 18
    close.Font = Enum.Font.GothamBold
    close.Parent = Main
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)
    close.MouseButton1Click:Connect(function() Main.Visible = false end)

    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -32, 0, 36)
    TabBar.Position = UDim2.new(0, 16, 0, 56)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Main

    local function MakeTab(name, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 110, 1, 0)
        b.Position = UDim2.new(0, (order - 1) * 118, 0, 0)
        b.BackgroundColor3 = Color3.fromRGB(32, 32, 42)
        b.Text = name
        b.TextColor3 = Color3.fromRGB(180, 180, 200)
        b.TextSize = 13
        b.Font = Enum.Font.GothamMedium
        b.Parent = TabBar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
        return b
    end

    local TabSilent = MakeTab("Silent Aim", 1)
    local TabESP    = MakeTab("ESP", 2)
    local TabSet    = MakeTab("Anti", 3)

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -32, 1, -110)
    Content.Position = UDim2.new(0, 16, 0, 100)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    local Pages = {
        Silent = Instance.new("ScrollingFrame"),
        ESP    = Instance.new("ScrollingFrame"),
        Set    = Instance.new("ScrollingFrame"),
    }
    for _, p in pairs(Pages) do
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.ScrollBarThickness = 3
        p.ScrollBarImageColor3 = Accent
        p.CanvasSize = UDim2.new(0, 0, 0, 480)
        p.Visible = false
        p.Parent = Content
    end
    Pages.Silent.Visible = true

    local function Switch(tab)
        Pages.Silent.Visible = tab == "Silent"
        Pages.ESP.Visible    = tab == "ESP"
        Pages.Set.Visible    = tab == "Set"
        TabSilent.BackgroundColor3 = tab == "Silent" and Accent or Color3.fromRGB(32, 32, 42)
        TabESP.BackgroundColor3    = tab == "ESP"    and Accent or Color3.fromRGB(32, 32, 42)
        TabSet.BackgroundColor3    = tab == "Set"    and Accent or Color3.fromRGB(32, 32, 42)
        TabSilent.TextColor3 = tab == "Silent" and Color3.new(1,1,1) or Color3.fromRGB(180,180,200)
        TabESP.TextColor3    = tab == "ESP"    and Color3.new(1,1,1) or Color3.fromRGB(180,180,200)
        TabSet.TextColor3    = tab == "Set"    and Color3.new(1,1,1) or Color3.fromRGB(180,180,200)
    end
    TabSilent.MouseButton1Click:Connect(function() Switch("Silent") end)
    TabESP.MouseButton1Click:Connect(function() Switch("ESP") end)
    TabSet.MouseButton1Click:Connect(function() Switch("Set") end)

    local function Toggle(parent, text, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 36)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -60, 1, 0)
        l.Position = UDim2.new(0, 12, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(220, 220, 235)
        l.TextSize = 13
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 40, 0, 20)
        btn.Position = UDim2.new(1, -50, 0.5, -10)
        btn.BackgroundColor3 = def and Accent or Color3.fromRGB(50, 50, 60)
        btn.Text = ""
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = def and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        knob.BackgroundColor3 = Color3.new(1,1,1)
        knob.BorderSizePixel = 0
        knob.Parent = btn
        Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

        local state = def
        btn.MouseButton1Click:Connect(function()
            state = not state
            TweenService:Create(btn, TweenInfo.new(0.15), {
                BackgroundColor3 = state and Accent or Color3.fromRGB(50, 50, 60)
            }):Play()
            TweenService:Create(knob, TweenInfo.new(0.15), {
                Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            }):Play()
            cb(state)
        end)
    end

    local function Slider(parent, text, min, max, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 52)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.7, 0, 0, 20)
        l.Position = UDim2.new(0, 12, 0, 6)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(220, 220, 235)
        l.TextSize = 13
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0.3, -12, 0, 20)
        val.Position = UDim2.new(0.7, 0, 0, 6)
        val.BackgroundTransparency = 1
        val.Text = tostring(def)
        val.TextColor3 = Accent
        val.TextSize = 13
        val.Font = Enum.Font.GothamMedium
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = f

        local barBg = Instance.new("Frame")
        barBg.Size = UDim2.new(1, -24, 0, 6)
        barBg.Position = UDim2.new(0, 12, 0, 34)
        barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        barBg.BorderSizePixel = 0
        barBg.Parent = f
        Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Accent
        fill.BorderSizePixel = 0
        fill.Parent = barBg
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local drag = false
        barBg.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = true end
        end)
        barBg.InputEnded:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 then drag = false end
        end)
        UserInputService.InputChanged:Connect(function(i)
            if drag and i.UserInputType == Enum.UserInputType.MouseMovement then
                local r = math.clamp((i.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
                local v = math.floor(min + (max - min) * r + 0.5)
                fill.Size = UDim2.new(r, 0, 1, 0)
                val.Text = tostring(v)
                cb(v)
            end
        end)
    end

    local function Drop(parent, text, opts, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 36)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.5, 0, 1, 0)
        l.Position = UDim2.new(0, 12, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Color3.fromRGB(220, 220, 235)
        l.TextSize = 13
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 120, 0, 24)
        btn.Position = UDim2.new(1, -132, 0.5, -12)
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
        btn.Text = def
        btn.TextColor3 = Color3.fromRGB(220, 220, 235)
        btn.TextSize = 12
        btn.Font = Enum.Font.Gotham
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        local idx = table.find(opts, def) or 1
        btn.MouseButton1Click:Connect(function()
            idx = idx % #opts + 1
            btn.Text = opts[idx]
            cb(opts[idx])
        end)
    end

    -- Silent page
    Toggle(Pages.Silent, "Enable Silent Aim", Silent.Config.Enabled, function(v) Silent.Config.Enabled = v end, 0)
    Slider(Pages.Silent, "FOV Radius", 20, 400, Silent.Config.FOV, function(v) Silent.Config.FOV = v end, 44)
    Drop(Pages.Silent, "Hit Part", {"Head", "HumanoidRootPart", "UpperTorso"}, Silent.Config.HitPart, function(v) Silent.Config.HitPart = v end, 104)
    Toggle(Pages.Silent, "Visible Check", Silent.Config.VisibleCheck, function(v) Silent.Config.VisibleCheck = v end, 148)
    Slider(Pages.Silent, "Prediction (x100)", 0, 30, math.floor(Silent.Config.Prediction * 100), function(v) Silent.Config.Prediction = v / 100 end, 192)
    Toggle(Pages.Silent, "Show FOV Circle", Silent.Config.ShowFOV, function(v) Silent.Config.ShowFOV = v end, 252)

    -- ESP page
    Toggle(Pages.ESP, "Enable ESP", ESP.Config.Enabled, function(v) ESP.Config.Enabled = v end, 0)
    Toggle(Pages.ESP, "Boxes", ESP.Config.Boxes, function(v) ESP.Config.Boxes = v end, 44)
    Toggle(Pages.ESP, "Names", ESP.Config.Names, function(v) ESP.Config.Names = v end, 88)
    Toggle(Pages.ESP, "Distance", ESP.Config.Distance, function(v) ESP.Config.Distance = v end, 132)
    Toggle(Pages.ESP, "Health Bar", ESP.Config.HealthBar, function(v) ESP.Config.HealthBar = v end, 176)
    Toggle(Pages.ESP, "Tracers", ESP.Config.Tracers, function(v) ESP.Config.Tracers = v end, 220)
    Drop(Pages.ESP, "Tracer Origin", {"Bottom", "Center", "Mouse"}, ESP.Config.TracerFrom, function(v) ESP.Config.TracerFrom = v end, 264)
    Slider(Pages.ESP, "Max Distance", 100, 2000, ESP.Config.MaxDistance, function(v) ESP.Config.MaxDistance = v end, 308)

    -- Anti page
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 120)
    info.Position = UDim2.new(0, 0, 0, 8)
    info.BackgroundTransparency = 1
    info.Text = "Adonis / Tamper Protection\n\n• Detected / Kill / indexInstance neutered\n• Kick swallow active\n• Watchdog re-scans every 5s\n• Silent uses BulletHandler only\n  (no __index / metamethod hooks)"
    info.TextColor3 = Color3.fromRGB(140, 200, 140)
    info.TextSize = 12
    info.Font = Enum.Font.Gotham
    info.TextWrapped = true
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.TextYAlignment = Enum.TextYAlignment.Top
    info.Parent = Pages.Set

    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1, 0, 0, 20)
    credit.Position = UDim2.new(0, 0, 1, -28)
    credit.BackgroundTransparency = 1
    credit.Text = "cobble hills  ·  flick silent v3"
    credit.TextColor3 = Color3.fromRGB(80, 80, 100)
    credit.TextSize = 11
    credit.Font = Enum.Font.Gotham
    credit.Parent = Main

    -- drag
    local dragging, dragStart, startPos
    Main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = Main.Position
        end
    end)
    Main.InputEnded:Connect(function(i)
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

    print("[UI] ready · RightShift")
end

return UI
