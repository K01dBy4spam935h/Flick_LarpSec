--[[
    LarpSec - Flick v1 · UI
]]

local UI = {}

local Themes = {
    Default = {
        Background = Color3.fromRGB(21, 21, 21),
        Groupbox   = Color3.fromRGB(30, 30, 30),
        Border     = Color3.fromRGB(46, 46, 46),
        Accent     = Color3.fromRGB(74, 144, 226),
        GradA      = Color3.fromRGB(30, 30, 30),
        GradB      = Color3.fromRGB(40, 48, 62),
    },
    Ubuntu = {
        Background = Color3.fromRGB(30, 30, 30),
        Groupbox   = Color3.fromRGB(48, 48, 48),
        Border     = Color3.fromRGB(70, 70, 70),
        Accent     = Color3.fromRGB(233, 84, 32),
        GradA      = Color3.fromRGB(48, 48, 48),
        GradB      = Color3.fromRGB(90, 40, 20),
    },
    Tokyo = {
        Background = Color3.fromRGB(26, 27, 38),
        Groupbox   = Color3.fromRGB(36, 40, 59),
        Border     = Color3.fromRGB(65, 72, 104),
        Accent     = Color3.fromRGB(122, 162, 247),
        GradA      = Color3.fromRGB(36, 40, 59),
        GradB      = Color3.fromRGB(55, 40, 80),
    },
    Blossom = {
        Background = Color3.fromRGB(32, 24, 28),
        Groupbox   = Color3.fromRGB(48, 36, 42),
        Border     = Color3.fromRGB(80, 55, 65),
        Accent     = Color3.fromRGB(255, 140, 170),
        GradA      = Color3.fromRGB(48, 36, 42),
        GradB      = Color3.fromRGB(90, 40, 60),
    },
    Midnight = {
        Background = Color3.fromRGB(10, 12, 22),
        Groupbox   = Color3.fromRGB(18, 22, 38),
        Border     = Color3.fromRGB(40, 50, 80),
        Accent     = Color3.fromRGB(100, 140, 255),
        GradA      = Color3.fromRGB(18, 22, 38),
        GradB      = Color3.fromRGB(30, 20, 55),
    },
    Dark = {
        Background = Color3.fromRGB(12, 12, 12),
        Groupbox   = Color3.fromRGB(22, 22, 22),
        Border     = Color3.fromRGB(40, 40, 40),
        Accent     = Color3.fromRGB(180, 180, 180),
        GradA      = Color3.fromRGB(22, 22, 22),
        GradB      = Color3.fromRGB(35, 35, 35),
    },
    Hacker = {
        Background = Color3.fromRGB(8, 14, 8),
        Groupbox   = Color3.fromRGB(14, 28, 14),
        Border     = Color3.fromRGB(30, 60, 30),
        Accent     = Color3.fromRGB(40, 255, 80),
        GradA      = Color3.fromRGB(14, 28, 14),
        GradB      = Color3.fromRGB(20, 50, 20),
    },
}

local function applyGradient(frame, theme)
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
    g.Rotation = 90
end

local function applyThemeToWindow(window, themeName)
    local theme = Themes[themeName] or Themes.Default
    pcall(function()
        if window.Frame then
            window.Frame.BackgroundColor3 = theme.Background
        end
        if window.Sidebar then
            window.Sidebar.BackgroundColor3 = theme.Groupbox
        end
        -- walk descendants for groupboxes / slider fills
        if window.Frame then
            for _, d in ipairs(window.Frame:GetDescendants()) do
                if d:IsA("Frame") and (d.Name == "Groupbox" or d.Name:find("Group")) then
                    d.BackgroundColor3 = theme.Groupbox
                    applyGradient(d, theme)
                end
                if d:IsA("Frame") and (d.Name == "Fill" or d.Name == "SliderFill") then
                    d.BackgroundColor3 = theme.Accent
                    applyGradient(d, theme)
                end
                if d:IsA("TextButton") and d.Name == "TabBtn" then
                    -- leave default; accent on active handled by lib
                end
            end
        end
    end)
end

-- simple color picker popup
local function openColorPicker(parentGui, current, onChange)
    local existing = parentGui:FindFirstChild("ColorPickerPopup")
    if existing then existing:Destroy() end

    local popup = Instance.new("Frame")
    popup.Name = "ColorPickerPopup"
    popup.Size = UDim2.new(0, 220, 0, 200)
    popup.Position = UDim2.new(0.5, -110, 0.5, -100)
    popup.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
    popup.BorderSizePixel = 0
    popup.ZIndex = 50
    popup.Parent = parentGui
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 6)

    local h, s, v = Color3.toHSV(current or Color3.fromRGB(74, 144, 226))

    local sv = Instance.new("ImageButton")
    sv.Size = UDim2.new(0, 160, 0, 120)
    sv.Position = UDim2.new(0, 10, 0, 10)
    sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    sv.BorderSizePixel = 0
    sv.ZIndex = 51
    sv.AutoButtonColor = false
    sv.Parent = popup

    local white = Instance.new("Frame")
    white.Size = UDim2.new(1, 0, 1, 0)
    white.BackgroundColor3 = Color3.new(1, 1, 1)
    white.BorderSizePixel = 0
    white.ZIndex = 52
    white.Parent = sv
    local wg = Instance.new("UIGradient")
    wg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    wg.Parent = white

    local black = Instance.new("Frame")
    black.Size = UDim2.new(1, 0, 1, 0)
    black.BackgroundColor3 = Color3.new(0, 0, 0)
    black.BorderSizePixel = 0
    black.ZIndex = 53
    black.Parent = sv
    local bg = Instance.new("UIGradient")
    bg.Rotation = 90
    bg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    bg.Parent = black

    local hueBar = Instance.new("ImageButton")
    hueBar.Size = UDim2.new(0, 18, 0, 120)
    hueBar.Position = UDim2.new(0, 180, 0, 10)
    hueBar.BorderSizePixel = 0
    hueBar.ZIndex = 51
    hueBar.AutoButtonColor = false
    hueBar.Parent = popup
    local hg = Instance.new("UIGradient")
    hg.Rotation = 90
    local keys = {}
    for i = 0, 6 do
        table.insert(keys, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
    end
    hg.Color = ColorSequence.new(keys)
    hg.Parent = hueBar
    hueBar.BackgroundColor3 = Color3.new(1, 1, 1)

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 40, 0, 18)
    preview.Position = UDim2.new(0, 10, 0, 140)
    preview.BorderSizePixel = 0
    preview.ZIndex = 51
    preview.BackgroundColor3 = Color3.fromHSV(h, s, v)
    preview.Parent = popup

    local hex = Instance.new("TextLabel")
    hex.Size = UDim2.new(0, 100, 0, 18)
    hex.Position = UDim2.new(0, 56, 0, 140)
    hex.BackgroundTransparency = 1
    hex.TextColor3 = Color3.new(1, 1, 1)
    hex.TextSize = 12
    hex.Font = Enum.Font.Gotham
    hex.TextXAlignment = Enum.TextXAlignment.Left
    hex.ZIndex = 51
    hex.Parent = popup

    local function updateHex()
        local c = Color3.fromHSV(h, s, v)
        preview.BackgroundColor3 = c
        hex.Text = string.format("#%02X%02X%02X", math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255))
        onChange(c)
    end
    updateHex()

    local function pickSV(input)
        local rel = Vector2.new(input.Position.X, input.Position.Y) - sv.AbsolutePosition
        s = math.clamp(rel.X / sv.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp(rel.Y / sv.AbsoluteSize.Y, 0, 1)
        updateHex()
    end
    local function pickH(input)
        local rel = (input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y
        h = math.clamp(rel, 0, 1)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        updateHex()
    end

    local UIS = game:GetService("UserInputService")
    local dragSV, dragH
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

    local function mkBtn(text, x, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 60, 0, 22)
        b.Position = UDim2.new(0, x, 0, 168)
        b.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
        b.Text = text
        b.TextColor3 = Color3.new(1, 1, 1)
        b.TextSize = 11
        b.Font = Enum.Font.Gotham
        b.ZIndex = 51
        b.Parent = popup
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(cb)
        return b
    end

    mkBtn("RGB", 10, function()
        -- cycle pure R G B primaries as quick picks
        local prim = {
            Color3.fromRGB(255, 0, 0),
            Color3.fromRGB(0, 255, 0),
            Color3.fromRGB(0, 0, 255),
            Color3.fromRGB(255, 255, 255),
        }
        local c = prim[math.random(1, #prim)]
        h, s, v = Color3.toHSV(c)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        updateHex()
    end)
    mkBtn("Static", 78, function()
        -- static rainbow-ish mid saturation (not animated)
        local c = Color3.fromHSV((tick() * 0.05) % 1, 0.85, 1)
        h, s, v = Color3.toHSV(c)
        -- lock a fixed rainbow sample based on hash of time once
        c = Color3.fromHSV(0.75, 0.7, 1) -- static violet-cyan range pick
        -- better: fixed multi-hue blend color (magenta-cyan mid)
        c = Color3.fromRGB(255, 0, 128)
        h, s, v = Color3.toHSV(c)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        updateHex()
    end)
    mkBtn("Close", 146, function()
        popup:Destroy()
    end)
end

function UI.Init(Silent, ESP, Anti, Perf)
    local Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/K01dBy4spam935h/Flick_LarpSec/main/src/library.lua"
    ))()

    local Lib = Library.new({
        Title = "LarpSec - Flick v1",
        ToggleKey = Enum.KeyCode.RightShift,
    })

    local Window = Lib:CreateWindow({
        Title = "LarpSec - Flick v1",
        Size = Vector2.new(580, 500),
    })

    local function colorBtn(gb, label, getCol, setCol)
        gb:AddLabel(label)
        -- library may not have color - use toggle as open picker proxy via label + dropdown workaround
    end

    -- ── Combat ──────────────────────────────────────────────
    local TabCombat = Window:CreateTab("Combat")
    local GBSilent = TabCombat:CreateGroupbox("Silent Aim", "Left")
    local GBTarget = TabCombat:CreateGroupbox("Targeting", "Right")

    GBSilent:AddToggle({
        Text = "Enabled",
        Default = Silent.Config.Enabled,
        Callback = function(v) Silent.Config.Enabled = v end,
    })
    GBSilent:AddSlider({
        Text = "FOV",
        Min = 20, Max = 2000, Default = Silent.Config.FOV,
        Callback = function(v) Silent.Config.FOV = v end,
    })
    GBSilent:AddSlider({
        Text = "Hit Chance",
        Min = 1, Max = 100, Default = Silent.Config.HitChance,
        Suffix = "%",
        Callback = function(v) Silent.Config.HitChance = v end,
    })
    GBSilent:AddToggle({
        Text = "Show FOV",
        Default = Silent.Config.ShowFOV,
        Callback = function(v) Silent.Config.ShowFOV = v end,
    })

    GBTarget:AddDropdown({
        Text = "Hit Part",
        Values = {"Torso", "Head", "HumanoidRootPart", "UpperTorso"},
        Default = "Torso",
        Callback = function(v)
            if v == "Torso" then
                Silent.Config.HitPart = "UpperTorso"
                Silent.Config.PreferTorso = true
            else
                Silent.Config.HitPart = v
                Silent.Config.PreferTorso = false
            end
        end,
    })
    GBTarget:AddToggle({
        Text = "Visible Check",
        Default = Silent.Config.VisibleCheck,
        Callback = function(v) Silent.Config.VisibleCheck = v end,
    })
    GBTarget:AddToggle({
        Text = "Sticky Aim",
        Default = Silent.Config.Sticky,
        Callback = function(v) Silent.Config.Sticky = v end,
    })

    -- ── Visuals ─────────────────────────────────────────────
    local TabVisuals = Window:CreateTab("Visuals")
    local GBWorld = TabVisuals:CreateGroupbox("World", "Left")
    local GBHud = TabVisuals:CreateGroupbox("HUD", "Right")

    GBWorld:AddToggle({
        Text = "Fullbright",
        Default = Perf.Config.Fullbright,
        Callback = function(v) Perf.Config.Fullbright = v Perf.Refresh() end,
    })
    GBWorld:AddToggle({
        Text = "Fog",
        Default = Perf.Config.FogEnabled,
        Callback = function(v) Perf.Config.FogEnabled = v Perf.Refresh() end,
    })
    GBWorld:AddSlider({
        Text = "Fog End",
        Min = 50, Max = 2000, Default = Perf.Config.FogEnd,
        Callback = function(v) Perf.Config.FogEnd = v Perf.Refresh() end,
    })
    GBWorld:AddSlider({
        Text = "Stretch Res",
        Min = 10, Max = 20, Default = 10,
        Callback = function(v) Perf.Config.Stretch = v / 10 end,
    })
    GBWorld:AddToggle({
        Text = "Third Person",
        Default = false,
        Callback = function(v) Perf.SetThirdPerson(v) end,
    })

    GBHud:AddToggle({
        Text = "Radar",
        Default = ESP.Config.Radar,
        Callback = function(v) ESP.Config.Radar = v end,
    })
    GBHud:AddToggle({
        Text = "Arrows",
        Default = ESP.Config.Arrows,
        Callback = function(v) ESP.Config.Arrows = v end,
    })
    GBHud:AddDropdown({
        Text = "Crosshair",
        Values = {"Default", "Cross", "Dot", "Off"},
        Default = "Default",
        Callback = function(v) Perf.SetCrosshair(v) end,
    })
    GBHud:AddToggle({
        Text = "FPS / Ping",
        Default = Perf.Config.ShowFPS,
        Callback = function(v) Perf.Config.ShowFPS = v end,
    })

    -- ── ESP ─────────────────────────────────────────────────
    local TabESP = Window:CreateTab("ESP")
    local GBESP = TabESP:CreateGroupbox("ESP", "Left")
    local GBStyle = TabESP:CreateGroupbox("Style", "Right")

    GBESP:AddToggle({ Text = "Enabled", Default = ESP.Config.Enabled, Callback = function(v) ESP.Config.Enabled = v end})
    GBESP:AddToggle({Text = "Boxes", Default = ESP.Config.Boxes, Callback = function(v) ESP.Config.Boxes = v end})
    GBESP:AddToggle({Text = "Names", Default = ESP.Config.Names, Callback = function(v) ESP.Config.Names = v end})
    GBESP:AddToggle({Text = "Distance", Default = ESP.Config.Distance, Callback = function(v) ESP.Config.Distance = v end})
    GBESP:AddToggle({Text = "Tracers", Default = ESP.Config.Tracers, Callback = function(v) ESP.Config.Tracers = v end})
    GBESP:AddToggle({Text = "Chams", Default = ESP.Config.Chams, Callback = function(v) ESP.Config.Chams = v end})

    GBStyle:AddDropdown({
        Text = "Tracer Origin",
        Values = {"Bottom", "Center", "Mouse"},
        Default = ESP.Config.TracerFrom,
        Callback = function(v) ESP.Config.TracerFrom = v end,
    })
    GBStyle:AddSlider({
        Text = "Max Distance",
        Min = 100, Max = 2000, Default = ESP.Config.MaxDistance,
        Suffix = "m",
        Callback = function(v) ESP.Config.MaxDistance = v end,
    })
    GBStyle:AddDropdown({
        Text = "Color Preset",
        Values = {"Blue", "Purple", "Cyan", "Red", "Green", "White", "Orange", "StaticRGB"},
        Default = "Blue",
        Callback = function(name)
            local map = {
                Blue   = Color3.fromRGB(74, 144, 226),
                Purple = Color3.fromRGB(120, 90, 255),
                Cyan   = Color3.fromRGB(80, 200, 255),
                Red    = Color3.fromRGB(255, 70, 70),
                Green  = Color3.fromRGB(80, 255, 140),
                White  = Color3.fromRGB(240, 240, 245),
                Orange = Color3.fromRGB(255, 160, 60),
                StaticRGB = Color3.fromRGB(255, 0, 128),
            }
            local c = map[name] or map.Blue
            ESP.Config.Color = c
            ESP.Config.ChamsColor = c
            Silent.Config.FOVColor = c
        end,
    })
    GBStyle:AddDropdown({
        Text = "Open Picker",
        Values = {"ESP Color", "Chams Color"},
        Default = "ESP Color",
        Callback = function(which)
            local gui = Lib.ScreenGui or game:GetService("CoreGui"):FindFirstChild("FlickLib")
            if not gui then return end
            local cur = which == "Chams Color" and ESP.Config.ChamsColor or ESP.Config.Color
            openColorPicker(gui, cur, function(c)
                if which == "Chams Color" then
                    ESP.Config.ChamsColor = c
                else
                    ESP.Config.Color = c
                    Silent.Config.FOVColor = c
                end
            end)
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
    GBCull:AddLabel("hides unnecessary clutter")
    GBCull:AddLabel("shadows · particles · VFX")

    -- ── Config ──────────────────────────────────────────────
    local TabConfig = Window:CreateTab("Config")
    local GBTheme = TabConfig:CreateGroupbox("Theme", "Left")
    local GBKey = TabConfig:CreateGroupbox("Menu", "Right")

    GBTheme:AddDropdown({
        Text = "Theme",
        Values = {"Default", "Ubuntu", "Tokyo", "Blossom", "Midnight", "Dark", "Hacker"},
        Default = "Default",
        Callback = function(name)
            applyThemeToWindow(Window, name)
        end,
    })
    GBKey:AddLabel("RightShift · toggle menu")
    GBKey:AddLabel("Title bar · drag")

    -- ── Beta ────────────────────────────────────────────────
    local TabBeta = Window:CreateTab("Beta")
    local GBBeta = TabBeta:CreateGroupbox("Experimental", "Left")
    GBBeta:AddToggle({
        Text = "No Reload",
        Default = Silent.Config.NoReload,
        Callback = function(v) Silent.Config.NoReload = v end,
    })
    GBBeta:AddLabel("zeros reloadTime on config")
    GBBeta:AddLabel("table — unstable after death")

    -- ── Info ────────────────────────────────────────────────
    local TabInfo = Window:CreateTab("Info")
    local GBInfo = TabInfo:CreateGroupbox("Status", "Left")
    local GBNoRel = TabInfo:CreateGroupbox("No Reload", "Right")

    GBInfo:AddLabel("LarpSec - Flick v1")
    GBInfo:AddLabel("Adonis bypass active")
    GBInfo:AddLabel("Silent: Direction torso")

    GBNoRel:AddLabel("Status: experimental")
    GBNoRel:AddLabel("Lever: config reloadTime")
    GBNoRel:AddLabel("Not proven live timer")
    GBNoRel:AddLabel("Respawn: rebind flaky")
    GBNoRel:AddLabel("Shelved as reliable")

    Window.Frame.Visible = true
    applyThemeToWindow(Window, "Default")
end

return UI
