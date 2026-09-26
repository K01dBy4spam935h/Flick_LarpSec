--[[
    LarpSec · Kill Sound
    Mute by SoundId + Play hooks · play custom on kill
]]

local Players          = game:GetService("Players")
local SoundService     = game:GetService("SoundService")
local RunService       = game:GetService("RunService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local LocalPlayer      = Players.LocalPlayer

local KillSound = {}
local Config
local lastPlay = 0
local blockedIds = {} -- [soundId string] = true
local watched = setmetatable({}, { __mode = "k" })

local NAME_KEYS = {
    "hitsound", "hit_sound", "hitmarker", "kill", "killed",
    "headshot", "elim", "death", "oof", "hit",
}

local function shouldBlock(sound)
    if typeof(sound) ~= "Instance" or not sound:IsA("Sound") then return false end
    local n = sound.Name or ""
    if n == "LarpSecKill" or n == "LarpSecPreview" then return false end
    local sid = tostring(sound.SoundId or "")
    if sid ~= "" and blockedIds[sid] then return true end
    n = string.lower(n)
    for _, k in ipairs(NAME_KEYS) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

local function muteSound(sound)
    pcall(function()
        sound.Volume = 0
        pcall(function() sound:Stop() end)
    end)
end

local function rememberId(sound)
    pcall(function()
        local sid = tostring(sound.SoundId or "")
        if sid ~= "" and sid ~= "rbxassetid://0" then
            blockedIds[sid] = true
        end
    end)
end

local function watchSound(sound)
    if watched[sound] then return end
    if not sound:IsA("Sound") then return end
    -- learn ids from game hit sounds by name
    local n = string.lower(sound.Name or "")
    for _, k in ipairs(NAME_KEYS) do
        if n:find(k, 1, true) then
            rememberId(sound)
            break
        end
    end
    if not shouldBlock(sound) then return end
    watched[sound] = true
    muteSound(sound)
    pcall(function()
        sound:GetPropertyChangedSignal("Playing"):Connect(function()
            if sound.Playing then muteSound(sound) end
        end)
        sound.Played:Connect(function()
            muteSound(sound)
        end)
    end)
end

local function scanAll()
    pcall(function()
        local roots = {
            workspace,
            SoundService,
            ReplicatedStorage,
            LocalPlayer:FindFirstChild("PlayerGui"),
            LocalPlayer:FindFirstChild("PlayerScripts"),
        }
        for _, root in ipairs(roots) do
            if root then
                for _, s in ipairs(root:GetDescendants()) do
                    if s:IsA("Sound") then watchSound(s) end
                end
            end
        end
    end)
end

local function harvestHitSoundIds()
    pcall(function()
        local gm = ReplicatedStorage:FindFirstChild("ModuleScripts")
        if not gm then return end
        for _, s in ipairs(gm:GetDescendants()) do
            if s:IsA("Sound") then
                local n = string.lower(s.Name)
                if n:find("hit") or n:find("kill") then
                    rememberId(s)
                    watchSound(s)
                end
            end
        end
    end)
end

local function playId(id, tag)
    if not id or id == "" then return end
    local sid = tostring(id)
    if not sid:find("rbxassetid") then
        sid = "rbxassetid://" .. sid
    end
    pcall(function()
        local s = Instance.new("Sound")
        s.Name = tag or "LarpSecKill"
        s.SoundId = sid
        s.Volume = 2
        s.Parent = SoundService
        if SoundService.PlayLocalSound then
            SoundService:PlayLocalSound(s)
        end
        pcall(function() s:Play() end)
        task.delay(8, function()
            pcall(function() s:Destroy() end)
        end)
    end)
end

function KillSound.Play()
    if not Config then return end
    local id = Config.GetSelectedKillSoundId()
    if not id then return end
    if tick() - lastPlay < 0.05 then return end
    lastPlay = tick()
    playId(id, "LarpSecKill")
end

function KillSound.Preview()
    if not Config then return end
    local id = Config.GetSelectedKillSoundId()
    if not id then
        warn("[KillSound] none selected")
        return
    end
    playId(id, "LarpSecPreview")
end

function KillSound.Init(cfg)
    Config = cfg
    harvestHitSoundIds()
    scanAll()

    -- PlayLocalSound gate
    pcall(function()
        if not hookfunction then return end
        local oldPLS
        oldPLS = hookfunction(SoundService.PlayLocalSound, function(self, sound, ...)
            if shouldBlock(sound) then
                muteSound(sound)
                return
            end
            return oldPLS(self, sound, ...)
        end)
    end)

    -- any new sound
    local function onAdded(inst)
        if inst:IsA("Sound") then
            task.defer(function()
                watchSound(inst)
                -- if it starts playing next frames, kill volume
                task.delay(0.05, function()
                    if shouldBlock(inst) then muteSound(inst) end
                end)
            end)
        end
    end
    workspace.DescendantAdded:Connect(onAdded)
    SoundService.DescendantAdded:Connect(onAdded)
    pcall(function()
        ReplicatedStorage.DescendantAdded:Connect(onAdded)
    end)

    -- every frame: silence blocked playing sounds (catches clones / PlayLocalSound copies)
    RunService.Heartbeat:Connect(function()
        pcall(function()
            for _, s in ipairs(SoundService:GetChildren()) do
                if s:IsA("Sound") and shouldBlock(s) then
                    muteSound(s)
                end
            end
        end)
    end)

    -- kill detect: Died + HealthChanged
    local function track(plr)
        if plr == LocalPlayer then return end
        local function bind(char)
            local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
            if not hum then return end
            local last = hum.Health
            hum.Died:Connect(function()
                local my = LocalPlayer.Character
                local mh = my and my:FindFirstChildOfClass("Humanoid")
                if mh and mh.Health > 0 then
                    KillSound.Play()
                end
            end)
            hum.HealthChanged:Connect(function(h)
                if last > 0 and h <= 0 then
                    local my = LocalPlayer.Character
                    local mh = my and my:FindFirstChildOfClass("Humanoid")
                    if mh and mh.Health > 0 then
                        KillSound.Play()
                    end
                end
                last = h
            end)
        end
        if plr.Character then task.spawn(bind, plr.Character) end
        plr.CharacterAdded:Connect(function(c) task.spawn(bind, c) end)
    end
    for _, p in ipairs(Players:GetPlayers()) do track(p) end
    Players.PlayerAdded:Connect(track)

    task.spawn(function()
        while true do
            task.wait(2)
            harvestHitSoundIds()
            scanAll()
        end
    end)
end

return KillSound
