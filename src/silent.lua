--[[
    Flick · Silent + Insta Reload
    No AmmoCount tables in gc — try reload function skip via constants
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
local reloadHooksDone = false

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

local function FunctionHasReloadConst(fn)
    local ok, consts = pcall(debug.getconstants, fn)
    if not ok or type(consts) ~= "table" then return false, {} end
    local hits = {}
    for _, c in ipairs(consts) do
        if type(c) == "string" then
            local l = string.lower(c)
            if l:find("reload", 1, true) or l == "ammo" or l:find("magempty") or l:find("outofammo") then
                table.insert(hits, c)
            end
        end
    end
    return #hits > 0, hits
end

local function HookReloadFunctions()
    if reloadHooksDone then return end
    local hooked = 0
    local listed = 0

    local ok, err = pcall(function()
        for _, obj in ipairs(getgc()) do
            if type(obj) == "function" then
                local has, hits = FunctionHasReloadConst(obj)
                if has then
                    listed = listed + 1
                    local info = ""
                    pcall(function()
                        info = tostring(debug.info(obj, "n")) .. " @ " .. tostring(debug.info(obj, "s"))
                    end)
                    print("[Rage] reload-const fn: " .. info .. " consts=[" .. table.concat(hits, ",") .. "]")

                    -- only hook if name/source suggests reload, not every ammo string
                    local shouldHook = false
                    for _, h in ipairs(hits) do
                        local l = string.lower(h)
                        if l:find("reload") then shouldHook = true end
                    end
                    if shouldHook and hooked < 8 then
                        local success, herr = pcall(function()
                            local old = obj
                            -- hookfunction if available
                            if hookfunction then
                                hookfunction(obj, function(...)
                                    if Silent.Config.InstaReload then
                                        print("[Rage] skipped reload fn")
                                        return
                                    end
                                    return old(...)
                                end)
                                hooked = hooked + 1
                            end
                        end)
                        if not success then
                            warn("[Rage] hook failed: " .. tostring(herr))
                        end
                    end
                end
            end
        end
    end)

    if not ok then
        warn("[Rage] reload scan error: " .. tostring(err))
    end
    print("[Rage] reload-const functions listed: " .. tostring(listed) .. " hooked: " .. tostring(hooked))
    reloadHooksDone = true
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

    if not reloadHooksDone then
        HookReloadFunctions()
    end

    -- try fire local Reload remote as "done" — may no-op or error; pcall only
    task.defer(function()
        if not Silent.Config.InstaReload then return end
        local cr = LocalPlayer:FindFirstChild("ClientRemotes")
        if cr then
            local rel = cr:FindFirstChild("Reload")
            if rel and rel:IsA("RemoteEvent") then
                -- do not FireServer — server may interpret as start reload
                print("[Rage] ClientRemotes.Reload present (not auto-fired)")
            end
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
        if Silent.Config.InstaReload then
            HookReloadFunctions()
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
