--[[
    Flick · Silent Aim + Magic Bullet (hit-report path)

    Mapped:
      BulletHandler.Fire(data) → client FX + server cast
      Server re-validates Origin near shooter → pure Origin teleport = FX only

    Magic (working approach on games with client hit reports):
      1. Keep Origin real (passes distance checks)
      2. Silent still aims Direction at torso
      3. Hook FireServer / namecall: if payload looks like a hit report
         (Position, Instance, Part, Hit), rewrite to target part
      4. Also patch data.Misc.CamCFrame when present (some Flick builds)

    If Flick is fully server-raycast with no client hit remote, wallbang
    cannot register damage from the client alone — toggle will still aim.
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
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = Silent.Config.FOVThickness
FOVCircle.NumSides  = 64
FOVCircle.Filled    = false
FOVCircle.Color     = Silent.Config.FOVColor
FOVCircle.Visible   = false
FOVCircle.ZIndex    = 2

local stickyTarget = nil
local lastTarget = nil -- BasePart

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
                    lastTarget = stickyTarget
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
    lastTarget = best
    return best
end

local function SpoofHitTable(t, part)
    if type(t) ~= "table" or not part then return end
    if t.Position ~= nil then t.Position = part.Position end
    if t.Instance ~= nil then t.Instance = part end
    if t.Part ~= nil then t.Part = part end
    if t.Hit ~= nil and typeof(t.Hit) == "Instance" then t.Hit = part end
    if t.Normal ~= nil then t.Normal = Vector3.new(0, 1, 0) end
    if t.Distance ~= nil and type(t.Distance) == "number" then
        local o = Camera.CFrame.Position
        t.Distance = (part.Position - o).Magnitude
    end
    for _, v in pairs(t) do
        if type(v) == "table" then
            SpoofHitTable(v, part)
        end
    end
end

local function InstallHitHooks()
    -- namecall: catch FireServer hit reports
    local ok, err = pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            if Silent.Config.MagicBullet and lastTarget and method == "FireServer" then
                local name = tostring(self)
                local lower = string.lower(name)
                if lower:find("hit") or lower:find("damage") or lower:find("bullet") or lower:find("shot") or lower:find("gun") then
                    for i, a in ipairs(args) do
                        if typeof(a) == "Instance" and a:IsA("BasePart") then
                            args[i] = lastTarget
                        elseif typeof(a) == "Vector3" then
                            args[i] = lastTarget.Position
                        elseif type(a) == "table" then
                            SpoofHitTable(a, lastTarget)
                        end
                    end
                    return old(self, unpack(args))
                end
                -- also spoof generic tables that look like ray results
                for _, a in ipairs(args) do
                    if type(a) == "table" and (a.Position or a.Instance or a.Part) then
                        SpoofHitTable(a, lastTarget)
                    end
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
    if not ok then
        warn("[Silent] namecall hook failed:", err)
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
        if Silent.Config.Enabled and type(data) == "table" then
            if math.random(1, 100) <= Silent.Config.HitChance then
                local target = GetClosest()
                if target then
                    local realOrigin = data.Origin or Camera.CFrame.Position
                    local d = target.Position - realOrigin
                    if d.Magnitude > 0.001 then
                        data.Direction = d.Unit
                    end
                    -- do NOT move Origin (server rejects) — keep real origin
                    if data.Misc and type(data.Misc) == "table" then
                        pcall(function()
                            data.Misc.CamCFrame = CFrame.new(realOrigin, target.Position)
                        end)
                    end
                end
            end
        end
        return oldFire(data)
    end

    InstallHitHooks()

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
