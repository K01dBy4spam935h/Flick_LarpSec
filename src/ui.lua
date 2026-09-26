--[[
    LarpSec - Flick v1 UI
]]

local UI = {}
local Players = game:GetService("Players")
local Stats = game:GetService("Stats")
local LocalPlayer = Players.LocalPlayer

local Themes = {
    Default = { AnimA = Color3.fromRGB(18,20,32), AnimB = Color3.fromRGB(45,60,100), GradA = Color3.fromRGB(24,24,28), GradB = Color3.fromRGB(40,55,85), Groupbox = Color3.fromRGB(30,30,30), Border = Color3.fromRGB(46,46,46), Accent = Color3.fromRGB(74,144,226), Text = Color3.fromRGB(255,255,255) },
    Ubuntu = { AnimA = Color3.fromRGB(40,8,25), AnimB = Color3.fromRGB(150,55,18), GradA = Color3.fromRGB(55,15,30), GradB = Color3.fromRGB(130,45,18), Groupbox = Color3.fromRGB(55,22,38), Border = Color3.fromRGB(120,55,35), Accent = Color3.fromRGB(233,84,32), Text = Color3.fromRGB(255,240,230) },
    Tokyo = { AnimA = Color3.fromRGB(26,27,50), AnimB = Color3.fromRGB(85,55,130), GradA = Color3.fromRGB(30,34,55), GradB = Color3.fromRGB(70,45,110), Groupbox = Color3.fromRGB(36,40,59), Border = Color3.fromRGB(65,72,104), Accent = Color3.fromRGB(122,162,247), Text = Color3.fromRGB(192,202,245) },
    Blossom = { AnimA = Color3.fromRGB(45,25,40), AnimB = Color3.fromRGB(130,55,90), GradA = Color3.fromRGB(50,32,42), GradB = Color3.fromRGB(120,55,85), Groupbox = Color3.fromRGB(58,40,50), Border = Color3.fromRGB(120,70,90), Accent = Color3.fromRGB(255,140,180), Text = Color3.fromRGB(255,230,240) },
    Midnight = { AnimA = Color3.fromRGB(8,12,30), AnimB = Color3.fromRGB(45,35,95), GradA = Color3.fromRGB(14,18,36), GradB = Color3.fromRGB(35,25,75), Groupbox = Color3.fromRGB(16,20,40), Border = Color3.fromRGB(40,55,100), Accent = Color3.fromRGB(90,130,255), Text = Color3.fromRGB(210,220,255) },
    Dark = { AnimA = Color3.fromRGB(10,10,10), AnimB = Color3.fromRGB(50,50,50), GradA = Color3.fromRGB(16,16,16), GradB = Color3.fromRGB(42,42,42), Groupbox = Color3.fromRGB(18,18,18), Border = Color3.fromRGB(36,36,36), Accent = Color3.fromRGB(200,200,200), Text = Color3.fromRGB(230,230,230) },
    Hacker = { AnimA = Color3.fromRGB(4,16,4), AnimB = Color3.fromRGB(25,90,30), GradA = Color3.fromRGB(8,22,8), GradB = Color3.fromRGB(18,60,18), Groupbox = Color3.fromRGB(10,24,10), Border = Color3.fromRGB(20,70,20), Accent = Color3.fromRGB(0,255,70), Text = Color3.fromRGB(180,255,180) },
}

local UI_FONTS = {"Gotham","GothamBold","SourceSans","SourceSansBold","Code","Fantasy","Arcade","Bodoni","Garamond","Oswald"}

local function getExecutorName()
    local name
    pcall(function() if identifyexecutor then name = identifyexecutor() end end)
    if not name or name == "" then pcall(function() if getexecutorname then name = getexecutorname() end end) end
    return tostring(name or "Unknown")
end

local animToken = 0
local function startAnimatedBackground(window, theme)
    animToken = animToken + 1
    local token = animToken
    local root = window.Frame
    if not root then return end
    local c0, c1, acc = theme.AnimA, theme.AnimB, theme.Accent
    local seq = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c0),
        ColorSequenceKeypoint.new(0.35, acc),
        ColorSequenceKeypoint.new(0.7, c1),
        ColorSequenceKeypoint.new(1, c0),
    })
    local grads = {}
    local function paint(frame)
        if not frame or not frame:IsA("Frame") then return end
        frame.BackgroundColor3 = Color3.new(1,1,1)
        local g = frame:FindFirstChild("PanelGrad")
        if not g then g = Instance.new("UIGradient") g.Name = "PanelGrad" g.Parent = frame end
        g.Color = seq
        table.insert(grads, g)
    end
    paint(root)
    for _, name in ipairs({"TopBar","Sidebar","Content"}) do
        local f = root:FindFirstChild(name)
        if not f then
            for _, d in ipairs(root:GetDescendants()) do
                if d.Name == name and d:IsA("Frame") then f = d break end
            end
        end
        paint(f)
    end
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("Frame") and d:FindFirstChild("Body") then paint(d) end
    end
    task.spawn(function()
        local rot = 0
        while token == animToken and root.Parent do
            rot = (rot + 0.9) % 360
            for _, g in ipairs(grads) do
                if g and g.Parent then g.Rotation = rot end
            end
            task.wait(0.025)
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
                if n:find("group") then d.BackgroundColor3 = Color3.new(1,1,1) end
                if n == "sliderfill" or n == "fill" then d.BackgroundColor3 = theme.Accent end
            end
            if d:IsA("UIStroke") then d.Color = theme.Border end
            if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) and fontName then
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
    popup.Size = UDim2.new(0, 240, 0, 230)
    popup.Position = UDim2.new(0.5, -120, 0.5, -115)
    popup.BackgroundColor3 = Color3.fromRGB(22,22,28)
    popup.BorderSizePixel = 0
    popup.ZIndex = 90
    popup.Parent = parentGui
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 6)

    local h, s, v = Color3.toHSV(current or Color3.fromRGB(74,144,226))
    local mode = "Static"

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -12, 0, 18)
    title.Position = UDim2.new(0, 8, 0, 4)
    title.BackgroundTransparency = 1
    title.Text = "HSV Color Canvas"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 12
    title.Font = Enum.Font.Code
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 91
    title.Parent = popup

    local sv = Instance.new("ImageButton")
    sv.Size = UDim2.new(0, 170, 0, 120)
    sv.Position = UDim2.new(0, 10, 0, 28)
    sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    sv.BorderSizePixel = 0
    sv.AutoButtonColor = false
    sv.ZIndex = 91
    sv.Parent = popup
    local white = Instance.new("Frame")
    white.Size = UDim2.new(1,0,1,0)
    white.BackgroundColor3 = Color3.new(1,1,1)
    white.BorderSizePixel = 0
    white.ZIndex = 92
    white.Parent = sv
    local wg = Instance.new("UIGradient")
    wg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)})
    wg.Parent = white
    local black = Instance.new("Frame")
    black.Size = UDim2.new(1,0,1,0)
    black.BackgroundColor3 = Color3.new(0,0,0)
    black.BorderSizePixel = 0
    black.ZIndex = 93
    black.Parent = sv
    local bg = Instance.new("UIGradient")
    bg.Rotation = 90
    bg.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)})
    bg.Parent = black

    local hueBar = Instance.new("ImageButton")
    hueBar.Size = UDim2.new(0, 18, 0, 120)
    hueBar.Position = UDim2.new(0, 190, 0, 28)
    hueBar.BorderSizePixel = 0
    hueBar.AutoButtonColor = false
    hueBar.BackgroundColor3 = Color3.new(1,1,1)
    hueBar.ZIndex = 91
    hueBar.Parent = popup
    local hg = Instance.new("UIGradient")
    hg.Rotation = 90
    local keys = {}
    for i = 0, 6 do table.insert(keys, ColorSequenceKeypoint.new(i/6, Color3.fromHSV(i/6, 1, 1))) end
    hg.Color = ColorSequence.new(keys)
    hg.Parent = hueBar

    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 36, 0, 18)
    preview.Position = UDim2.new(0, 10, 0, 158)
    preview.BorderSizePixel = 0
    preview.ZIndex = 91
    preview.Parent = popup

    local hex = Instance.new("TextLabel")
    hex.Size = UDim2.new(0, 100, 0, 18)
    hex.Position = UDim2.new(0, 52, 0, 158)
    hex.BackgroundTransparency = 1
    hex.TextColor3 = Color3.new(1,1,1)
    hex.TextSize = 12
    hex.Font = Enum.Font.Code
    hex.TextXAlignment = Enum.TextXAlignment.Left
    hex.ZIndex = 91
    hex.Parent = popup

    local modeLbl = Instance.new("TextLabel")
    modeLbl.Size = UDim2.new(0, 70, 0, 18)
    modeLbl.Position = UDim2.new(0, 155, 0, 158)
    modeLbl.BackgroundTransparency = 1
    modeLbl.TextColor3 = Color3.fromRGB(180,180,200)
    modeLbl.TextSize = 11
    modeLbl.Font = Enum.Font.Code
    modeLbl.ZIndex = 91
    modeLbl.Parent = popup

    local function emit()
        local c
        if mode == "Rainbow" then c = Color3.fromHSV((tick()*0.2)%1, 0.9, 1)
        elseif mode == "StaticRainbow" then c = Color3.fromRGB(255,40,180)
        else c = Color3.fromHSV(h,s,v) end
        preview.BackgroundColor3 = c
        hex.Text = string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
        modeLbl.Text = mode
        onChange(c, mode)
    end
    emit()

    local UIS = game:GetService("UserInputService")
    local dragSV, dragH = false, false
    local function pickSV(input)
        local rel = Vector2.new(input.Position.X, input.Position.Y) - sv.AbsolutePosition
        s = math.clamp(rel.X / math.max(sv.AbsoluteSize.X,1), 0, 1)
        v = 1 - math.clamp(rel.Y / math.max(sv.AbsoluteSize.Y,1), 0, 1)
        mode = "Static"
        emit()
    end
    local function pickH(input)
        local rel = (input.Position.Y - hueBar.AbsolutePosition.Y) / math.max(hueBar.AbsoluteSize.Y,1)
        h = math.clamp(rel, 0, 1)
        sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        mode = "Static"
        emit()
    end
    sv.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragSV = true pickSV(i) end end)
    hueBar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragH = true pickH(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragSV, dragH = false, false end end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        if dragSV then pickSV(i) end
        if dragH then pickH(i) end
    end)

    local function btn(text, x, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 52, 0, 22)
        b.Position = UDim2.new(0, x, 0, 198)
        b.BackgroundColor3 = Color3.fromRGB(40,42,55)
        b.Text = text
        b.TextColor3 = Color3.new(1,1,1)
        b.TextSize = 11
        b.Font = Enum.Font.Code
        b.ZIndex = 91
        b.Parent = popup
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        b.MouseButton1Click:Connect(cb)
    end
    btn("RGB", 10, function()
        mode = "Static"
        local prim = {Color3.fromRGB(255,40,40), Color3.fromRGB(40,255,80), Color3.fromRGB(40,120,255), Color3.fromRGB(255,220,40)}
        local c = prim[(math.floor(tick())%4)+1]
        h,s,v = Color3.toHSV(c)
        sv.BackgroundColor3 = Color3.fromHSV(h,1,1)
        emit()
    end)
    btn("Rain", 66, function() mode = "Rainbow" emit() end)
    btn("StatR", 122, function() mode = "StaticRainbow" emit() end)
    btn("Close", 178, function() popup:Destroy() end)

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
    local Window = Lib:CreateWindow({ Title = "LarpSec - Flick v1", Size = Vector2.new(620, 540) })
    local function guiRoot()
        return Lib.ScreenGui or game:GetService("CoreGui"):FindFirstChild("FlickLib")
    end
    local currentTheme, currentUIFont = "Default", "Code"

    local function colorChooser(label, getCol, setCol)
        -- button that opens HSV canvas
        return {
            open = function()
                local g = guiRoot()
                if g then openColorPicker(g, getCol(), function(c) setCol(c) end) end
            end
        }
    end

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
        local text, col = "AC: ISSUE", Color3.fromRGB(255,170,60)
        if status == "bypassed" then text, col = "AC: BYPASSED", Color3.fromRGB(80,255,120)
        elseif status == "detected" then text, col = "AC: DETECTED", Color3.fromRGB(255,70,70) end
        pcall(function()
            for _, d in ipairs(Window.Frame:GetDescendants()) do
                if d:IsA("TextLabel") and d.Text:sub(1,3) == "AC:" then
                    d.Text = text d.TextColor3 = col
                end
            end
        end)
    end
    task.defer(function()
        task.wait(2.6)
        if Anti and Anti.GetStatus then setStatusVisual(Anti.GetStatus()) end
    end)
    GBAnti:AddButton({
        Text = "Auto Resolve",
        Callback = function()
            local st = "issue"
            pcall(function() if Anti.Resolve then st = Anti.Resolve() end end)
            setStatusVisual(st)
        end,
    })
    task.spawn(function()
        while Window.Frame and Window.Frame.Parent do
            local ping = 0
            pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
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
    local GBBot = TabCombat:CreateGroupbox("Bots / Audio", "Right")
    GBSilent:AddToggle({Text = "Enabled", Default = Silent.Config.Enabled, Callback = function(v) Silent.Config.Enabled = v end})
    GBSilent:AddSlider({Text = "FOV", Min = 20, Max = 2000, Default = Silent.Config.FOV, Callback = function(v) Silent.Config.FOV = v end})
    GBSilent:AddSlider({Text = "Hit Chance", Min = 1, Max = 100, Default = Silent.Config.HitChance, Suffix = "%", Callback = function(v) Silent.Config.HitChance = v end})
    GBSilent:AddToggle({Text = "Show FOV", Default = Silent.Config.ShowFOV, Callback = function(v) Silent.Config.ShowFOV = v end})
    GBSilent:AddDropdown({
        Text = "Hit Part", Values = {"Torso","Head","HumanoidRootPart","UpperTorso"}, Default = "Torso",
        Callback = function(v)
            if v == "Torso" then Silent.Config.HitPart = "UpperTorso" Silent.Config.PreferTorso = true
            else Silent.Config.HitPart = v Silent.Config.PreferTorso = false end
        end,
    })
    GBSilent:AddToggle({Text = "Visible Check", Default = Silent.Config.VisibleCheck, Callback = function(v) Silent.Config.VisibleCheck = v end})
    GBSilent:AddToggle({Text = "Sticky Aim", Default = Silent.Config.Sticky, Callback = function(v) Silent.Config.Sticky = v end})
    GBSilent:AddButton({
        Text = "FOV Color — Choose Color",
        Callback = function()
            local g = guiRoot()
            if g then openColorPicker(g, Silent.Config.FOVColor, function(c) Silent.Config.FOVColor = c end) end
        end,
    })
    GBBot:AddToggle({Text = "Triggerbot", Default = Silent.Config.Triggerbot, Callback = function(v) Silent.Config.Triggerbot = v end})
    GBBot:AddToggle({Text = "Auto Shoot", Default = Silent.Config.AutoShoot, Callback = function(v) Silent.Config.AutoShoot = v end})

    if Config then
        local killDD = GBBot:AddDropdown({
            Text = "Kill Sound",
            Values = Config.GetKillSoundNames(),
            Default = Config.Get().selectedKillSound ~= "" and Config.Get().selectedKillSound or "Off",
            Callback = function(name) Config.SetSelectedKillSound(name) end,
        })
        GBBot:AddButton({ Text = "Preview Kill Sound", Callback = function() if KillSound then KillSound.Preview() end end })
        local deathDD = GBBot:AddDropdown({
            Text = "Death Sound",
            Values = Config.GetDeathSoundNames(),
            Default = Config.Get().selectedDeathSound ~= "" and Config.Get().selectedDeathSound or "Off",
            Callback = function(name) Config.SetSelectedDeathSound(name) end,
        })
        GBBot:AddButton({ Text = "Preview Death Sound", Callback = function() if KillSound then KillSound.PreviewDeath() end end })
        local musicDD = GBBot:AddDropdown({
            Text = "Music",
            Values = Config.GetMusicNames(),
            Default = Config.Get().selectedMusic ~= "" and Config.Get().selectedMusic or "Off",
            Callback = function(name) Config.SetSelectedMusic(name) end,
        })
        GBBot:AddSlider({
            Text = "Music Volume", Min = 0, Max = 100, Default = math.floor((Config.Get().musicVolume or 0.5)*100),
            Callback = function(v) if KillSound then KillSound.SetMusicVolume(v/100) end end,
        })
        GBBot:AddButton({ Text = "Play Music", Callback = function() if KillSound then KillSound.StartMusic() end end })
        GBBot:AddButton({ Text = "Stop Music", Callback = function() if KillSound then KillSound.StopMusic() end end })

        -- store refs for refresh after add
        UI._killDD, UI._deathDD, UI._musicDD = killDD, deathDD, musicDD
    end

    -- Visuals
    local TabVisuals = Window:CreateTab("Visuals")
    local GBWorld = TabVisuals:CreateGroupbox("World", "Left")
    local GBHud = TabVisuals:CreateGroupbox("HUD", "Right")
    GBWorld:AddToggle({Text = "Fullbright", Default = Perf.Config.Fullbright, Callback = function(v) Perf.Config.Fullbright = v Perf.Refresh() end})
    GBWorld:AddToggle({Text = "Fog", Default = Perf.Config.FogEnabled, Callback = function(v) Perf.Config.FogEnabled = v Perf.Refresh() end})
    GBWorld:AddSlider({Text = "Fog End", Min = 50, Max = 2000, Default = Perf.Config.FogEnd, Callback = function(v) Perf.Config.FogEnd = v Perf.Refresh() end})
    GBWorld:AddSlider({Text = "Stretch Res", Min = 10, Max = 20, Default = 10, Callback = function(v) Perf.Config.Stretch = v/10 end})
    GBWorld:AddToggle({Text = "Third Person", Default = false, Callback = function(v) Perf.SetThirdPerson(v) end})
    if Config then
        local bgDD = GBWorld:AddDropdown({
            Text = "Background",
            Values = Config.GetImageNames(),
            Default = Config.Get().selectedBackground ~= "" and Config.Get().selectedBackground or "Off",
            Callback = function(name)
                Config.SetSelectedBackground(name)
                if name == "Off" then Perf.SetBackground(nil)
                else Perf.SetBackground(Config.GetSelectedBackgroundId()) end
            end,
        })
        UI._bgDD = bgDD
    end
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
    GBESP:AddSlider({Text = "Chams Fill", Min = 0, Max = 90, Default = 45, Callback = function(v) ESP.Config.ChamsFill = v/100 end})
    GBStyle:AddDropdown({Text = "Name Origin", Values = {"Username","DisplayName"}, Default = "Username", Callback = function(v) ESP.Config.NameOrigin = v end})
    GBStyle:AddDropdown({Text = "ESP Font", Values = {"UI","System","Plex","Monospace"}, Default = "UI", Callback = function(v) ESP.Config.Font = v end})
    GBStyle:AddDropdown({Text = "Color Mode", Values = {"Static","Rainbow"}, Default = "Static", Callback = function(v) ESP.Config.ColorMode = v end})
    GBStyle:AddDropdown({Text = "Tracer Origin", Values = {"Bottom","Center","Mouse","Top"}, Default = ESP.Config.TracerFrom, Callback = function(v) ESP.Config.TracerFrom = v end})
    GBStyle:AddSlider({Text = "Max Distance", Min = 100, Max = 2000, Default = ESP.Config.MaxDistance, Suffix = "m", Callback = function(v) ESP.Config.MaxDistance = v end})
    GBStyle:AddButton({ Text = "Box Color — Choose Color", Callback = function()
        local g = guiRoot()
        if g then openColorPicker(g, ESP.Config.Color, function(c, mode) ESP.Config.Color = c if mode == "Rainbow" then ESP.Config.ColorMode = "Rainbow" end end) end
    end })
    GBStyle:AddButton({ Text = "Name Color — Choose Color", Callback = function()
        local g = guiRoot()
        if g then openColorPicker(g, ESP.Config.NameColor, function(c) ESP.Config.NameColor = c end) end
    end })
    GBStyle:AddButton({ Text = "Distance Color — Choose Color", Callback = function()
        local g = guiRoot()
        if g then openColorPicker(g, ESP.Config.DistColor, function(c) ESP.Config.DistColor = c end) end
    end })
    GBStyle:AddButton({ Text = "Chams Color — Choose Color", Callback = function()
        local g = guiRoot()
        if g then openColorPicker(g, ESP.Config.ChamsColor, function(c) ESP.Config.ChamsColor = c end) end
    end })

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

    -- Config tab
    local TabConfig = Window:CreateTab("Config")
    local GBTheme = TabConfig:CreateGroupbox("Theme", "Left")
    local GBSave = TabConfig:CreateGroupbox("Save / Load", "Right")
    local GBAdd = TabConfig:CreateGroupbox("Add Assets", "Left")

    GBTheme:AddDropdown({
        Text = "Theme", Values = {"Default","Ubuntu","Tokyo","Blossom","Midnight","Dark","Hacker"}, Default = "Default",
        Callback = function(name) currentTheme = name applyTheme(Window, name, currentUIFont) end,
    })
    GBTheme:AddDropdown({
        Text = "UI Font", Values = UI_FONTS, Default = "Code",
        Callback = function(name) currentUIFont = name applyTheme(Window, currentTheme, name) end,
    })

    GBSave:AddButton({
        Text = "Save Config",
        Callback = function()
            local ok = Config.SaveFile({
                silent = Silent.Config,
                esp = ESP.Config,
                perf = Perf.Config,
                theme = currentTheme,
                font = currentUIFont,
            })
            print(ok and "[LarpSec] config saved" or "[LarpSec] save failed")
        end,
    })
    GBSave:AddButton({
        Text = "Load Config",
        Callback = function()
            local feat = Config.LoadFile()
            if not feat then print("[LarpSec] no save found") return end
            if feat.silent then for k,v in pairs(feat.silent) do Silent.Config[k] = v end end
            if feat.esp then for k,v in pairs(feat.esp) do ESP.Config[k] = v end end
            if feat.perf then for k,v in pairs(feat.perf) do Perf.Config[k] = v end end
            if feat.theme then currentTheme = feat.theme applyTheme(Window, currentTheme, feat.font or currentUIFont) end
            if UI._killDD then UI._killDD.SetValues(UI._killDD, Config.GetKillSoundNames()) end
            if UI._deathDD then UI._deathDD.SetValues(UI._deathDD, Config.GetDeathSoundNames()) end
            if UI._musicDD then UI._musicDD.SetValues(UI._musicDD, Config.GetMusicNames()) end
            if UI._bgDD then UI._bgDD.SetValues(UI._bgDD, Config.GetImageNames()) end
            local bg = Config.GetSelectedBackgroundId()
            if bg then Perf.SetBackground(bg) end
            print("[LarpSec] config loaded")
        end,
    })

    local addType = "Kill"
    local nameIn, idIn
    GBAdd:AddDropdown({
        Text = "Asset Type",
        Values = {"Kill Sound", "Death Sound", "Music", "Background Image"},
        Default = "Kill Sound",
        Callback = function(v)
            if v == "Kill Sound" then addType = "Kill"
            elseif v == "Death Sound" then addType = "Death"
            elseif v == "Music" then addType = "Music"
            else addType = "Image" end
        end,
    })
    nameIn = GBAdd:AddInput({ Text = "Name", Placeholder = "my_sound", Default = "" })
    idIn = GBAdd:AddInput({ Text = "Asset ID", Placeholder = "123456789", Default = "" })
    GBAdd:AddButton({
        Text = "Add Asset",
        Callback = function()
            local name = nameIn.Get()
            local id = idIn.Get()
            if not name or name == "" or not id or id == "" then
                warn("[LarpSec] name and id required")
                return
            end
            if addType == "Kill" then
                Config.AddKillSound(name, id)
                if UI._killDD then UI._killDD.SetValues(UI._killDD, Config.GetKillSoundNames()) end
            elseif addType == "Death" then
                Config.AddDeathSound(name, id)
                if UI._deathDD then UI._deathDD.SetValues(UI._deathDD, Config.GetDeathSoundNames()) end
            elseif addType == "Music" then
                Config.AddMusic(name, id)
                if UI._musicDD then UI._musicDD.SetValues(UI._musicDD, Config.GetMusicNames()) end
            else
                Config.AddImage(name, id)
                if UI._bgDD then UI._bgDD.SetValues(UI._bgDD, Config.GetImageNames()) end
            end
            print("[LarpSec] added", addType, name)
        end,
    })

    -- Beta / Info
    local TabBeta = Window:CreateTab("Beta")
    TabBeta:CreateGroupbox("Experimental", "Left"):AddToggle({
        Text = "No Reload", Default = Silent.Config.NoReload, Callback = function(v) Silent.Config.NoReload = v end,
    })
    local TabInfo = Window:CreateTab("Info")
    local GBInfo = TabInfo:CreateGroupbox("Features", "Left")
    local GBSnd = TabInfo:CreateGroupbox("Assets", "Right")
    GBInfo:AddLabel("LarpSec - Flick v1")
    GBInfo:AddLabel("RightShift · menu")
    GBInfo:AddLabel("Title bar · drag")
    GBSnd:AddLabel("Add assets in Config tab")
    GBSnd:AddLabel("Save persists custom IDs")
    GBSnd:AddLabel("Images: rbxassetid + thumb fallback")

    Window.Frame.Visible = true
    applyTheme(Window, "Default", "Code")
end

return UI
