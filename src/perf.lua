--[[
    Flick · Performance + world visuals helpers
]]

local Lighting    = game:GetService("Lighting")
local RunService  = game:GetService("RunService")
local Stats       = game:GetService("Stats")
local Players     = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

local Perf = {}

Perf.Config = {
    ShowFPS          = false,
    OptimizeLighting = false,
    OptimizeTextures = false,
    ReduceGraphics   = false,
    Culling          = false,
    HideShadows      = false,
    HideParticles    = false,
    OptimizeVFX      = false,
    Fullbright       = false,
    FogEnabled       = true,
    FogStart         = 0,
    FogEnd           = 1000,
    Stretch          = 1, -- 1 = normal, higher = wider FOV stretch feel
    ThirdPerson      = false,
}

local saved = {}
local overlayGui, fpsLabel, pingLabel
local crosshairGui, crosshairFrame
local particleConn

local function saveLighting()
    if saved.done then return end
    saved.done = true
    saved.Brightness = Lighting.Brightness
    saved.FogStart = Lighting.FogStart
    saved.FogEnd = Lighting.FogEnd
    saved.FogColor = Lighting.FogColor
    saved.GlobalShadows = Lighting.GlobalShadows
    saved.ClockTime = Lighting.ClockTime
    saved.Ambient = Lighting.Ambient
    saved.OutdoorAmbient = Lighting.OutdoorAmbient
end

local function applyLighting()
    saveLighting()
    if Perf.Config.OptimizeLighting or Perf.Config.ReduceGraphics then
        Lighting.Brightness = math.min(Lighting.Brightness, 2)
        pcall(function()
            for _, v in ipairs(Lighting:GetChildren()) do
                if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") then
                    v.Enabled = false
                end
            end
        end)
    end
    if Perf.Config.HideShadows then
        Lighting.GlobalShadows = false
    elseif saved.done then
        Lighting.GlobalShadows = saved.GlobalShadows
    end
    if Perf.Config.Fullbright then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.FogEnd = 1e6
    end
    if not Perf.Config.FogEnabled then
        Lighting.FogEnd = 1e6
        Lighting.FogStart = 1e6
    else
        Lighting.FogStart = Perf.Config.FogStart
        Lighting.FogEnd = Perf.Config.FogEnd
    end
end

local function applyParticles(hide)
    pcall(function()
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke") or inst:IsA("Fire") then
                if hide then
                    inst.Enabled = false
                end
            end
            if Perf.Config.OptimizeVFX and (inst:IsA("Explosion") or inst.Name:lower():find("vfx")) then
                pcall(function() inst:Destroy() end)
            end
        end
    end)
end

local function applyTextures(opt)
    if not opt then return end
    pcall(function()
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("Texture") or inst:IsA("Decal") then
                inst.Transparency = math.max(inst.Transparency, 0.35)
            end
            if inst:IsA("MeshPart") then
                pcall(function() inst.TextureID = "" end)
            end
        end
    end)
end

local function applyCulling(on)
    if not on then return end
    pcall(function()
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BasePart") and not inst.Parent:FindFirstChildOfClass("Humanoid") then
                local n = inst.Name:lower()
                if n:find("debris") or n:find("detail") or n:find("leaf") or n:find("clutter") then
                    inst.LocalTransparencyModifier = 1
                end
            end
        end
    end)
end

function Perf.Refresh()
    applyLighting()
    if Perf.Config.HideParticles or Perf.Config.OptimizeVFX then
        applyParticles(true)
    end
    if Perf.Config.OptimizeTextures or Perf.Config.ReduceGraphics then
        applyTextures(true)
    end
    if Perf.Config.Culling then
        applyCulling(true)
    end
end

local function makeOverlay()
    if overlayGui then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "LarpSecOverlay"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 110, 0, 44)
    frame.Position = UDim2.new(0, 12, 0, 12)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)

    fpsLabel = Instance.new("TextLabel")
    fpsLabel.Size = UDim2.new(1, -8, 0, 20)
    fpsLabel.Position = UDim2.new(0, 4, 0, 2)
    fpsLabel.BackgroundTransparency = 1
    fpsLabel.Text = "FPS  --"
    fpsLabel.TextColor3 = Color3.fromRGB(200, 220, 255)
    fpsLabel.TextSize = 12
    fpsLabel.Font = Enum.Font.GothamBold
    fpsLabel.TextXAlignment = Enum.TextXAlignment.Left
    fpsLabel.Parent = frame

    pingLabel = Instance.new("TextLabel")
    pingLabel.Size = UDim2.new(1, -8, 0, 20)
    pingLabel.Position = UDim2.new(0, 4, 0, 22)
    pingLabel.BackgroundTransparency = 1
    pingLabel.Text = "PING --"
    pingLabel.TextColor3 = Color3.fromRGB(180, 200, 220)
    pingLabel.TextSize = 12
    pingLabel.Font = Enum.Font.Gotham
    pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    pingLabel.Parent = frame

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

    overlayGui = gui
end

local function makeCrosshair()
    if crosshairGui then return end
    local gui = Instance.new("ScreenGui")
    gui.Name = "LarpSecCrosshair"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    crosshairGui = gui

    local f = Instance.new("Frame")
    f.Name = "CH"
    f.Size = UDim2.new(0, 12, 0, 12)
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Position = UDim2.new(0.5, 0, 0.5, 0)
    f.BackgroundTransparency = 1
    f.Parent = gui
    crosshairFrame = f

    local function arm(axis, len, thick)
        local a = Instance.new("Frame")
        a.BorderSizePixel = 0
        a.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        if axis == "h" then
            a.Size = UDim2.new(0, len, 0, thick)
            a.Position = UDim2.new(0.5, -len/2, 0.5, -thick/2)
        else
            a.Size = UDim2.new(0, thick, 0, len)
            a.Position = UDim2.new(0.5, -thick/2, 0.5, -len/2)
        end
        a.Parent = f
        return a
    end
    arm("h", 10, 2)
    arm("v", 10, 2)
end

Perf.CrosshairStyle = "Default" -- Default, Cross, Dot, Off

function Perf.SetCrosshair(style)
    Perf.CrosshairStyle = style
    makeCrosshair()
    if not crosshairFrame then return end
    crosshairGui.Enabled = style ~= "Off"
    for _, c in ipairs(crosshairFrame:GetChildren()) do c:Destroy() end
    if style == "Off" then return end
    local col = Color3.fromRGB(255, 255, 255)
    if style == "Dot" then
        local d = Instance.new("Frame")
        d.Size = UDim2.new(0, 4, 0, 4)
        d.Position = UDim2.new(0.5, -2, 0.5, -2)
        d.BorderSizePixel = 0
        d.BackgroundColor3 = col
        d.Parent = crosshairFrame
        Instance.new("UICorner", d).CornerRadius = UDim.new(1, 0)
    else
        local len = style == "Cross" and 14 or 10
        for _, axis in ipairs({"h", "v"}) do
            local a = Instance.new("Frame")
            a.BorderSizePixel = 0
            a.BackgroundColor3 = col
            if axis == "h" then
                a.Size = UDim2.new(0, len, 0, 2)
                a.Position = UDim2.new(0.5, -len/2, 0.5, -1)
            else
                a.Size = UDim2.new(0, 2, 0, len)
                a.Position = UDim2.new(0.5, -1, 0.5, -len/2)
            end
            a.Parent = crosshairFrame
        end
    end
end

function Perf.SetThirdPerson(on)
    Perf.Config.ThirdPerson = on
    pcall(function()
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if on then
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
            if hum then
                hum.CameraOffset = Vector3.new(0, 1.5, 0)
            end
            Camera.CameraType = Enum.CameraType.Custom
            LocalPlayer.CameraMinZoomDistance = 8
            LocalPlayer.CameraMaxZoomDistance = 20
            pcall(function() Camera.CameraSubject = hum end)
        else
            LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
            if hum then hum.CameraOffset = Vector3.zero end
            LocalPlayer.CameraMinZoomDistance = 0.5
            LocalPlayer.CameraMaxZoomDistance = 0.5
        end
    end)
end

function Perf.Init()
    makeOverlay()
    makeCrosshair()
    Perf.SetCrosshair("Default")
    saveLighting()

    local frames, last = 0, tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - last >= 0.5 then
            local fps = math.floor(frames / (now - last) + 0.5)
            frames = 0
            last = now
            if fpsLabel then fpsLabel.Text = "FPS  " .. tostring(fps) end
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            if pingLabel then pingLabel.Text = "PING " .. tostring(ping) .. "ms" end
        end
        if overlayGui then overlayGui.Enabled = Perf.Config.ShowFPS end

        -- stretch: widen FOV
        if Camera and Perf.Config.Stretch and Perf.Config.Stretch ~= 1 then
            local base = 70
            Camera.FieldOfView = math.clamp(base * Perf.Config.Stretch, 50, 120)
        end

        if Perf.Config.ThirdPerson then
            pcall(function()
                if LocalPlayer.CameraMode ~= Enum.CameraMode.Classic then
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                end
            end)
        end
    end)

    task.spawn(function()
        while true do
            task.wait(2)
            if Perf.Config.HideParticles or Perf.Config.OptimizeVFX or Perf.Config.Culling
                or Perf.Config.OptimizeTextures or Perf.Config.Fullbright then
                Perf.Refresh()
            end
        end
    end)
end

return Perf
