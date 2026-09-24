--[[
    Flick · Silent + Insta Reload v8
    Rebind on tool equip · quiet · no spam
]]

local Silent = {}

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

Silent.Config = {
    Enabled      = true,
    FOV          = 200,
    HitPart      = "UpperTorso",
    PreferTorso  = true,
    VisibleCheck = false,
    ShowFOV      = true,
    FOVColor     = Color3.fromRGB(74, 144, 226),
    FOVThickness = 1.5,
    Sticky       = true,
    HitChance    = 100,
    InstaReload  = false,
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = Silent.Config.FOVThickness
FOVCircle.NumSides  = 64
FOVCircle.Filled    = false
FOVCircle.Color     = Silent.Config.FOVColor
FOVCircle.Visible   = false
FOVCircle.ZIndex    = 2

local stickyTarget = nil
local controller = nil
local hookedNew = false
local lastScan = 0

local function GetChar(plr) return plr and plr.Character end
local function GetHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function GetPart(c, n) return c and c:FindFirstChild(n) end
local function Alive(plr)
    local c = GetChar(plr)
    local h = GetHum(c)
    return c and h and h.Health > 0
end

local function Visible(part)
    if not Silent.Config.VisibleCheck then return true end
    local origin = Camera.CFrame.Position
    local dir = part.Position - origin
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local hit = workspace:Raycast(origin, dir, params)
    return hit == nil or hit.Instance:IsDescendantOf(part.Parent)
end

local function CandidateParts(char)
    local list = {}
    if Silent.Config.PreferTorso then
        local ut = GetPart(char, "UpperTorso") or GetPart(char, "Torso")
        if ut then table.insert(list, ut) end
        local hrp = GetPart(char, "HumanoidRootPart")
        if hrp then table.insert(list, hrp) end
        local head = GetPart(char, "Head")
        if head then table.insert(list, head) end
        for _, name in ipairs({"LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}) do
            local p = GetPart(char, name)
            if p then table.insert(list, p) end
        end
    else
        local primary = GetPart(char, Silent.Config.HitPart)
        if primary then table.insert(list, primary) end
        for _, name in ipairs({"UpperTorso", "Torso", "HumanoidRootPart", "Head"}) do
            local p = GetPart(char, name)
            if p and p ~= primary then table.insert(list, p) end
        end
    end
    return list
end

local function GetClosest()
    if Silent.Config.Sticky and stickyTarget then
        local char = stickyTarget.Parent
        local hum = GetHum(char)
        if hum and hum.Health > 0 then
            local sp, on = Camera:WorldToViewportPoint(stickyTarget.Position)
            if on then
                local d = (Vector2.new(sp.X, sp.Y) - UserInputService:GetMouseLocation()).Magnitude
                if d <= Silent.Config.FOV * 1.2 then
                    return stickyTarget
                end
            end
        end
        stickyTarget = nil
    end

    local best, bestDist = nil, Silent.Config.FOV
    local mouse = UserInputService:GetMouseLocation()

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not Alive(plr) then continue end
        local char = GetChar(plr)
        for _, part in ipairs(CandidateParts(char)) do
            if not Visible(part) then continue end
            local sp, on = Camera:WorldToViewportPoint(part.Position)
            if not on then continue end
            local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
            if d < bestDist then
                bestDist = d
                best = part
            end
        end
    end

    if Silent.Config.Sticky then
        stickyTarget = best
    end
    return best
end

local function IsGunController(t)
    if type(t) ~= "table" then return false end
    local ok, res = pcall(function()
        return type(rawget(t, "Ammo")) == "number" and type(rawget(t, "reloadTime")) == "number"
    end)
    return ok and res
end

local function Patch(obj)
    obj = obj or controller
    if not obj or not IsGunController(obj) then return end
    pcall(function()
        local maxAmmo = rawget(obj, "MaxAmmo")
        if type(maxAmmo) ~= "number" or maxAmmo < 1 then maxAmmo = 1 end
        rawset(obj, "Ammo", maxAmmo)
        rawset(obj, "reloadTime", 0)
        if type(rawget(obj, "Reloading")) == "boolean" then rawset(obj, "Reloading", false) end
        if type(rawget(obj, "CanFire")) == "boolean" then rawset(obj, "CanFire", true) end
        if type(rawget(obj, "CanReload")) == "boolean" then rawset(obj, "CanReload", true) end
    end)
end

local function Scan()
    local now = tick()
    if now - lastScan < 0.5 then return controller ~= nil end
    lastScan = now

    local found = nil
    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if IsGunController(obj) then
                found = obj
            end
        end
    end)
    if found then
        controller = found
        return true
    end
    return false
end

local function HookNew()
    if hookedNew then return end
    local ok, GF = pcall(function()
        return require(ReplicatedStorage.ModuleScripts.GunModules.GunFramework)
    end)
    if not ok or type(GF) ~= "table" or type(GF.new) ~= "function" then return end

    local old = GF.new
    GF.new = function(...)
        local obj = old(...)
        if type(obj) == "table" and IsGunController(obj) then
            controller = obj
            if Silent.Config.InstaReload then
                Patch(obj)
            end
        elseif type(obj) == "table" then
            -- still track if it has Ammo after a tick (constructed async)
            task.defer(function()
                if IsGunController(obj) then
                    controller = obj
                    if Silent.Config.InstaReload then Patch(obj) end
                end
            end)
        end
        return obj
    end
    hookedNew = true
end

local function WatchCharacter(char)
    if not char then return end
    controller = nil

    local function onTool(tool)
        if not tool:IsA("Tool") then return end
        task.defer(function()
            task.wait(0.15)
            Scan()
            if controller and Silent.Config.InstaReload then
                Patch()
            end
        end)
        tool.Equipped:Connect(function()
            task.defer(function()
                task.wait(0.1)
                Scan()
                if controller and Silent.Config.InstaReload then Patch() end
            end)
        end)
    end

    for _, ch in ipairs(char:GetChildren()) do
        onTool(ch)
    end
    char.ChildAdded:Connect(onTool)

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            onTool(ch)
        end
        bp.ChildAdded:Connect(onTool)
    end
end

local function FindBulletHandler()
    local ok, mod = pcall(function()
        return require(ReplicatedStorage.ModuleScripts.GunModules.BulletHandler)
    end)
    if ok and mod and type(mod.Fire) == "function" then return mod end
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v.Name == "BulletHandler" and v:IsA("ModuleScript") then
            local s, m = pcall(require, v)
            if s and m and type(m.Fire) == "function" then return m end
        end
    end
    return nil
end

function Silent.Init()
    local BH = FindBulletHandler()
    if not BH then
        warn("[Silent] BulletHandler not found")
        return false
    end

    HookNew()

    if LocalPlayer.Character then
        WatchCharacter(LocalPlayer.Character)
        task.defer(Scan)
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        WatchCharacter(char)
        task.defer(function()
            task.wait(0.3)
            Scan()
        end)
    end)

    local oldFire = BH.Fire
    BH.Fire = function(data)
        if type(data) == "table" then
            if Silent.Config.InstaReload then
                if not controller or not IsGunController(controller) then
                    Scan()
                end
                if type(data.Misc) == "table" then
                    local max = data.Misc.MaxAmmo
                    if type(max) ~= "number" or max < 1 then max = 1 end
                    data.Misc.AmmoCount = max
                    data.Misc.ReloadTime = 0
                end
                Patch()
            end

            if Silent.Config.Enabled and math.random(1, 100) <= Silent.Config.HitChance then
                local target = GetClosest()
                if target then
                    local realOrigin = data.Origin or Camera.CFrame.Position
                    local d = target.Position - realOrigin
                    if d.Magnitude > 0.001 then
                        data.Direction = d.Unit
                    end
                    if data.Misc and type(data.Misc) == "table" then
                        pcall(function()
                            data.Misc.CamCFrame = CFrame.new(realOrigin, target.Position)
                        end)
                    end
                end
            end

            local result = oldFire(data)

            if Silent.Config.InstaReload then
                Patch()
                task.defer(Patch)
                task.delay(0.05, Patch)
                task.delay(0.15, Patch)
                task.delay(0.35, Patch)
            end
            return result
        end
        return oldFire(data)
    end

    RunService.RenderStepped:Connect(function()
        if Silent.Config.Enabled and Silent.Config.ShowFOV then
            FOVCircle.Position = UserInputService:GetMouseLocation()
            FOVCircle.Radius   = Silent.Config.FOV
            FOVCircle.Color    = Silent.Config.FOVColor
            FOVCircle.Visible  = true
        else
            FOVCircle.Visible = false
        end
    end)

    return true
end

return Silent
