--[[
    Flick · Silent + Insta Reload v6
    Safe keys only — do NOT zero FireRate / generic "rate"
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
local lastStrictScan = 0

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

local function IsStrictController(t)
    if type(t) ~= "table" then return false end
    local ok, res = pcall(function()
        return type(rawget(t, "Ammo")) == "number" and type(rawget(t, "reloadTime")) == "number"
    end)
    return ok and res
end

local function SetController(obj)
    if type(obj) ~= "table" then return end
    if controller == obj then return end
    controller = obj
    print("[Rage] controller set")
end

-- ONLY safe keys — never touch FireRate / generic rate
local function PatchController(obj)
    if type(obj) ~= "table" then return end
    pcall(function()
        local maxAmmo = 1
        local ma = rawget(obj, "MaxAmmo")
        if type(ma) == "number" and ma > 0 then maxAmmo = ma end

        if type(rawget(obj, "Ammo")) == "number" then rawset(obj, "Ammo", maxAmmo) end
        if type(rawget(obj, "reloadTime")) == "number" then rawset(obj, "reloadTime", 0) end
        if type(rawget(obj, "ReloadTime")) == "number" then rawset(obj, "ReloadTime", 0) end

        if type(rawget(obj, "Reloading")) == "boolean" then rawset(obj, "Reloading", false) end
        if type(rawget(obj, "reloading")) == "boolean" then rawset(obj, "reloading", false) end
        if type(rawget(obj, "CanReload")) == "boolean" then rawset(obj, "CanReload", true) end
        if type(rawget(obj, "CanFire")) == "boolean" then rawset(obj, "CanFire", true) end
        if type(rawget(obj, "canFire")) == "boolean" then rawset(obj, "canFire", true) end

        -- cooldown timestamps: set to past so checks pass
        local past = tick() - 10
        for _, k in ipairs({"NextShot", "nextShot", "NextFire", "nextFire", "LastShot", "lastShot"}) do
            if type(rawget(obj, k)) == "number" then rawset(obj, k, past) end
        end
        for _, k in ipairs({"Debounce", "debounce", "CoolingDown", "coolingDown"}) do
            if type(rawget(obj, k)) == "boolean" then rawset(obj, k, false) end
        end
        for _, k in ipairs({"Cooldown", "cooldown", "FireCooldown", "ShootCooldown"}) do
            if type(rawget(obj, k)) == "number" then rawset(obj, k, 0) end
        end
    end)
end

local function StrictScanOnce(force)
    local now = tick()
    if not force and now - lastStrictScan < 1.5 then return end
    lastStrictScan = now

    local found = nil
    local n = 0
    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if IsStrictController(obj) then
                n = n + 1
                found = obj
                if n >= 8 then break end
            end
        end
    end)
    if found then
        SetController(found)
    end
end

local function HookGunFrameworkNew()
    local ok, GF = pcall(function()
        return require(
            ReplicatedStorage
                :WaitForChild("ModuleScripts", 5)
                :WaitForChild("GunModules", 5)
                :WaitForChild("GunFramework", 5)
        )
    end)
    if not ok or type(GF) ~= "table" or type(GF.new) ~= "function" then
        return false
    end
    if hookedNew then return true end

    local oldNew = GF.new
    GF.new = function(...)
        local obj = oldNew(...)
        if type(obj) == "table" then
            SetController(obj)
            if Silent.Config.InstaReload then
                PatchController(obj)
            end
        end
        return obj
    end
    hookedNew = true
    print("[Rage] GunFramework.new hooked")
    return true
end

local function EnsureController()
    if controller and IsStrictController(controller) then
        return true
    end
    controller = nil
    StrictScanOnce(false)
    return controller ~= nil
end

local function ApplyInstaReload(data)
    if not Silent.Config.InstaReload then return end

    if type(data) == "table" and type(data.Misc) == "table" then
        local max = data.Misc.MaxAmmo
        if type(max) ~= "number" or max < 1 then max = 1 end
        data.Misc.AmmoCount = max
        data.Misc.ReloadTime = 0
    end

    EnsureController()
    if controller then
        PatchController(controller)
    end
end

local function OnRespawn()
    controller = nil
    lastStrictScan = 0
    task.spawn(function()
        HookGunFrameworkNew()
        for i = 1, 25 do
            task.wait(0.2)
            StrictScanOnce(true)
            if controller then
                PatchController(controller)
                print("[Rage] respawn ok")
                return
            end
        end
        print("[Rage] respawn miss — shoot to bind")
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
    task.defer(function()
        task.wait(0.4)
        StrictScanOnce(true)
    end)

    LocalPlayer.CharacterAdded:Connect(OnRespawn)

    local oldFire = BH.Fire
    BH.Fire = function(data)
        if type(data) == "table" then
            if Silent.Config.InstaReload then
                pcall(ApplyInstaReload, data)
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
            if Silent.Config.InstaReload and controller then
                PatchController(controller)
            end
            return result
        end
        return oldFire(data)
    end

    RunService.Heartbeat:Connect(function()
        if not Silent.Config.InstaReload then return end
        if controller and IsStrictController(controller) then
            PatchController(controller)
        elseif Silent.Config.InstaReload then
            EnsureController()
        end
    end)

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

    print("[Rage] ready v6")
    return true
end

return Silent
