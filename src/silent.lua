--[[
    Flick · Silent + Insta Reload
    Live gun state is not on GunFramework module — hunt upvalues / exact keys
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
local stateTables = {} -- real gun controllers
local scannedOnce = false

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

local function IsOurTable(t)
    return t == Silent or t == Silent.Config
end

-- exact key match from Fire.Misc shape + common controller names
local function IsGunState(t)
    if type(t) ~= "table" or IsOurTable(t) then return false end
    local ok, result = pcall(function()
        local has = function(k)
            return rawget(t, k) ~= nil
        end
        -- strong signals from probe
        if has("AmmoCount") or has("MaxAmmo") or has("ReloadTime") then return true end
        if has("ammo") or has("Ammo") or has("Magazine") or has("Mag") then return true end
        if has("Reloading") or has("reloading") or has("IsReloading") then return true end
        if has("NextShot") or has("nextShot") or has("CanFire") or has("canFire") then return true end
        return false
    end)
    return ok and result
end

local function CollectStateTables()
    stateTables = {}
    local seen = {}
    local function add(t)
        if type(t) ~= "table" or seen[t] or IsOurTable(t) then return end
        if IsGunState(t) then
            seen[t] = true
            table.insert(stateTables, t)
        end
    end

    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" then
                add(obj)
            elseif type(obj) == "function" then
                local i = 1
                while true do
                    local name, val = debug.getupvalue(obj, i)
                    if not name then break end
                    if type(val) == "table" then
                        add(val)
                    end
                    i = i + 1
                    if i > 40 then break end
                end
            end
        end
    end)

    print("[Rage] gun-state tables: " .. tostring(#stateTables))
    if stateTables[1] and not scannedOnce then
        scannedOnce = true
        local keys = {}
        pcall(function()
            for k, v in pairs(stateTables[1]) do
                table.insert(keys, tostring(k) .. "=" .. typeof(v) .. ":" .. tostring(v))
            end
        end)
        table.sort(keys)
        print("[Rage] sample: " .. table.concat(keys, " | "))
    end
    return #stateTables
end

local function PatchStateTables()
    local n = 0
    for _, t in ipairs(stateTables) do
        pcall(function()
            local function set(k, v)
                if rawget(t, k) ~= nil then
                    rawset(t, k, v)
                    n = n + 1
                    print("[Rage] set " .. tostring(k) .. "=" .. tostring(v))
                end
            end

            -- numbers
            local maxAmmo = rawget(t, "MaxAmmo") or rawget(t, "maxAmmo") or rawget(t, "MagSize") or 1
            if type(maxAmmo) ~= "number" then maxAmmo = 1 end

            for _, k in ipairs({"AmmoCount", "ammo", "Ammo", "Magazine", "Mag", "Clip", "Rounds", "Chamber"}) do
                local v = rawget(t, k)
                if type(v) == "number" then
                    rawset(t, k, maxAmmo)
                    n = n + 1
                    print("[Rage] set " .. k .. "=" .. tostring(maxAmmo))
                end
            end

            for _, k in ipairs({"ReloadTime", "reloadTime", "ReloadDelay", "Cooldown", "FireCooldown", "NextShot", "nextShot", "Debounce"}) do
                local v = rawget(t, k)
                if type(v) == "number" then
                    rawset(t, k, 0)
                    n = n + 1
                    print("[Rage] set " .. k .. "=0")
                end
            end

            for _, k in ipairs({"Reloading", "reloading", "IsReloading", "isReloading"}) do
                local v = rawget(t, k)
                if type(v) == "boolean" then
                    rawset(t, k, false)
                    n = n + 1
                    print("[Rage] set " .. k .. "=false")
                end
            end

            for _, k in ipairs({"CanFire", "canFire", "Ready", "ready"}) do
                local v = rawget(t, k)
                if type(v) == "boolean" then
                    rawset(t, k, true)
                    n = n + 1
                    print("[Rage] set " .. k .. "=true")
                end
            end
        end)
    end
    return n
end

local function ApplyInstaReload(data)
    if not Silent.Config.InstaReload then return end

    print("[Rage] InstaReload fire tick")

    if type(data) == "table" and type(data.Misc) == "table" then
        local max = data.Misc.MaxAmmo
        if type(max) ~= "number" or max < 1 then max = 1 end
        data.Misc.AmmoCount = max
        data.Misc.ReloadTime = 0
        print("[Rage] Misc ok")
    end

    if #stateTables == 0 then
        CollectStateTables()
    end
    local p = PatchStateTables()
    print("[Rage] patches: " .. tostring(p))

    task.defer(function()
        if Silent.Config.InstaReload then PatchStateTables() end
    end)
    task.delay(0.15, function()
        if Silent.Config.InstaReload then
            CollectStateTables()
            PatchStateTables()
        end
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

    task.spawn(function()
        task.wait(2)
        CollectStateTables()
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

    return true
end

return Silent
