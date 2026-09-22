--[[
    Flick · ESP
    Boxes / Names / Distance / Tracers · colorable · no health (one-shot)
]]

local ESP = {}

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

ESP.Config = {
    Enabled     = true,
    Boxes       = true,
    Names       = true,
    Distance    = true,
    Tracers     = true,
    MaxDistance = 1400,
    Color       = Color3.fromRGB(120, 90, 255),
    TracerFrom  = "Bottom",
}

local Cache = {}

local function GetChar(plr) return plr and plr.Character end
local function GetHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function GetRoot(c)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
end
local function GetPart(c, n) return c and c:FindFirstChild(n) end

local function Make(plr)
    local t = {
        Box      = Drawing.new("Square"),
        Name     = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer   = Drawing.new("Line"),
    }
    t.Box.Thickness = 1.5
    t.Box.Filled = false
    t.Box.Color = ESP.Config.Color
    t.Box.Visible = false

    t.Name.Size = 14
    t.Name.Center = true
    t.Name.Outline = true
    t.Name.Color = Color3.new(1,1,1)
    t.Name.Font = 2
    t.Name.Visible = false

    t.Distance.Size = 12
    t.Distance.Center = true
    t.Distance.Outline = true
    t.Distance.Color = Color3.fromRGB(200, 200, 210)
    t.Distance.Font = 2
    t.Distance.Visible = false

    t.Tracer.Thickness = 1.2
    t.Tracer.Color = ESP.Config.Color
    t.Tracer.Visible = false

    Cache[plr] = t
end

local function Kill(plr)
    local t = Cache[plr]
    if not t then return end
    for _, d in pairs(t) do pcall(function() d:Remove() end) end
    Cache[plr] = nil
end

local function Update()
    if not ESP.Config.Enabled then
        for _, t in pairs(Cache) do
            for _, d in pairs(t) do d.Visible = false end
        end
        return
    end

    local lpRoot = GetRoot(GetChar(LocalPlayer))
    local mouse  = UserInputService:GetMouseLocation()
    local vp     = Camera.ViewportSize
    local col    = ESP.Config.Color

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not Cache[plr] then Make(plr) end
        local t = Cache[plr]
        local char = GetChar(plr)
        local hum  = GetHum(char)
        local root = GetRoot(char)

        if not (char and hum and root and hum.Health > 0) then
            for _, d in pairs(t) do d.Visible = false end
            continue
        end

        local dist = lpRoot and (lpRoot.Position - root.Position).Magnitude or 9999
        if dist > ESP.Config.MaxDistance then
            for _, d in pairs(t) do d.Visible = false end
            continue
        end

        local head = GetPart(char, "Head") or root
        local headV, headOn = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.35, 0))
        local rootV, rootOn = Camera:WorldToViewportPoint(root.Position)
        local footV = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        if not rootOn and not headOn then
            for _, d in pairs(t) do d.Visible = false end
            continue
        end

        local headPos = Vector2.new(headV.X, headV.Y)
        local rootPos = Vector2.new(rootV.X, rootV.Y)
        local footPos = Vector2.new(footV.X, footV.Y)
        local height  = math.abs(headPos.Y - footPos.Y)
        local width   = height * 0.55
        local boxX    = rootPos.X - width / 2
        local boxY    = headPos.Y

        if ESP.Config.Boxes then
            t.Box.Size = Vector2.new(width, height)
            t.Box.Position = Vector2.new(boxX, boxY)
            t.Box.Color = col
            t.Box.Visible = true
        else
            t.Box.Visible = false
        end

        if ESP.Config.Names then
            t.Name.Text = plr.Name
            t.Name.Position = Vector2.new(rootPos.X, boxY - 16)
            t.Name.Visible = true
        else
            t.Name.Visible = false
        end

        if ESP.Config.Distance then
            t.Distance.Text = string.format("[%dm]", math.floor(dist))
            t.Distance.Position = Vector2.new(rootPos.X, boxY + height + 2)
            t.Distance.Visible = true
        else
            t.Distance.Visible = false
        end

        if ESP.Config.Tracers then
            local from
            if ESP.Config.TracerFrom == "Mouse" then
                from = mouse
            elseif ESP.Config.TracerFrom == "Center" then
                from = Vector2.new(vp.X / 2, vp.Y / 2)
            else
                from = Vector2.new(vp.X / 2, vp.Y)
            end
            t.Tracer.From = from
            t.Tracer.To = Vector2.new(rootPos.X, boxY + height)
            t.Tracer.Color = col
            t.Tracer.Visible = true
        else
            t.Tracer.Visible = false
        end
    end
end

function ESP.Init()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then Make(plr) end
    end
    Players.PlayerAdded:Connect(function(plr)
        task.wait(1)
        if plr ~= LocalPlayer then Make(plr) end
    end)
    Players.PlayerRemoving:Connect(Kill)
    RunService.RenderStepped:Connect(Update)
end

return ESP
