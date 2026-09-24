--[[
    Flick · Silent + NoReload
    NoReload: zero reloadTime on the live gun-shaped config table (not GF.new shell)
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
    NoReload     = false,
    Triggerbot   = false,
    AutoShoot    = false,
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = Silent.Config.FOVThickness
FOVCircle.NumSides  = 64
FOVCircle.Filled    = false
FOVCircle.Color     = Silent.Config.FOVColor
FOVCircle.Visible   = false
FOVCircle.ZIndex    = 2

local stickyTarget = nil
local reloadTable = nil -- FRESH gun-shaped table (Ammo + reloadTime), NOT GF.new return
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

local function IsReloadTable(t)
    if type(t) ~= "table" then return false end
    local ok, res = pcall(function()
        return type(rawget(t, "Ammo")) == "number" and type(rawget(t, "reloadTime")) == "number"
    end)
    return ok and res
end

local function FindReloadTable()
    local now = tick()
    if now - lastScan < 0.35 and reloadTable and IsReloadTable(reloadTable) then
        return reloadTable
    end
    lastScan = now

    local found = nil
    pcall(function()
        for _, obj in ipairs(getgc(true)) do
            if IsReloadTable(obj) then
                found = obj -- last match; usually the live one
            end
        end
    end)
    if found then
        reloadTable = found
    end
    return reloadTable
end

local function ApplyNoReload()
    if not Silent.Config.NoReload then return end
    local t = reloadTable
    if not t or not IsReloadTable(t) then
        t = FindReloadTable()
    end
    if not t then return end
    pcall(function()
        rawset(t, "reloadTime", 0)
        if type(rawget(t, "ReloadTime")) == "number" then
            rawset(t, "ReloadTime", 0)
        end
        local maxAmmo = rawget(t, "MaxAmmo")
        if type(maxAmmo) ~= "number" or maxAmmo < 1 then maxAmmo = 1 end
        if type(rawget(t, "Ammo")) == "number" then
            rawset(t, "Ammo", maxAmmo)
        end
    end)
end

local function OnTool(tool)
    if not tool or not tool:IsA("Tool") then return end
    task.defer(function()
        task.wait(0.12)
        reloadTable = nil
        lastScan = 0
        FindReloadTable()
        ApplyNoReload()
    end)
end

local function WatchCharacter(char)
    if not char then return end
    reloadTable = nil
    lastScan = 0

    for _, ch in ipairs(char:GetChildren()) do
        OnTool(ch)
    end
    char.ChildAdded:Connect(OnTool)

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            OnTool(ch)
        end
        bp.ChildAdded:Connect(OnTool)
    end

    -- auto-equip gun on spawn: a few delayed finds
    task.spawn(function()
        for _ = 1, 12 do
            task.wait(0.25)
            if FindReloadTable() then
                ApplyNoReload()
                break
            end
        end
    end)
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


local function SimulateClick()
    pcall(function()
        if mouse1press and mouse1release then
            mouse1press()
            task.delay(0.02, mouse1release)
            return
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.delay(0.02, function()
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end)
    end)
end

local function TargetOnCrosshair()
    local mouse = UserInputService:GetMouseLocation()
    local best, bestDist = nil, 6 -- px radius for trigger
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not Alive(plr) then continue end
        local char = GetChar(plr)
        for _, part in ipairs(CandidateParts(char)) do
            if Silent.Config.VisibleCheck and not Visible(part) then continue end
            local sp, on = Camera:WorldToViewportPoint(part.Position)
            if not on then continue end
            local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
            if d < bestDist then
                bestDist = d
                best = part
            end
        end
    end
    return best
end

local function TargetInFOVVisible()
    if not Silent.Config.Enabled and not Silent.Config.AutoShoot then
        -- still allow FOV scan for autoshoot
    end
    local best = GetClosest()
    if not best then return nil end
    if Silent.Config.VisibleCheck or true then
        -- autoshoot requires visible
        if not Visible(best) then return nil end
    end
    return best
end

function Silent.Init()
    local BH = FindBulletHandler()
    if not BH then
        warn("[Silent] BulletHandler not found")
        return false
    end

    if LocalPlayer.Character then
        WatchCharacter(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(WatchCharacter)

    local oldFire = BH.Fire
    BH.Fire = function(data)
        if type(data) == "table" then
            if Silent.Config.NoReload then
                ApplyNoReload()
                if type(data.Misc) == "table" then
                    data.Misc.ReloadTime = 0
                    local max = data.Misc.MaxAmmo
                    if type(max) == "number" and max >= 1 then
                        data.Misc.AmmoCount = max
                    end
                end
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

            if Silent.Config.NoReload then
                ApplyNoReload()
                task.defer(ApplyNoReload)
                task.delay(0.05, ApplyNoReload)
                task.delay(0.2, ApplyNoReload)
            end
            return result
        end
        return oldFire(data)
    end

    -- keep reloadTime collapsed while enabled (cheap: one table)
    RunService.Heartbeat:Connect(function()
        if Silent.Config.NoReload then
            ApplyNoReload()
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


    local lastTrig = 0
    local lastAuto = 0
    RunService.RenderStepped:Connect(function()
        if Silent.Config.Triggerbot then
            local t = TargetOnCrosshair()
            if t and (tick() - lastTrig) > 0.03 then
                lastTrig = tick()
                SimulateClick()
            end
        end
        if Silent.Config.AutoShoot then
            local t = GetClosest()
            if t and Visible(t) and (tick() - lastAuto) > 0.05 then
                lastAuto = tick()
                SimulateClick()
            end
        end
    end)

    return true
end

return Silent
