--[[
    Flick · Silent Aim + Insta Reload
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

-- scan character / backpack / tool for ammo-like values and refill
local function RefillAmmoValues()
    local filled = 0
    local roots = {}
    local char = LocalPlayer.Character
    if char then table.insert(roots, char) end
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then table.insert(roots, bp) end

    local nameHints = {
        "ammo", "mag", "clip", "round", "bullet", "shell", "chamber", "reserve"
    }

    for _, root in ipairs(roots) do
        for _, inst in ipairs(root:GetDescendants()) do
            if inst:IsA("IntValue") or inst:IsA("NumberValue") then
                local ln = string.lower(inst.Name)
                for _, h in ipairs(nameHints) do
                    if ln:find(h, 1, true) then
                        local maxV = nil
                        local parent = inst.Parent
                        if parent then
                            for _, sib in ipairs(parent:GetChildren()) do
                                if sib ~= inst and (sib:IsA("IntValue") or sib:IsA("NumberValue")) then
                                    local sn = string.lower(sib.Name)
                                    if sn:find("max") or sn:find("capacity") or sn:find("size") then
                                        maxV = sib.Value
                                        break
                                    end
                                end
                            end
                        end
                        local target = maxV or (inst.Value < 1 and 1 or inst.Value)
                        if maxV then target = maxV end
                        if type(target) == "number" and target >= 0 then
                            if maxV and inst.Value ~= maxV then
                                inst.Value = maxV
                                filled = filled + 1
                            elseif not maxV and inst.Value == 0 then
                                inst.Value = 1
                                filled = filled + 1
                            end
                        end
                        break
                    end
                end
            end
        end
    end
    return filled
end

local function ApplyInstaReload(data)
    if not Silent.Config.InstaReload then return end

    local okMisc = false
    if type(data) == "table" and type(data.Misc) == "table" then
        local max = data.Misc.MaxAmmo
        if type(max) ~= "number" or max < 1 then max = 1 end
        data.Misc.AmmoCount = max
        data.Misc.ReloadTime = 0
        okMisc = true
    else
        warn("[Rage] InstaReload: data.Misc missing on Fire")
    end

    local n = 0
    local ok, err = pcall(function()
        n = RefillAmmoValues()
    end)
    if not ok then
        warn("[Rage] InstaReload refill error: " .. tostring(err))
    end

    -- defer second pass (some guns update ammo after Fire returns)
    task.defer(function()
        if not Silent.Config.InstaReload then return end
        local ok2, err2 = pcall(RefillAmmoValues)
        if not ok2 then
            warn("[Rage] InstaReload deferred error: " .. tostring(err2))
        end
    end)

    if okMisc or n > 0 then
        -- silent success; only warn on total failure
    else
        warn("[Rage] InstaReload: no Misc patch and no ammo values found")
    end
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
