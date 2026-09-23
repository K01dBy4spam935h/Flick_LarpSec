--[[
    Flick · Silent + Insta Reload
    GunFramework.new → controller with Ammo / CanReload / reloadTime
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
local controllers = {} -- gun objects from GunFramework.new
local hookedNew = false

local function GetChar(plr) return plr and plr.Character end
local function GetHum(c) return c and c:FindFirstChildOfClass("Humanoid") end
local function GetRoot(c)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso"))
end
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

local function IsController(t)
    if type(t) ~= "table" then return false end
    local ok, res = pcall(function()
        -- signature from GunFramework.new constants
        local hasAmmo = rawget(t, "Ammo") ~= nil or rawget(t, "ammo") ~= nil
        local hasReload = rawget(t, "reloadTime") ~= nil or rawget(t, "ReloadTime") ~= nil
            or rawget(t, "CanReload") ~= nil or rawget(t, "Reloading") ~= nil
        return hasAmmo and hasReload
    end)
    return ok and res
end

local function TrackController(obj)
    if not IsController(obj) then return false end
    for _, c in ipairs(controllers) do
        if c == obj then return true end
    end
    table.insert(controllers, obj)
    local keys = {}
    pcall(function()
        for k, v in pairs(obj) do
            table.insert(keys, tostring(k) .. "=" .. typeof(v))
        end
    end)
    table.sort(keys)
    print("[Rage] controller tracked keys: " .. table.concat(keys, ", "))
    return true
end

local function PatchController(obj)
    local n = 0
    pcall(function()
        local maxAmmo = 1
        for _, key in ipairs({"MaxAmmo", "maxAmmo", "MagSize", "magSize"}) do
            local v = rawget(obj, key)
            if type(v) == "number" and v > 0 then maxAmmo = v break end
        end

        local function set(k, v)
            if rawget(obj, k) ~= nil then
                rawset(obj, k, v)
                n = n + 1
                print("[Rage] " .. tostring(k) .. " → " .. tostring(v))
            end
        end

        set("Ammo", maxAmmo)
        set("ammo", maxAmmo)
        set("AmmoCount", maxAmmo)
        set("Magazine", maxAmmo)
        set("reloadTime", 0)
        set("ReloadTime", 0)
        set("Reloading", false)
        set("reloading", false)
        set("[Reloading]", false)
        set("CanReload", true)
        set("CanFire", true)
        set("canFire", true)

        -- nested
        for k, v in pairs(obj) do
            if type(v) == "table" then
                local sub = v
                if rawget(sub, "Ammo") ~= nil or rawget(sub, "reloadTime") ~= nil then
                    n = n + PatchController(sub)
                end
            end
        end
    end)
    return n
end

local function PatchAllControllers()
    local total = 0
    for _, c in ipairs(controllers) do
        total = total + PatchController(c)
    end
    return total
end

local function ScanExistingControllers()
    local found = 0
    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and IsController(obj) then
                if TrackController(obj) then found = found + 1 end
            end
        end
    end)
    print("[Rage] gc controllers: " .. tostring(found) .. " total tracked: " .. tostring(#controllers))
end

local function HookGunFrameworkNew()
    if hookedNew then return end
    local ok, GF = pcall(function()
        return require(
            ReplicatedStorage
                :WaitForChild("ModuleScripts", 5)
                :WaitForChild("GunModules", 5)
                :WaitForChild("GunFramework", 5)
        )
    end)
    if not ok or type(GF) ~= "table" or type(GF.new) ~= "function" then
        warn("[Rage] GunFramework.new not found")
        return
    end

    local oldNew = GF.new
    GF.new = function(...)
        local obj = oldNew(...)
        pcall(function()
            if type(obj) == "table" then
                TrackController(obj)
                if Silent.Config.InstaReload then
                    PatchController(obj)
                end
            end
        end)
        return obj
    end
    hookedNew = true
    print("[Rage] GunFramework.new hooked")
end

local function ApplyInstaReload(data)
    if not Silent.Config.InstaReload then return end

    print("[Rage] InstaReload fire tick")

    if type(data) == "table" and type(data.Misc) == "table" then
        local max = data.Misc.MaxAmmo
        if type(max) ~= "number" or max < 1 then max = 1 end
        data.Misc.AmmoCount = max
        data.Misc.ReloadTime = 0
    end

    if #controllers == 0 then
        ScanExistingControllers()
    end

    local n = PatchAllControllers()
    print("[Rage] controllers=" .. tostring(#controllers) .. " patches=" .. tostring(n))

    task.defer(function()
        if Silent.Config.InstaReload then PatchAllControllers() end
    end)
    task.delay(0.05, function()
        if Silent.Config.InstaReload then PatchAllControllers() end
    end)
    task.delay(0.2, function()
        if Silent.Config.InstaReload then PatchAllControllers() end
    end)
    task.delay(0.5, function()
        if Silent.Config.InstaReload then PatchAllControllers() end
    end)
end

local function FindBulletHandler()
    local ok, mod = pcall(function()
        return require(
            ReplicatedStorage
                :WaitForChild("ModuleScripts", 6)
                :WaitForChild("GunModules", 6)
                :WaitForChild("BulletHandler", 6)
        )
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

    HookGunFrameworkNew()
    task.spawn(function()
        task.wait(1)
        ScanExistingControllers()
        HookGunFrameworkNew()
    end)

    local oldFire = BH.Fire
    BH.Fire = function(data)
        if type(data) == "table" then
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
            local ok, err = pcall(ApplyInstaReload, data)
            if not ok then
                warn("[Rage] error: " .. tostring(err))
            end
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
