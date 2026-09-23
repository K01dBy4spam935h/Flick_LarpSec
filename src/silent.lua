--[[
    Flick · Silent + Magic Bullet (penetrate-step)

    Architecture:
      BulletHandler.Fire(data)  data.Origin, data.Direction
      Server trusts Direction for aim; often validates Origin near shooter.
      Pure "origin at target" fails validation → FX only, no damage.

    Magic strategy:
      1. Ray from realOrigin → target
      2. For each world hit that is NOT the target character, step Origin
         just past that surface and continue
      3. Final Origin is the furthest-forward free point still on the line
         (as close to the player as possible while clear of walls)
      4. Direction remains unit vector into the target
      This keeps Origin within a more plausible distance of the shooter
      than "spawn on their chest" while still clearing geometry.
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
    MagicBullet  = false,
    MagicSteps   = 10,   -- max wall steps
    MagicPad     = 0.2,  -- studs past each surface
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = Silent.Config.FOVThickness
FOVCircle.NumSides  = 64
FOVCircle.Filled    = false
FOVCircle.Color     = Silent.Config.FOVColor
FOVCircle.Visible   = false
FOVCircle.ZIndex    = 2

local stickyTarget = nil

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

-- step Origin forward past non-target geometry; stop when LOS is clear to target
local function MagicOrigin(realOrigin, targetPart)
    local targetPos = targetPart.Position
    local targetChar = targetPart.Parent
    local toTarget = targetPos - realOrigin
    local total = toTarget.Magnitude
    if total < 0.5 then
        return realOrigin, (total > 0 and toTarget.Unit or Camera.CFrame.LookVector)
    end
    local dir = toTarget.Unit
    local origin = realOrigin
    local pad = Silent.Config.MagicPad or 0.2
    local maxSteps = Silent.Config.MagicSteps or 10

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character}

    for _ = 1, maxSteps do
        local remaining = (targetPos - origin).Magnitude
        if remaining < 0.25 then
            break
        end
        local hit = workspace:Raycast(origin, dir * remaining, params)
        if not hit then
            -- clear path from this origin
            return origin, dir
        end
        if hit.Instance:IsDescendantOf(targetChar) then
            -- next hit is the target itself — origin is good
            return origin, dir
        end
        -- world geometry: step just past the surface
        origin = hit.Position + dir * pad
        -- safety: never go past the target
        if (origin - realOrigin):Dot(dir) > total then
            origin = targetPos - dir * 0.75
            break
        end
    end

    -- fallback: short standoff from target (last resort)
    return targetPos - dir * 0.75, dir
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
        if Silent.Config.Enabled and type(data) == "table" then
            if math.random(1, 100) <= Silent.Config.HitChance then
                local target = GetClosest()
                if target then
                    local realOrigin = data.Origin or Camera.CFrame.Position
                    if Silent.Config.MagicBullet then
                        local origin, dir = MagicOrigin(realOrigin, target)
                        data.Origin = origin
                        data.Direction = dir
                    else
                        local aimPos = target.Position
                        local d = aimPos - realOrigin
                        if d.Magnitude > 0.001 then
                            data.Direction = d.Unit
                        end
                    end
                end
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
