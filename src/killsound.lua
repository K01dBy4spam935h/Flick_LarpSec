--[[
    LarpSec · Kill Sound
    Blocks common in-game hit/kill sounds; plays user sound from Config
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local LocalPlayer = Players.LocalPlayer

local KillSound = {}
local Config
local muted = {}
local lastPlay = 0

local BLOCK_NAMES = {
    hitsound = true,
    hit = true,
    kill = true,
    killed = true,
    headshot = true,
    death = true,
    elim = true,
    elimination = true,
}

local function shouldBlock(sound)
    if not sound or not sound:IsA("Sound") then return false end
    local n = string.lower(sound.Name)
    if BLOCK_NAMES[n] then return true end
    for key in pairs(BLOCK_NAMES) do
        if n:find(key, 1, true) then return true end
    end
    return false
end

local function muteSound(sound)
    pcall(function()
        sound.Volume = 0
        sound:Stop()
    end)
end

local function watchSound(sound)
    if not shouldBlock(sound) then return end
    muteSound(sound)
    if muted[sound] then return end
    muted[sound] = true
    pcall(function()
        sound:GetPropertyChangedSignal("Playing"):Connect(function()
            if sound.Playing then muteSound(sound) end
        end)
        sound:GetPropertyChangedSignal("Volume"):Connect(function()
            if sound.Volume > 0 and shouldBlock(sound) then sound.Volume = 0 end
        end)
    end)
end

local function scanExisting()
    pcall(function()
        for _, s in ipairs(workspace:GetDescendants()) do
            if s:IsA("Sound") then watchSound(s) end
        end
        for _, s in ipairs(SoundService:GetDescendants()) do
            if s:IsA("Sound") then watchSound(s) end
        end
        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then
            for _, s in ipairs(pg:GetDescendants()) do
                if s:IsA("Sound") then watchSound(s) end
            end
        end
    end)
end

function KillSound.Play()
    if not Config then return end
    local id = Config.GetSelectedKillSoundId()
    if not id or id == "" then return end
    if tick() - lastPlay < 0.05 then return end
    lastPlay = tick()
    pcall(function()
        local s = Instance.new("Sound")
        s.SoundId = tostring(id)
        s.Volume = 1
        s.Parent = SoundService
        s:Play()
        s.Ended:Connect(function()
            s:Destroy()
        end)
        task.delay(5, function()
            if s then pcall(function() s:Destroy() end) end
        end)
    end)
end

local function onCharacter(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.Died:Connect(function()
        -- someone died; if we were involved is hard — play on any nearby death when we have a selection
        -- tighter: only when local player is alive and killed recently handled via health track of others
    end)
end

function KillSound.Init(cfg)
    Config = cfg
    scanExisting()
    workspace.DescendantAdded:Connect(function(inst)
        if inst:IsA("Sound") then
            task.defer(watchSound, inst)
        end
    end)
    SoundService.DescendantAdded:Connect(function(inst)
        if inst:IsA("Sound") then
            task.defer(watchSound, inst)
        end
    end)

    -- play custom sound when another player dies while we are alive (client-side elim feedback)
    local healthCache = {}
    local function trackPlayer(plr)
        if plr == LocalPlayer then return end
        local function bind(char)
            local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
            if not hum then return end
            healthCache[plr] = hum.Health
            hum.HealthChanged:Connect(function(h)
                local prev = healthCache[plr] or h
                healthCache[plr] = h
                if prev > 0 and h <= 0 then
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                        KillSound.Play()
                    end
                end
            end)
        end
        if plr.Character then bind(plr.Character) end
        plr.CharacterAdded:Connect(bind)
    end
    for _, p in ipairs(Players:GetPlayers()) do trackPlayer(p) end
    Players.PlayerAdded:Connect(trackPlayer)

    task.spawn(function()
        while true do
            task.wait(4)
            scanExisting()
        end
    end)
end

return KillSound
