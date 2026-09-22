--[[
    Flick · UI (Luahook-inspired)
    Dark · accent top · topbar-only drag · sections
]]

local UI = {}

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local CoreGui          = game:GetService("CoreGui")
local LocalPlayer      = Players.LocalPlayer

-- theme (octohook / luahook dark)
local Theme = {
    Accent     = Color3.fromRGB(120, 90, 255),
    Background = Color3.fromRGB(15, 15, 20),
    Group      = Color3.fromRGB(20, 20, 26),
    Card       = Color3.fromRGB(28, 28, 36),
    Border     = Color3.fromRGB(40, 40, 50),
    Text       = Color3.fromRGB(235, 235, 245),
    TextDim    = Color3.fromRGB(140, 140, 155),
}

function UI.Init(Silent, ESP, Anti)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FlickUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() ScreenGui.Parent = CoreGui end)
    if not ScreenGui.Parent then
        ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- main window
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 460, 0, 540)
    Main.Position = UDim2.new(0.5, -230, 0.5, -270)
    Main.BackgroundColor3 = Theme.Background
    Main.BorderSizePixel = 0
    Main.Visible = false
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 6)

    -- outer stroke
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = Main

    -- TOP BAR (only this is draggable)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
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

    -- TAB BAR
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1, -16, 0, 30)
    TabBar.Position = UDim2.new(0, 8, 0, 42)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Main

    local function MakeTab(name, order)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 100, 1, 0)
        b.Position = UDim2.new(0, (order - 1) * 106, 0, 0)
        b.BackgroundColor3 = Theme.Card
        b.Text = name
        b.TextColor3 = Theme.TextDim
        b.TextSize = 12
        b.Font = Enum.Font.GothamMedium
        b.Parent = TabBar
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        return b
    end

    local TabCombat = MakeTab("Combat", 1)
    local TabVisuals = MakeTab("Visuals", 2)
    local TabMisc = MakeTab("Misc", 3)

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -16, 1, -88)
    Content.Position = UDim2.new(0, 8, 0, 78)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    local Pages = {
        Combat  = Instance.new("ScrollingFrame"),
        Visuals = Instance.new("ScrollingFrame"),
        Misc    = Instance.new("ScrollingFrame"),
    }
    for _, p in pairs(Pages) do
        p.Size = UDim2.new(1, 0, 1, 0)
        p.BackgroundTransparency = 1
        p.BorderSizePixel = 0
        p.ScrollBarThickness = 2
        p.ScrollBarImageColor3 = Theme.Accent
        p.CanvasSize = UDim2.new(0, 0, 0, 520)
        p.Visible = false
        p.Parent = Content
    end
    Pages.Combat.Visible = true

    local function Switch(tab)
        Pages.Combat.Visible  = tab == "Combat"
        Pages.Visuals.Visible = tab == "Visuals"
        Pages.Misc.Visible    = tab == "Misc"
        TabCombat.BackgroundColor3  = tab == "Combat"  and Theme.Accent or Theme.Card
        TabVisuals.BackgroundColor3 = tab == "Visuals" and Theme.Accent or Theme.Card
        TabMisc.BackgroundColor3    = tab == "Misc"    and Theme.Accent or Theme.Card
        TabCombat.TextColor3  = tab == "Combat"  and Color3.new(1,1,1) or Theme.TextDim
        TabVisuals.TextColor3 = tab == "Visuals" and Color3.new(1,1,1) or Theme.TextDim
        TabMisc.TextColor3    = tab == "Misc"    and Color3.new(1,1,1) or Theme.TextDim
    end
    TabCombat.MouseButton1Click:Connect(function() Switch("Combat") end)
    TabVisuals.MouseButton1Click:Connect(function() Switch("Visuals") end)
    TabMisc.MouseButton1Click:Connect(function() Switch("Misc") end)

    -- helpers
    local function Section(parent, text, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 22)
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
        return y + 26
    end

    local function Toggle(parent, text, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 32)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Theme.Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -56, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Text
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 36, 0, 18)
        btn.Position = UDim2.new(1, -46, 0.5, -9)
        btn.BackgroundColor3 = def and Theme.Accent or Color3.fromRGB(45, 45, 55)
        btn.Text = ""
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame")
        knob.Size = UDim2.new(0, 14, 0, 14)
        knob.Position = def and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
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
                Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
            }):Play()
            cb(state)
        end)
        return y + 38
    end

    local function Slider(parent, text, min, max, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 48)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Theme.Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.65, 0, 0, 18)
        l.Position = UDim2.new(0, 10, 0, 6)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Text
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0.3, -10, 0, 18)
        val.Position = UDim2.new(0.7, 0, 0, 6)
        val.BackgroundTransparency = 1
        val.Text = tostring(def)
        val.TextColor3 = Theme.Accent
        val.TextSize = 12
        val.Font = Enum.Font.GothamMedium
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Parent = f

        local bar = Instance.new("Frame")
        bar.Size = UDim2.new(1, -20, 0, 5)
        bar.Position = UDim2.new(0, 10, 0, 32)
        bar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        bar.BorderSizePixel = 0
        bar.Parent = f
        Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((def - min) / (max - min), 0, 1, 0)
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
        return y + 54
    end

    local function Drop(parent, text, opts, def, cb, y)
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 0, 32)
        f.Position = UDim2.new(0, 0, 0, y)
        f.BackgroundColor3 = Theme.Card
        f.BorderSizePixel = 0
        f.Parent = parent
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 4)

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(0.45, 0, 1, 0)
        l.Position = UDim2.new(0, 10, 0, 0)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Theme.Text
        l.TextSize = 12
        l.Font = Enum.Font.Gotham
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = f

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 130, 0, 22)
        btn.Position = UDim2.new(1, -140, 0.5, -11)
        btn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
        btn.Text = def
        btn.TextColor3 = Theme.Text
        btn.TextSize = 11
        btn.Font = Enum.Font.Gotham
        btn.Parent = f
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

        local idx = table.find(opts, def) or 1
        btn.MouseButton1Click:Connect(function()
            idx = idx % #opts + 1
            btn.Text = opts[idx]
            cb(opts[idx])
        end)
        return y + 38
    end

    -- ── Combat ──
    local y = 0
    y = Section(Pages.Combat, "Silent Aim", y)
    y = Toggle(Pages.Combat, "Enabled", Silent.Config.Enabled, function(v) Silent.Config.Enabled = v end, y)
    y = Slider(Pages.Combat, "FOV", 20, 400, Silent.Config.FOV, function(v) Silent.Config.FOV = v end, y)
    y = Drop(Pages.Combat, "Hit Part", {"Head", "HumanoidRootPart", "UpperTorso"}, Silent.Config.HitPart, function(v) Silent.Config.HitPart = v end, y)
    y = Toggle(Pages.Combat, "Visible Check", Silent.Config.VisibleCheck, function(v) Silent.Config.VisibleCheck = v end, y)
    y = Toggle(Pages.Combat, "Sticky Aim", Silent.Config.Sticky, function(v) Silent.Config.Sticky = v end, y)
    y = Toggle(Pages.Combat, "Show FOV", Silent.Config.ShowFOV, function(v) Silent.Config.ShowFOV = v end, y)

    -- ── Visuals ──
    y = 0
    y = Section(Pages.Visuals, "ESP", y)
    y = Toggle(Pages.Visuals, "Enabled", ESP.Config.Enabled, function(v) ESP.Config.Enabled = v end, y)
    y = Toggle(Pages.Visuals, "Boxes", ESP.Config.Boxes, function(v) ESP.Config.Boxes = v end, y)
    y = Toggle(Pages.Visuals, "Names", ESP.Config.Names, function(v) ESP.Config.Names = v end, y)
    y = Toggle(Pages.Visuals, "Distance", ESP.Config.Distance, function(v) ESP.Config.Distance = v end, y)
    y = Toggle(Pages.Visuals, "Health Bar", ESP.Config.HealthBar, function(v) ESP.Config.HealthBar = v end, y)
    y = Toggle(Pages.Visuals, "Tracers", ESP.Config.Tracers, function(v) ESP.Config.Tracers = v end, y)
    y = Drop(Pages.Visuals, "Tracer Origin", {"Bottom", "Center", "Mouse"}, ESP.Config.TracerFrom, function(v) ESP.Config.TracerFrom = v end, y)
    y = Slider(Pages.Visuals, "Max Distance", 100, 2000, ESP.Config.MaxDistance, function(v) ESP.Config.MaxDistance = v end, y)

    -- ── Misc ──
    y = 0
    y = Section(Pages.Misc, "Anti-Cheat", y)
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 60)
    status.Position = UDim2.new(0, 0, 0, y)
    status.BackgroundColor3 = Theme.Card
    status.BorderSizePixel = 0
    status.Text = "  Adonis · Detected / Kill / indexInstance\n  Heartbeat preserved · Kick swallow active\n  Status updates after ~3s"
    status.TextColor3 = Color3.fromRGB(120, 200, 140)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Center
    status.Parent = Pages.Misc
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 4)
    y = y + 70

    y = Section(Pages.Misc, "Info", y)
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, 0, 0, 50)
    info.Position = UDim2.new(0, 0, 0, y)
    info.BackgroundTransparency = 1
    info.Text = "RightShift  ·  toggle menu\nTop bar only is draggable\nHitscan · no prediction needed"
    info.TextColor3 = Theme.TextDim
    info.TextSize = 11
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Parent = Pages.Misc

    -- TOP BAR DRAG ONLY
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
