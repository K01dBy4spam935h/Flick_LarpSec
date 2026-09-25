--[[
    LarpSec · Kill Sound
    Mute HitSound-class game sounds · play user sound via PlayLocalSound
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

local KillSound = {}
local Config
local lastPlay = 0
local watched = setmetatable({}, { __mode = "k" })

local BLOCK_SUB = {
    "hitsound", "hit_sound", "hitmarker", "kill", "killed",
    "headshot", "elim", "death", "oof", "slain",
}

local function shouldBlock(sound)
    if not sound or not sound:IsA("Sound") then return false end
    -- never block our own preview/kill sounds
    if sound.Name == "LarpSecKill" or sound.Name == "LarpSecPreview" then return false end
    local n = string.lower(sound.Name)
    local id = string.lower(tostring(sound.SoundId or ""))
    for _, key in ipairs(BLOCK_SUB) do
        if n:find(key, 1, true) then return true end
    end
    -- Flick gun hit
    if n == "hitsound" or n:find("hit", 1, true) and n:find("sound", 1, true) then
        return true
    end
    return false
end

local function muteSound(sound)
    pcall(function()
        sound.Volume = 0
        if sound.Playing then sound:Stop() end
    end)
end

local function watchSound(sound)
    if watched[sound] then return end
    if not shouldBlock(sound) then return end
    watched[sound] = true
    muteSound(sound)
    pcall(function()
        sound:GetPropertyChangedSignal("Playing"):Connect(function()
            if sound.Playing then muteSound(sound) end
        end)
        sound:GetPropertyChangedSignal("Volume"):Connect(function()
            if shouldBlock(sound) and sound.Volume > 0 then
                sound.Volume = 0
            end
        end)
        sound.Played:Connect(function()
            muteSound(sound)
        end)
    end)
end

local function scanAll()
    local roots = {
        workspace,
        SoundService,
        LocalPlayer:FindFirstChild("PlayerGui"),
        LocalPlayer:FindFirstChild("PlayerScripts"),
        game:GetService("ReplicatedStorage"),
    }
    for _, root in ipairs(roots) do
        if root then
            pcall(function()
                for _, s in ipairs(root:GetDescendants()) do
                    if s:IsA("Sound") then watchSound(s) end
                end
            end)
        end
    end
end

local function playId(id, name)
    if not id or id == "" then return false end
    id = tostring(id)
    if not id:find("rbxassetid://") and tonumber(id) then
        id = "rbxassetid://" .. id
    end
    local ok = false
    pcall(function()
        local holder = LocalPlayer:FindFirstChild("PlayerGui")
        if not holder then
            holder = Instance.new("ScreenGui")
            holder.Name = "LarpSecAudio"
            holder.ResetOnSpawn = false
            holder.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
        local s = Instance.new("Sound")
        s.Name = name or "LarpSecKill"
        s.SoundId = id
        s.Volume = 1
        s.Looped = false
        s.Parent = holder
        -- PlayLocalSound is the reliable client hear path
        pcall(function()
            SoundService:PlayLocalSound(s)
        end)
        pcall(function()
            s:Play()
        end)
        task.delay(6, function()
            pcall(function() s:Destroy() end)
        end)
        ok = true
    end)
    return ok
end

function KillSound.Play()
    if not Config then return end
    local id = Config.GetSelectedKillSoundId()
    if not id then return end
    if tick() - lastPlay < 0.08 then return end
    lastPlay = tick()
    playId(id, "LarpSecKill")
end

function KillSound.Preview()
    if not Config then return end
    local id = Config.GetSelectedKillSoundId()
    if not id then return end
    playId(id, "LarpSecPreview")
end

function KillSound.Init(cfg)
    Config = cfg
    scanAll()

    local function onAdded(inst)
        if inst:IsA("Sound") then
            task.defer(watchSound, inst)
        end
    end
    workspace.DescendantAdded:Connect(onAdded)
    SoundService.DescendantAdded:Connect(onAdded)
    pcall(function()
        LocalPlayer:WaitForChild("PlayerGui").DescendantAdded:Connect(onAdded)
    end)
    pcall(function()
        game:GetService("ReplicatedStorage").DescendantAdded:Connect(onAdded)
    end)

    -- any player health 0 while we're alive → kill feedback (client)
    local function track(plr)
        if plr == LocalPlayer then return end
        local function bind(char)
            local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 4)
            if not hum then return end
            local last = hum.Health
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
            task.wait(3)
            scanAll()
        end
    end)
end

return KillSound
