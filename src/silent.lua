--[[
    Flick · Silent + Insta Reload / Rapid
    Controllers from GunFramework.new (Ammo, reloadTime, CanReload)
    Heartbeat keep-alive · respawn rescan
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
local controllers = {}
local hookedNew = false
local lastScan = 0

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
    print("[Rage] controller +" .. tostring(#controllers))
    return true
end

local function PatchController(obj)
    local n = 0
    pcall(function()
        local maxAmmo = 1
        for _, key in ipairs({"MaxAmmo", "maxAmmo", "MagSize", "magSize"}) do
            local v = rawget(obj, key)
            if type(v) == "number" and v > 0 then
                maxAmmo = v
                break
            end
        end

        local function set(k, v)
            local cur = rawget(obj, k)
            if cur ~= nil and cur ~= v then
                rawset(obj, k, v)
                n = n + 1
            elseif cur ~= nil and cur == v then
                -- already set
            elseif cur == nil then
                -- try set anyway for known keys
            end
            if cur ~= nil then
                rawset(obj, k, v)
            end
        end

        -- force write known keys if present
        local writes = {
            Ammo = maxAmmo,
            ammo = maxAmmo,
            AmmoCount = maxAmmo,
            Magazine = maxAmmo,
            reloadTime = 0,
            ReloadTime = 0,
            Reloading = false,
            reloading = false,
            CanReload = true,
            CanFire = true,
            canFire = true,
            Debounce = false,
            debounce = false,
            Cooldown = 0,
            cooldown = 0,
            NextShot = 0,
            nextShot = 0,
            NextFire = 0,
            nextFire = 0,
            LastFire = 0,
            lastFire = 0,
            FireDelay = 0,
            fireDelay = 0,
            ShootDelay = 0,
        }
        for k, v in pairs(writes) do
            if rawget(obj, k) ~= nil then
                rawset(obj, k, v)
                n = n + 1
            end
        end

        -- any numeric key that looks like a timer / delay
        for k, v in pairs(obj) do
            local lk = string.lower(tostring(k))
            if type(v) == "number" then
                if lk:find("delay") or lk:find("cool") or lk:find("next")
                    or lk:find("lastfire") or lk:find("lastshot") or lk:find("wait") then
                    if v ~= 0 then
                        rawset(obj, k, 0)
                        n = n + 1
                    end
                end
                if (lk:find("ammo") or lk == "mag" or lk:find("clip")) and not lk:find("max") and not lk:find("size") then
                    if v ~= maxAmmo then
                        rawset(obj, k, maxAmmo)
                        n = n + 1
                    end
                end
            elseif type(v) == "boolean" then
                if lk:find("reloading") and v == true then
                    rawset(obj, k, false)
                    n = n + 1
                end
            end
        end
    end)
    return n
end

local function PatchAll()
    local total = 0
    -- drop dead refs
    local live = {}
    for _, c in ipairs(controllers) do
        if type(c) == "table" then
            table.insert(live, c)
            total = total + PatchController(c)
        end
    end
    controllers = live
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
    if found > 0 then
        print("[Rage] scan found " .. tostring(found) .. " total " .. tostring(#controllers))
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

    -- always re-wrap (respawn may get new module env in rare cases; usually same)
    if not hookedNew then
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
    return true
end

local function OnRespawn()
    -- clear stale controllers from old character
    controllers = {}
    hookedNew = false
    task.defer(function()
        HookGunFrameworkNew()
        task.wait(0.3)
        ScanExistingControllers()
        task.wait(0.5)
        ScanExistingControllers()
        if Silent.Config.InstaReload then
            PatchAll()
        end
        print("[Rage] respawn rebind controllers=" .. tostring(#controllers))
    end)
end

local function ApplyInstaReload(data)
    if not Silent.Config.InstaReload then return end

    if type(data) == "table" and type(data.Misc) == "table" then
        local max = data.Misc.MaxAmmo
        if type(max) ~= "number" or max < 1 then max = 1 end
        data.Misc.AmmoCount = max
        data.Misc.ReloadTime = 0
    end

    if #controllers == 0 then
        ScanExistingControllers()
    end
    PatchAll()
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
    ScanExistingControllers()

    -- respawn
    LocalPlayer.CharacterAdded:Connect(function()
        OnRespawn()
    end)
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Died:Connect(function()
                -- prepare for next character
            end)
        end
    end

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
            pcall(ApplyInstaReload, data)
        end
        return oldFire(data)
    end

    -- continuous rapid: keep ammo full and timers at 0 every frame while enabled
    RunService.Heartbeat:Connect(function()
        if not Silent.Config.InstaReload then return end
        if #controllers == 0 then
            local now = tick()
            if now - lastScan > 1 then
                lastScan = now
                ScanExistingControllers()
                HookGunFrameworkNew()
            end
            return
        end
        PatchAll()
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

    print("[Rage] ready · heartbeat rapid · respawn rebind")
    return true
end

return Silent
