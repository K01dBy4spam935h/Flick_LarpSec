--[[
    Flick · Performance mode + FPS/Ping overlay
]]

local Perf = {}

local Lighting     = game:GetService("Lighting")
local RunService   = game:GetService("RunService")
local Stats        = game:GetService("Stats")
local Players      = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer

Perf.Config = {
    Enabled = false,
    ShowFPS = true,
}

local saved = {}
local fpsLabel, pingLabel
local overlayGui

local function applyPerf(on)
    if on then
        saved.QualityLevel = settings().Rendering.QualityLevel
        saved.GlobalShadows = Lighting.GlobalShadows
        saved.FogEnd = Lighting.FogEnd
        saved.Brightness = Lighting.Brightness
        saved.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale
        saved.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale
        saved.Technology = Lighting.Technology

        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        end)
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = math.min(Lighting.Brightness, 1.5)
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        pcall(function()
            Lighting.Technology = Enum.Technology.Legacy
        end)

        -- soft cull distant particles / trails
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then
                pcall(function()
                    if not v:GetAttribute("_flickSaved") then
                        v:SetAttribute("_flickSaved", v.Enabled)
                        v.Enabled = false
                    end
                end)
            end
        end
    else
        if saved.QualityLevel then
            pcall(function() settings().Rendering.QualityLevel = saved.QualityLevel end)
        end
        if saved.GlobalShadows ~= nil then Lighting.GlobalShadows = saved.GlobalShadows end
        if saved.FogEnd then Lighting.FogEnd = saved.FogEnd end
        if saved.Brightness then Lighting.Brightness = saved.Brightness end
        if saved.EnvironmentDiffuseScale then Lighting.EnvironmentDiffuseScale = saved.EnvironmentDiffuseScale end
        if saved.EnvironmentSpecularScale then Lighting.EnvironmentSpecularScale = saved.EnvironmentSpecularScale end
        if saved.Technology then pcall(function() Lighting.Technology = saved.Technology end) end

        for _, v in ipairs(workspace:GetDescendants()) do
            if v:GetAttribute("_flickSaved") ~= nil then
                pcall(function()
                    v.Enabled = v:GetAttribute("_flickSaved")
                    v:SetAttribute("_flickSaved", nil)
                end)
            end
        end
    end
end

local function makeOverlay()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FlickPerf"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

    local frame = Instance.new("Frame")
    frame.Name = "Counter"
    frame.Size = UDim2.new(0, 110, 0, 44)
    frame.Position = UDim2.new(0, 12, 0, 12)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.25
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 90, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.4
    stroke.Parent = frame

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

    -- drag
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
    return frame
end

function Perf.Init()
    makeOverlay()

    local frames = 0
    local last = tick()
    RunService.RenderStepped:Connect(function()
        frames = frames + 1
        local now = tick()
        if now - last >= 0.5 then
            local fps = math.floor(frames / (now - last) + 0.5)
            frames = 0
            last = now
            if fpsLabel then
                fpsLabel.Text = "FPS  " .. tostring(fps)
            end
            local ping = 0
            pcall(function()
                ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            end)
            if pingLabel then
                pingLabel.Text = "PING " .. tostring(ping) .. "ms"
            end
        end

        if overlayGui then
            overlayGui.Enabled = Perf.Config.ShowFPS
        end
    end)
end

function Perf.SetEnabled(v)
    Perf.Config.Enabled = v
    applyPerf(v)
end

return Perf
