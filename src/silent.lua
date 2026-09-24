--[[
    Flick · Silent + Insta Reload (optimized)
    Only track objects returned by GunFramework.new — never bulk getgc
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
local controllers = {} -- only from GF.new
local MAX_CONTROLLERS = 4
local hookedNew = false
local patchAccumulator = 0

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

local function TrackController(obj)
    if type(obj) ~= "table" then return end
    for _, c in ipairs(controllers) do
        if c == obj then return end
    end
    table.insert(controllers, obj)
    -- keep only newest
    while #controllers > MAX_CONTROLLERS do
        table.remove(controllers, 1)
    end
    print("[Rage] controller tracked (" .. tostring(#controllers) .. ")")
end

local function PatchController(obj)
    pcall(function()
        local maxAmmo = 1
        local ma = rawget(obj, "MaxAmmo") or rawget(obj, "maxAmmo") or rawget(obj, "MagSize")
        if type(ma) == "number" and ma > 0 then maxAmmo = ma end

        local function force(k, v)
            if rawget(obj, k) ~= nil then
                rawset(obj, k, v)
            end
        end

        force("Ammo", maxAmmo)
        force("ammo", maxAmmo)
        force("AmmoCount", maxAmmo)
        force("reloadTime", 0)
        force("ReloadTime", 0)
        force("Reloading", false)
        force("reloading", false)
        force("CanReload", true)
        force("CanFire", true)
        force("canFire", true)
        force("Debounce", false)
        force("Cooldown", 0)
        force("NextShot", 0)
        force("nextShot", 0)
        force("NextFire", 0)
        force("LastFire", 0)
        force("lastFire", 0)
        force("FireDelay", 0)
        force("fireDelay", 0)
    end)
end

local function PatchAll()
    for i = #controllers, 1, -1 do
        local c = controllers[i]
        if type(c) ~= "table" then
            table.remove(controllers, i)
        else
            PatchController(c)
        end
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
            TrackController(obj)
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

local function OnRespawn()
    controllers = {}
    -- keep hookedNew true — same GF.new wrapper still works for next character
    task.defer(function()
        HookGunFrameworkNew()
        -- wait for gun to construct
        for _ = 1, 10 do
            task.wait(0.25)
            if #controllers > 0 then break end
        end
        if Silent.Config.InstaReload then
            PatchAll()
        end
        print("[Rage] respawn controllers=" .. tostring(#controllers))
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

    LocalPlayer.CharacterAdded:Connect(OnRespawn)

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

    -- light heartbeat: only patch known controllers (0–4), no getgc
    RunService.Heartbeat:Connect(function()
        if not Silent.Config.InstaReload then return end
        if #controllers == 0 then return end
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

    print("[Rage] ready (no gc scan)")
    return true
end

return Silent
