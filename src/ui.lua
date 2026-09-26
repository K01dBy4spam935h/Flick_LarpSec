--[[
    LarpSec - Flick v1 UI
]]

local UI = {}
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local Themes = {
    Default = {
        AnimA = Color3.fromRGB(18, 20, 32), AnimB = Color3.fromRGB(45, 60, 100),
        GradA = Color3.fromRGB(24, 24, 28), GradB = Color3.fromRGB(40, 55, 85),
        Groupbox = Color3.fromRGB(30, 30, 30), Border = Color3.fromRGB(46, 46, 46),
        Accent = Color3.fromRGB(74, 144, 226), Text = Color3.fromRGB(255, 255, 255),
    },
    Ubuntu = {
        AnimA = Color3.fromRGB(40, 8, 25), AnimB = Color3.fromRGB(150, 55, 18),
        GradA = Color3.fromRGB(55, 15, 30), GradB = Color3.fromRGB(130, 45, 18),
        Groupbox = Color3.fromRGB(55, 22, 38), Border = Color3.fromRGB(120, 55, 35),
        Accent = Color3.fromRGB(233, 84, 32), Text = Color3.fromRGB(255, 240, 230),
    },
    Tokyo = {
        AnimA = Color3.fromRGB(26, 27, 50), AnimB = Color3.fromRGB(85, 55, 130),
        GradA = Color3.fromRGB(30, 34, 55), GradB = Color3.fromRGB(70, 45, 110),
        Groupbox = Color3.fromRGB(36, 40, 59), Border = Color3.fromRGB(65, 72, 104),
        Accent = Color3.fromRGB(122, 162, 247), Text = Color3.fromRGB(192, 202, 245),
    },
    Blossom = {
        AnimA = Color3.fromRGB(45, 25, 40), AnimB = Color3.fromRGB(130, 55, 90),
        GradA = Color3.fromRGB(50, 32, 42), GradB = Color3.fromRGB(120, 55, 85),
        Groupbox = Color3.fromRGB(58, 40, 50), Border = Color3.fromRGB(120, 70, 90),
        Accent = Color3.fromRGB(255, 140, 180), Text = Color3.fromRGB(255, 230, 240),
    },
    Midnight = {
        AnimA = Color3.fromRGB(8, 12, 30), AnimB = Color3.fromRGB(45, 35, 95),
        GradA = Color3.fromRGB(14, 18, 36), GradB = Color3.fromRGB(35, 25, 75),
        Groupbox = Color3.fromRGB(16, 20, 40), Border = Color3.fromRGB(40, 55, 100),
        Accent = Color3.fromRGB(90, 130, 255), Text = Color3.fromRGB(210, 220, 255),
    },
    Dark = {
        AnimA = Color3.fromRGB(10, 10, 10), AnimB = Color3.fromRGB(50, 50, 50),
        GradA = Color3.fromRGB(16, 16, 16), GradB = Color3.fromRGB(42, 42, 42),
        Groupbox = Color3.fromRGB(18, 18, 18), Border = Color3.fromRGB(36, 36, 36),
        Accent = Color3.fromRGB(200, 200, 200), Text = Color3.fromRGB(230, 230, 230),
    },
    Hacker = {
        AnimA = Color3.fromRGB(4, 16, 4), AnimB = Color3.fromRGB(25, 90, 30),
        GradA = Color3.fromRGB(8, 22, 8), GradB = Color3.fromRGB(18, 60, 18),
        Groupbox = Color3.fromRGB(10, 24, 10), Border = Color3.fromRGB(20, 70, 20),
        Accent = Color3.fromRGB(0, 255, 70), Text = Color3.fromRGB(180, 255, 180),
    },
}

local UI_FONTS = {"Gotham","GothamBold","SourceSans","SourceSansBold","Code","Fantasy","Arcade","Bodoni","Garamond","Oswald"}

local function getExecutorName()
    local name
    pcall(function() if identifyexecutor then name = identifyexecutor() end end)
    if not name or name == "" then pcall(function() if getexecutorname then name = getexecutorname() end end) end
    if not name or name == "" then name = "Unknown" end
    return tostring(name)
end

local animToken = 0
local function startAnimatedBackground(window, theme)
    animToken = animToken + 1
    local token = animToken
    local root = window.Frame
    if not root then return end

    -- high-contrast ends so rotation is obvious
    local c0 = theme.AnimA
    local c1 = theme.AnimB
    local seq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c0),
        ColorSequenceKeypoint.new(0.5, theme.Accent),
        ColorSequenceKeypoint.new(1, c1),
    })

    local function paint(frame)
        if not frame or not frame:IsA("Frame") then return end
        frame.BackgroundColor3 = Color3.new(1, 1, 1)
        local g = frame:FindFirstChild("PanelGrad")
        if not g then
            g = Instance.new("UIGradient")
            g.Name = "PanelGrad"
            g.Parent = frame
        end
        g.Color = seq
        return g
    end

    local grads = {}
    table.insert(grads, paint(root))
    for _, name in ipairs({"TopBar", "Sidebar", "Content"}) do
        local f = root:FindFirstChild(name)
        if not f then
            for _, d in ipairs(root:GetDescendants()) do
                if d.Name == name and d:IsA("Frame") then f = d break end
            end
        end
        local g = paint(f)
        if g then table.insert(grads, g) end
    end
    -- groupboxes
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("Frame") and d:FindFirstChild("Body") then
            local g = paint(d)
            if g then table.insert(grads, g) end
        end
    end

    task.spawn(function()
        local rot = 0
        while token == animToken and root.Parent do
            rot = (rot + 0.7) % 360
            for _, g in ipairs(grads) do
                if g and g.Parent then
                    g.Rotation = rot
                end
            end
            task.wait(0.03)
        end
    end)
end

local function applyTheme(window, themeName, fontName)
    local theme = Themes[themeName] or Themes.Default
    pcall(function()
        startAnimatedBackground(window, theme)
        local root = window.Frame
        if not root then return end
        for _, d in ipairs(root:GetDescendants()) do
            if d:IsA("Frame") then
                local n = d.Name:lower()
                if n:find("group") then
                    d.BackgroundColor3 = theme.Groupbox
                end
                if n == "sliderfill" or n == "fill" then
                    d.BackgroundColor3 = theme.Accent
                end
            end
            if d:IsA("UIStroke") then d.Color = theme.Border end
            if (d:IsA("TextLabel") or d:IsA("TextButton")) and fontName then
                pcall(function() d.Font = Enum.Font[fontName] end)
            end
        end
    end)
end

local function openColorPicker(parentGui, current, onChange)
    local existing = parentGui:FindFirstChild("ColorPickerPopup")
    if existing then existing:Destroy() end
    local popup = Instance.new("Frame")
    popup.Name = "ColorPickerPopup"
    popup.Size = UDim2.new(0, 220, 0, 160)
    popup.Position = UDim2.new(0.5, -110, 0.5, -80)
    popup.BackgroundColor3 = Color3.fromRGB(22,22,28)
    popup.BorderSizePixel = 0
    popup.ZIndex = 80
    popup.Parent = parentGui
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 6)
    local h, s, v = Color3.toHSV(current or Color3.fromRGB(74,144,226))
    local mode = "Static"
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 40, 0, 40)
    preview.Position = UDim2.new(0, 12, 0, 12)
    preview.BorderSizePixel = 0
    preview.ZIndex = 81
    preview.Parent = popup
    local hex = Instance.new("TextLabel")
    hex.Size = UDim2.new(0, 120, 0, 20)
    hex.Position = UDim2.new(0, 60, 0, 20)
    hex.BackgroundTransparency = 1
    hex.TextColor3 = Color3.new(1,1,1)
    hex.TextSize = 13
    hex.Font = Enum.Font.Code
    hex.ZIndex = 81
    hex.Parent = popup
    local function emit()
        local c
        if mode == "Rainbow" then c = Color3.fromHSV((tick()*0.2)%1, 0.9, 1)
        elseif mode == "StaticRainbow" then c = Color3.fromRGB(255,40,180)
        else c = Color3.fromHSV(h,s,v) end
        preview.BackgroundColor3 = c
        hex.Text = string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
        onChange(c, mode)
    end
    emit()
    local function btn(text, x, y, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 48, 0, 22)
        b.Position = UDim2.new(0, x, 0, y)
        b.BackgroundColor3 = Color3.fromRGB(40,42,55)
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = 11
        b.Font = Enum.Font.Code
        b.ZIndex = 81
        b.Parent = popup
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(cb)
    end
    btn("RGB", 12, 70, function()
        mode = "Static"
        local prim = {Color3.fromRGB(255,40,40), Color3.fromRGB(40,255,80), Color3.fromRGB(40,120,255)}
        local c = prim[(math.floor(tick()) % 3) + 1]
        h,s,v = Color3.toHSV(c)
        emit()
    end)
    btn("Rain", 66, 70, function() mode = "Rainbow" emit() end)
    btn("StatR", 120, 70, function() mode = "StaticRainbow" emit() end)
    btn("Close", 160, 120, function() popup:Destroy() end)
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
    local Lib = Library.new({ Title = "LarpSec - Flick v1", ToggleKey = Enum.KeyCode.RightShift })
    local Window = Lib:CreateWindow({ Title = "LarpSec - Flick v1", Size = Vector2.new(600, 520) })
    local function guiRoot()
        return Lib.ScreenGui or game:GetService("CoreGui"):FindFirstChild("FlickLib")
    end
    local currentTheme, currentUIFont = "Default", "Code"

    -- Main
    local TabMain = Window:CreateTab("Main")
    local GBServer = TabMain:CreateGroupbox("Server", "Left")
    local GBAnti = TabMain:CreateGroupbox("Anti-Cheat", "Right")
    GBServer:AddLabel("Executor: " .. getExecutorName())
    GBServer:AddLabel("JobId: " .. tostring(game.JobId))
    GBServer:AddLabel("Players: " .. tostring(#Players:GetPlayers()))
    GBServer:AddLabel("Latency: -- ms")
    GBAnti:AddLabel("AC: checking...")
    local function setStatusVisual(status)
        local text = "AC: ISSUE"
        local col = Color3.fromRGB(255, 170, 60)
        if status == "bypassed" then text = "AC: BYPASSED" col = Color3.fromRGB(80, 255, 120)
        elseif status == "detected" then text = "AC: DETECTED" col = Color3.fromRGB(255, 70, 70) end
        pcall(function()
            for _, d in ipairs(Window.Frame:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text:sub(1,3) == "AC:" then
                    d.Text = text
                    d.TextColor3 = col
                end
            end
        end)
    end
    task.defer(function()
        task.wait(2.6)
        if Anti and Anti.GetStatus then setStatusVisual(Anti.GetStatus()) end
    end)
    GBAnti:AddDropdown({
        Text = "Auto Resolve",
        Values = {"Run"},
        Default = "Run",
        Callback = function()
            local st = "issue"
            pcall(function()
                if Anti.Resolve then st = Anti.Resolve() end
            end)
            setStatusVisual(st)
        end,
    })

    -- latency poll
    task.spawn(function()
        while Window.Frame and Window.Frame.Parent do
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            pcall(function()
                for _, d in ipairs(Window.Frame:GetDescendants()) do
                    if d:IsA("TextLabel") and d.Text:find("Latency:") then
                        d.Text = "Latency: " .. tostring(ping) .. " ms"
                    end
                    if d:IsA("TextLabel") and d.Text:find("Players:") then
                        d.Text = "Players: " .. tostring(#Players:GetPlayers())
                    end
                end
                if Anti and Anti.GetStatus then setStatusVisual(Anti.GetStatus()) end
            end)
            task.wait(1)
        end
    end)

    -- Combat
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
        Text = "FOV Color",
        Values = {"Open"},
        Default = "Open",
        Callback = function()
            local g = guiRoot()
            if g then openColorPicker(g, Silent.Config.FOVColor, function(c) Silent.Config.FOVColor = c end) end
        end,
    })
    GBBot:AddToggle({Text = "Triggerbot", Default = Silent.Config.Triggerbot, Callback = function(v) Silent.Config.Triggerbot = v end})
    GBBot:AddToggle({Text = "Auto Shoot", Default = Silent.Config.AutoShoot, Callback = function(v) Silent.Config.AutoShoot = v end})
    if Config then
        local names = Config.GetKillSoundNames()
        local sel = Config.Get().selectedKillSound
        if not sel or sel == "" then sel = "Off" end
        GBBot:AddDropdown({
            Text = "Kill Sound",
            Values = names,
            Default = sel,
            Callback = function(name) Config.SetSelectedKillSound(name) end,
        })
        GBBot:AddDropdown({
            Text = "Preview Sound",
            Values = {"Play"},
            Default = "Play",
            Callback = function()
                if KillSound and KillSound.Preview then KillSound.Preview() end
            end,
        })
    end

    -- Visuals
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
    GBHud:AddDropdown({Text = "Crosshair", Values = {"Default","Cross","Dot","Off"}, Default = "Default", Callback = function(v) Perf.SetCrosshair(v) end})
    GBHud:AddToggle({Text = "FPS / Ping", Default = Perf.Config.ShowFPS, Callback = function(v) Perf.Config.ShowFPS = v end})

    -- ESP
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
    GBStyle:AddDropdown({Text = "Name Origin", Values = {"Username","DisplayName"}, Default = "Username", Callback = function(v) ESP.Config.NameOrigin = v end})
    GBStyle:AddDropdown({Text = "ESP Font", Values = {"UI","System","Plex","Monospace"}, Default = "UI", Callback = function(v) ESP.Config.Font = v end})
    GBStyle:AddDropdown({Text = "Color Mode", Values = {"Static","Rainbow"}, Default = "Static", Callback = function(v) ESP.Config.ColorMode = v end})
    GBStyle:AddDropdown({Text = "Tracer Origin", Values = {"Bottom","Center","Mouse"}, Default = ESP.Config.TracerFrom, Callback = function(v) ESP.Config.TracerFrom = v end})
    GBStyle:AddSlider({Text = "Max Distance", Min = 100, Max = 2000, Default = ESP.Config.MaxDistance, Suffix = "m", Callback = function(v) ESP.Config.MaxDistance = v end})
    GBStyle:AddDropdown({Text = "Box Color", Values = {"Open"}, Default = "Open", Callback = function()
        local g = guiRoot()
        if g then openColorPicker(g, ESP.Config.Color, function(c, mode) ESP.Config.Color = c if mode == "Rainbow" then ESP.Config.ColorMode = "Rainbow" end end) end
    end})
    GBStyle:AddDropdown({Text = "Name Color", Values = {"Open"}, Default = "Open", Callback = function()
        local g = guiRoot()
        if g then openColorPicker(g, ESP.Config.NameColor, function(c) ESP.Config.NameColor = c end) end
    end})
    GBStyle:AddDropdown({Text = "Distance Color", Values = {"Open"}, Default = "Open", Callback = function()
        local g = guiRoot()
        if g then openColorPicker(g, ESP.Config.DistColor, function(c) ESP.Config.DistColor = c end) end
    end})
    GBStyle:AddDropdown({Text = "Chams Color", Values = {"Open"}, Default = "Open", Callback = function()
        local g = guiRoot()
        if g then openColorPicker(g, ESP.Config.ChamsColor, function(c) ESP.Config.ChamsColor = c end) end
    end})

    -- Performance
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

    -- Config
    local TabConfig = Window:CreateTab("Config")
    local GBTheme = TabConfig:CreateGroupbox("Theme", "Left")
    local GBFont = TabConfig:CreateGroupbox("Font", "Right")
    GBTheme:AddDropdown({
        Text = "Theme",
        Values = {"Default","Ubuntu","Tokyo","Blossom","Midnight","Dark","Hacker"},
        Default = "Default",
        Callback = function(name) currentTheme = name applyTheme(Window, name, currentUIFont) end,
    })
    GBFont:AddDropdown({
        Text = "UI Font",
        Values = UI_FONTS,
        Default = "Code",
        Callback = function(name) currentUIFont = name applyTheme(Window, currentTheme, name) end,
    })

    -- Beta
    local TabBeta = Window:CreateTab("Beta")
    local GBBeta = TabBeta:CreateGroupbox("Experimental", "Left")
    GBBeta:AddToggle({Text = "No Reload", Default = Silent.Config.NoReload, Callback = function(v) Silent.Config.NoReload = v end})

    -- Info
    local TabInfo = Window:CreateTab("Info")
    local GBInfo = TabInfo:CreateGroupbox("Features", "Left")
    local GBNoRel = TabInfo:CreateGroupbox("No Reload", "Right")
    local GBCtl = TabInfo:CreateGroupbox("Controls", "Left")
    local GBSnd = TabInfo:CreateGroupbox("Kill Sounds", "Right")
    GBInfo:AddLabel("LarpSec - Flick v1")
    GBInfo:AddLabel("Triggerbot: crosshair hit")
    GBInfo:AddLabel("AutoShoot: FOV + visible")
    GBInfo:AddLabel("Chams: Highlight fill+outline")
    GBNoRel:AddLabel("State: experimental")
    GBNoRel:AddLabel("Lever: config reloadTime")
    GBNoRel:AddLabel("Not proven live timer")
    GBCtl:AddLabel("RightShift · menu")
    GBCtl:AddLabel("Title bar · drag")
    GBSnd:AddLabel("Edit src/config.lua SOUNDS")
    GBSnd:AddLabel("Preview Sound to test")
    GBSnd:AddLabel("No default sound shipped")

    Window.Frame.Visible = true
    applyTheme(Window, "Default", "Code")
end

return UI
