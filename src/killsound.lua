--[[
    LarpSec · Kill / Death / Music
]]

local Players           = game:GetService("Players")
local SoundService      = game:GetService("SoundService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer

local KillSound = {}
local Config
local lastPlay = 0
local blockedIds = {}
local watched = setmetatable({}, { __mode = "k" })
local musicSound = nil
local musicGen = 0

local NAME_KEYS = {
    "hitsound", "hit_sound", "hitmarker", "kill", "killed",
    "headshot", "elim", "death", "oof", "hit",
}

local function shouldBlock(sound)
    if typeof(sound) ~= "Instance" or not sound:IsA("Sound") then return false end
    local n = sound.Name or ""
    if n:find("LarpSec") then return false end
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
        sound.Played:Connect(function() muteSound(sound) end)
    end)
end

local function scanAll()
    pcall(function()
        for _, root in ipairs({
            workspace, SoundService, ReplicatedStorage,
            LocalPlayer:FindFirstChild("PlayerGui"),
            LocalPlayer:FindFirstChild("PlayerScripts"),
        }) do
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

local function playId(id, tag, vol)
    if not id or id == "" then return end
    local sid = tostring(id)
    if not sid:find("rbxassetid") then sid = "rbxassetid://" .. sid end
    pcall(function()
        local s = Instance.new("Sound")
        s.Name = tag or "LarpSecKill"
        s.SoundId = sid
        s.Volume = vol or 2
        s.Parent = SoundService
        if SoundService.PlayLocalSound then
            SoundService:PlayLocalSound(s)
        end
        pcall(function() s:Play() end)
        task.delay(10, function() pcall(function() s:Destroy() end) end)
    end)
end

function KillSound.Play()
    if not Config then return end
    local id = Config.GetSelectedKillSoundId()
    if not id then return end
    if tick() - lastPlay < 0.05 then return end
    lastPlay = tick()
    playId(id, "LarpSecKill", 2)
end

function KillSound.PlayDeath()
    if not Config then return end
    local id = Config.GetSelectedDeathSoundId()
    if not id then return end
    playId(id, "LarpSecDeath", 2)
end

function KillSound.Preview()
    if not Config then return end
    local id = Config.GetSelectedKillSoundId()
    if not id then warn("[KillSound] none selected") return end
    playId(id, "LarpSecPreview", 2)
end

function KillSound.PreviewDeath()
    if not Config then return end
    local id = Config.GetSelectedDeathSoundId()
    if not id then warn("[DeathSound] none selected") return end
    playId(id, "LarpSecPreviewDeath", 2)
end

function KillSound.StartMusic(forceName)
    if not Config then return end
    local name = forceName or Config.GetSelectedMusicName()
    if not name then return end
    local raw = Config.Get().music[name]
    local id = Config.NormalizeAssetId(raw, "sound")
    if not id then return end

    KillSound.StopMusic()
    Config.SetSelectedMusic(name)

    pcall(function()
        local sid = tostring(id)
        if not sid:find("rbxassetid") then sid = "rbxassetid://" .. sid end
        local s = Instance.new("Sound")
        s.Name = "LarpSecMusic"
        s.SoundId = sid
        s.Volume = Config.Get().musicVolume or 0.5
        s.Looped = false
        s.Parent = SoundService
        musicSound = s
        Config.Get().musicPlaying = true

        local cutoff = Config.GetMusicCutoff(name)
        musicGen = musicGen + 1
        local gen = musicGen

        s.Ended:Connect(function()
            if musicGen ~= gen then return end
            if Config.Get().musicAutoAdvance then
                KillSound.PlayNextMusic()
            else
                Config.Get().musicPlaying = false
                musicSound = nil
            end
        end)

        s:Play()

        -- only THIS song's cutoff
        if cutoff and cutoff > 0 then
            task.spawn(function()
                local t0 = tick()
                while musicGen == gen and musicSound == s and s.Parent do
                    if tick() - t0 >= cutoff then
                        if musicGen == gen then
                            pcall(function() s:Stop() end)
                            if Config.Get().musicAutoAdvance then
                                KillSound.PlayNextMusic()
                            else
                                KillSound.StopMusic()
                            end
                        end
                        break
                    end
                    task.wait(0.1)
                end
            end)
        end
    end)
end

function KillSound.PlayNextMusic()
    if not Config then return end
    local list = Config.GetMusicPlaylist()
    if #list == 0 then
        KillSound.StopMusic()
        return
    end
    local cur = Config.GetSelectedMusicName()
    local idx = 1
    for i, n in ipairs(list) do
        if n == cur then
            idx = i
            break
        end
    end
    local nextName = list[(idx % #list) + 1]
    KillSound.StartMusic(nextName)
end

function KillSound.StopMusic()
    musicGen = musicGen + 1
    if musicSound then
        pcall(function()
            musicSound:Stop()
            musicSound:Destroy()
        end)
        musicSound = nil
    end
    if Config then Config.Get().musicPlaying = false end
end

function KillSound.SetMusicVolume(v)
    if Config then Config.Get().musicVolume = v end
    if musicSound then pcall(function() musicSound.Volume = v end) end
end

function KillSound.Init(cfg)
    Config = cfg
    harvestHitSoundIds()
    scanAll()

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

    local function onAdded(inst)
        if inst:IsA("Sound") then
            task.defer(function()
                watchSound(inst)
                task.delay(0.05, function()
                    if shouldBlock(inst) then muteSound(inst) end
                end)
            end)
        end
    end
    workspace.DescendantAdded:Connect(onAdded)
    SoundService.DescendantAdded:Connect(onAdded)

    RunService.Heartbeat:Connect(function()
        pcall(function()
            for _, s in ipairs(SoundService:GetChildren()) do
                if s:IsA("Sound") and shouldBlock(s) then muteSound(s) end
            end
        end)
    end)

    local function trackEnemy(plr)
        if plr == LocalPlayer then return end
        local function bind(char)
            local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 5)
            if not hum then return end
            local last = hum.Health
            hum.Died:Connect(function()
                local my = LocalPlayer.Character
                local mh = my and my:FindFirstChildOfClass("Humanoid")
                if mh and mh.Health > 0 then KillSound.Play() end
            end)
            hum.HealthChanged:Connect(function(h)
                if last > 0 and h <= 0 then
                    local my = LocalPlayer.Character
                    local mh = my and my:FindFirstChildOfClass("Humanoid")
                    if mh and mh.Health > 0 then KillSound.Play() end
                end
                last = h
            end)
        end
        if plr.Character then task.spawn(bind, plr.Character) end
        plr.CharacterAdded:Connect(function(c) task.spawn(bind, c) end)
    end
    for _, p in ipairs(Players:GetPlayers()) do trackEnemy(p) end
    Players.PlayerAdded:Connect(trackEnemy)

    local lastDeathPlay = 0
    local function onLocalDeath()
        if tick() - lastDeathPlay < 0.4 then return end
        lastDeathPlay = tick()
        KillSound.PlayDeath()
    end
    local function trackSelf(char)
        local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 8)
        if not hum then return end
        local lastH = hum.Health
        hum.Died:Connect(onLocalDeath)
        hum.HealthChanged:Connect(function(h)
            if lastH > 0 and h <= 0 then
                onLocalDeath()
            end
            lastH = h
        end)
        -- some games destroy character without firing Died cleanly
        char.AncestryChanged:Connect(function(_, parent)
            if parent == nil and lastH > 0 and lastH < (hum.MaxHealth or 100) then
                -- died mid-life (not a clean leave)
                if lastH <= 5 then onLocalDeath() end
            end
        end)
    end
    if LocalPlayer.Character then task.spawn(trackSelf, LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(function(c) task.spawn(trackSelf, c) end)
    LocalPlayer.CharacterRemoving:Connect(function(c)
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then
            onLocalDeath()
        end
    end)

    task.spawn(function()
        while true do
            task.wait(2)
            harvestHitSoundIds()
            scanAll()
        end
    end)
end

return KillSound
