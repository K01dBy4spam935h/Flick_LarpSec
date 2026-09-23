--[[
    Flick · Silent + Insta Reload
    GunFramework = { new } only — live state is on controller objects (getgc)
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
local gunControllers = {} -- weak-ish list of tables that look like gun state

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

local function LooksLikeGunState(t)
    if type(t) ~= "table" then return false end
    local hasAmmo, hasReload, hasShot = false, false, false
    local ok, _ = pcall(function()
        for k, v in pairs(t) do
            local lk = string.lower(tostring(k))
            if type(v) == "number" or type(v) == "boolean" then
                if lk:find("ammo") or lk:find("mag") or lk:find("clip") then hasAmmo = true end
                if lk:find("reload") then hasReload = true end
                if lk:find("shot") or lk:find("cooldown") or lk:find("debounce") then hasShot = true end
            end
        end
    end)
    return ok and ((hasAmmo and hasReload) or (hasAmmo and hasShot) or hasReload)
end

local function ScanGunControllers()
    gunControllers = {}
    local ok, err = pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" and LooksLikeGunState(obj) then
                table.insert(gunControllers, obj)
            end
        end
    end)
    if not ok then
        warn("[Rage] getgc scan failed: " .. tostring(err))
        return 0
    end
    print("[Rage] gun-state tables found: " .. tostring(#gunControllers))
    -- dump first match keys once
    if gunControllers[1] then
        local keys = {}
        pcall(function()
            for k, v in pairs(gunControllers[1]) do
                table.insert(keys, tostring(k) .. "=" .. typeof(v))
            end
        end)
        table.sort(keys)
        print("[Rage] sample state keys: " .. table.concat(keys, ", "))
    end
    return #gunControllers
end

local function PatchGunControllers()
    local n = 0
    for _, t in ipairs(gunControllers) do
        pcall(function()
            for k, v in pairs(t) do
                local lk = string.lower(tostring(k))
                if type(v) == "number" then
                    if lk:find("reload") or lk:find("cooldown") or lk:find("nextfire")
                        or lk:find("nextshot") or lk:find("debounc") or lk:find("delay") then
                        rawset(t, k, 0)
                        n = n + 1
                    end
                    if (lk:find("ammo") or lk:find("mag") or lk:find("clip") or lk:find("chamber")) and v <= 0 then
                        local maxK = nil
                        for k2, v2 in pairs(t) do
                            local lk2 = string.lower(tostring(k2))
                            if type(v2) == "number" and (lk2:find("max") or lk2:find("capacity")) then
                                maxK = v2
                                break
                            end
                        end
                        rawset(t, k, maxK or 1)
                        n = n + 1
                    end
                elseif type(v) == "boolean" then
                    if lk:find("reload") or lk:find("reloading") then
                        rawset(t, k, false)
                        n = n + 1
                    end
                end
            end
        end)
    end
    return n
end

local function RefillInstances()
    local n = 0
    local roots = {}
    if LocalPlayer.Character then table.insert(roots, LocalPlayer.Character) end
    if LocalPlayer:FindFirstChild("Backpack") then table.insert(roots, LocalPlayer.Backpack) end

    for _, root in ipairs(roots) do
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("IntValue") or inst:IsA("NumberValue") then
                local ln = string.lower(inst.Name)
                if ln:find("ammo") or ln:find("mag") or ln:find("clip") or ln:find("round") then
                    if inst.Value == 0 then
                        inst.Value = 1
                        n = n + 1
                        print("[Rage] inst " .. inst:GetFullName() .. " →1")
                    end
                end
                if ln:find("reload") then
                    inst.Value = 0
                    n = n + 1
                    print("[Rage] inst " .. inst:GetFullName() .. " →0")
                end
            end
        end
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
        print("[Rage] Misc AmmoCount=" .. tostring(max) .. " ReloadTime=0")
    else
        warn("[Rage] no data.Misc")
    end

    if #gunControllers == 0 then
        ScanGunControllers()
    end
    local pc = PatchGunControllers()
    print("[Rage] controller fields patched: " .. tostring(pc))

    local ni = RefillInstances()
    print("[Rage] instances touched: " .. tostring(ni))

    task.defer(function()
        if Silent.Config.InstaReload then
            PatchGunControllers()
            RefillInstances()
        end
    end)
    task.delay(0.1, function()
        if Silent.Config.InstaReload then
            PatchGunControllers()
            RefillInstances()
        end
    end)
    task.delay(0.5, function()
        if Silent.Config.InstaReload then
            PatchGunControllers()
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
                warn("[Rage] ApplyInstaReload error: " .. tostring(err))
            end
        end
        return oldFire(data)
    end

    task.spawn(function()
        task.wait(2)
        if Silent.Config.InstaReload or true then
            ScanGunControllers()
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

    return true
end

return Silent
