--[[
    LarpSec · Config
    Edit tables below OR add IDs in-UI (saved to LarpSec_save.json)
]]

-- ========== DEFAULTS ==========
local DEFAULT_KILL = {
    ["uwu"] = "rbxassetid://139219844119994",
    ["oof"] = "rbxassetid://139019913635357",
    ["Cracked"] = "rbxassetid://139933713042888",
    ["MM2 - Gunshot"] = "rbxassetid://72486045176582",
    ["MM2 - Knife"] = "rbxassetid://96761506644564",
    ["Nani!?"] = "rbxassetid://77547270929945",
    ["Fart"] = "rbxassetid://138132180123464",
    ["Senpai"] = "rbxassetid://115498703521334",
    ["Anime Cat Girl"] = "rbxassetid://104321578550512",
    ["Android Notification"] = "rbxassetid://81041181328536",
}

local DEFAULT_DEATH = {
    ["oof"] = "rbxassetid://139019913635357",
    ["Cracked"] = "rbxassetid://139933713042888",
    ["Anime Girl Scream"] = "rbxassetid://91651003035814",
    ["Nani!?"] = "rbxassetid://77547270929945",
    ["Garry's Mod Death Sound"] = "rbxassetid://140153453307373",
    ["Death Bang"] = "rbxassetid://139846745296940",
    ["Fold Valley Death"] = "rbxassetid://123575028398063",
    ["Uh Oh"] = "rbxassetid://123634096731592",
    ["Snoring"] = "rbxassetid://110110344375165",
    ["Fah!"] = "rbxassetid://138788420216035",
    ["Fart"] = "rbxassetid://125967527987624",
    ["Laugh"] = "rbxassetid://136931085501622",
    ["Funny Sound"] = "rbxassetid://133467169655691",
    ["Funny Scream"] = "rbxassetid://6999993863",
}

local DEFAULT_MUSIC = {
    ["Drift Night Phonk"] = "rbxassetid://85735197482652",
    ["I love You So"] = "rbxassetid://100048144167699",
    ["Low Cortisol"] = "rbxassetid://110919391228823",
    ["Great Fairys Fountain"] = "rbxassetid://123076660184344",
    ["Tick Tack"] = "rbxassetid://122708070570064",
    ["Under Your Spell"] = "rbxassetid://91007045451630",
    ["For My Girl"] = "rbxassetid://71393805905055",
}

-- per-song cutoff in seconds (only that song). 0 / missing = play full length
local DEFAULT_MUSIC_CUTOFFS = {
    -- ["Drift Night Phonk"] = 42.5,
}

local DEFAULT_IMAGES = {
    -- ["Bg1"] = "123456789",
}
-- ==============================

local HttpService = game:GetService("HttpService")
local Config = {}

local data = {
    killSounds = {},
    deathSounds = {},
    music = {},
    musicCutoffs = {}, -- [name] = number seconds
    images = {},
    selectedKillSound = "",
    selectedDeathSound = "",
    selectedMusic = "",
    selectedBackground = "",
    musicVolume = 0.5,
    musicPlaying = false,
    musicAutoAdvance = true,
}

for k, v in pairs(DEFAULT_KILL) do data.killSounds[k] = v end
for k, v in pairs(DEFAULT_DEATH) do data.deathSounds[k] = v end
for k, v in pairs(DEFAULT_MUSIC) do data.music[k] = v end
for k, v in pairs(DEFAULT_MUSIC_CUTOFFS) do data.musicCutoffs[k] = v end
for k, v in pairs(DEFAULT_IMAGES) do data.images[k] = v end

local SAVE_FILE = "LarpSec_save.json"

local function colorToTbl(c)
    if typeof(c) == "Color3" then
        return { r = c.R, g = c.G, b = c.B }
    end
    return c
end

local function tblToColor(t)
    if type(t) == "table" and t.r then
        return Color3.new(t.r, t.g, t.b)
    end
    return t
end

function Config.NormalizeAssetId(id, kind)
    if not id or id == "" then return nil end
    local s = tostring(id):gsub("%s+", "")
    local num = s:match("(%d+)")
    if not num then return s end
    if kind == "image" then
        return "rbxassetid://" .. num, num
    end
    if not s:find("rbxassetid") then
        return "rbxassetid://" .. num
    end
    return s
end

function Config.ResolveImage(id)
    local full = Config.NormalizeAssetId(id, "image")
    return full or ""
end

function Config.ResolveImageFallbacks(id)
    local full, num = Config.NormalizeAssetId(id, "image")
    if not num then return { tostring(id) } end
    return {
        "rbxassetid://" .. num,
        "rbxthumb://type=Asset&id=" .. num .. "&w=420&h=420",
        "https://www.roblox.com/asset/?id=" .. num,
    }
end

local function namesFrom(map)
    local names = { "Off" }
    for name in pairs(map or {}) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b)
        if a == "Off" then return true end
        if b == "Off" then return false end
        return a:lower() < b:lower()
    end)
    return names
end

function Config.Get() return data end

function Config.GetKillSoundNames() return namesFrom(data.killSounds) end
function Config.GetDeathSoundNames() return namesFrom(data.deathSounds) end
function Config.GetMusicNames() return namesFrom(data.music) end
function Config.GetImageNames() return namesFrom(data.images) end

-- ordered playlist (alphabetical, Off excluded) for auto-advance
function Config.GetMusicPlaylist()
    local list = {}
    for name, id in pairs(data.music) do
        local sid = tostring(id or "")
        if name ~= "Off" and sid ~= "" and sid ~= "rbxassetid://0" and sid ~= "0" then
            table.insert(list, name)
        end
    end
    table.sort(list, function(a, b) return a:lower() < b:lower() end)
    return list
end

function Config.GetMusicCutoff(name)
    if not name or name == "" then return 0 end
    local c = data.musicCutoffs[name]
    if type(c) == "number" and c > 0 then return c end
    return 0
end

function Config.SetMusicCutoff(name, seconds)
    if not name or name == "" or name == "Off" then return end
    local s = tonumber(seconds) or 0
    if s <= 0 then
        data.musicCutoffs[name] = nil
    else
        data.musicCutoffs[name] = s
    end
end

function Config.GetSelectedKillSoundId()
    local sel = data.selectedKillSound
    if not sel or sel == "" or sel == "Off" then return nil end
    return Config.NormalizeAssetId(data.killSounds[sel], "sound")
end

function Config.GetSelectedDeathSoundId()
    local sel = data.selectedDeathSound
    if not sel or sel == "" or sel == "Off" then return nil end
    return Config.NormalizeAssetId(data.deathSounds[sel], "sound")
end

function Config.GetSelectedMusicId()
    local sel = data.selectedMusic
    if not sel or sel == "" or sel == "Off" then return nil end
    return Config.NormalizeAssetId(data.music[sel], "sound")
end

function Config.GetSelectedMusicName()
    local sel = data.selectedMusic
    if not sel or sel == "" or sel == "Off" then return nil end
    return sel
end

function Config.GetSelectedBackgroundId()
    local sel = data.selectedBackground
    if not sel or sel == "" or sel == "Off" then return nil end
    return data.images[sel]
end

function Config.SetSelectedKillSound(name)
    data.selectedKillSound = (name == "Off" or not name) and "" or name
end
function Config.SetSelectedDeathSound(name)
    data.selectedDeathSound = (name == "Off" or not name) and "" or name
end
function Config.SetSelectedMusic(name)
    data.selectedMusic = (name == "Off" or not name) and "" or name
end
function Config.SetSelectedBackground(name)
    data.selectedBackground = (name == "Off" or not name) and "" or name
end

function Config.AddKillSound(name, id)
    if not name or name == "" or not id then return false end
    data.killSounds[name] = tostring(id)
    return true
end
function Config.AddDeathSound(name, id)
    if not name or name == "" or not id then return false end
    data.deathSounds[name] = tostring(id)
    return true
end
function Config.AddMusic(name, id)
    if not name or name == "" or not id then return false end
    data.music[name] = tostring(id)
    return true
end
function Config.AddImage(name, id)
    if not name or name == "" or not id then return false end
    data.images[name] = tostring(id)
    return true
end

function Config.SaveFile(extra)
    local packet = {
        version = 2,
        killSounds = data.killSounds,
        deathSounds = data.deathSounds,
        music = data.music,
        musicCutoffs = data.musicCutoffs,
        images = data.images,
        selectedKillSound = data.selectedKillSound,
        selectedDeathSound = data.selectedDeathSound,
        selectedMusic = data.selectedMusic,
        selectedBackground = data.selectedBackground,
        musicVolume = data.musicVolume,
        musicAutoAdvance = data.musicAutoAdvance,
        features = extra or {},
    }
    local function walk(t)
        if type(t) ~= "table" then return t end
        local n = {}
        for k, v in pairs(t) do
            if typeof(v) == "Color3" then
                n[k] = colorToTbl(v)
            elseif type(v) == "table" then
                n[k] = walk(v)
            else
                n[k] = v
            end
        end
        return n
    end
    packet.features = walk(packet.features)
    local ok = pcall(function()
        if writefile then
            writefile(SAVE_FILE, HttpService:JSONEncode(packet))
        else
            local g = getgenv and getgenv() or _G
            g.LarpSecSave = packet
        end
    end)
    return ok
end

function Config.LoadFile()
    local packet
    pcall(function()
        if isfile and isfile(SAVE_FILE) and readfile then
            packet = HttpService:JSONDecode(readfile(SAVE_FILE))
        end
    end)
    if not packet then
        pcall(function()
            local g = getgenv and getgenv() or _G
            packet = g.LarpSecSave
        end)
    end
    if type(packet) ~= "table" then return nil end
    if type(packet.killSounds) == "table" then
        for k, v in pairs(packet.killSounds) do data.killSounds[k] = v end
    end
    if type(packet.deathSounds) == "table" then
        for k, v in pairs(packet.deathSounds) do data.deathSounds[k] = v end
    end
    if type(packet.music) == "table" then
        for k, v in pairs(packet.music) do data.music[k] = v end
    end
    if type(packet.musicCutoffs) == "table" then
        data.musicCutoffs = packet.musicCutoffs
    end
    if type(packet.images) == "table" then
        for k, v in pairs(packet.images) do data.images[k] = v end
    end
    data.selectedKillSound = packet.selectedKillSound or data.selectedKillSound
    data.selectedDeathSound = packet.selectedDeathSound or data.selectedDeathSound
    data.selectedMusic = packet.selectedMusic or data.selectedMusic
    data.selectedBackground = packet.selectedBackground or data.selectedBackground
    data.musicVolume = packet.musicVolume or data.musicVolume
    if packet.musicAutoAdvance ~= nil then data.musicAutoAdvance = packet.musicAutoAdvance end
    local function walk(t)
        if type(t) ~= "table" then return t end
        local n = {}
        for k, v in pairs(t) do
            if type(v) == "table" and v.r and v.g and v.b and not v[1] then
                n[k] = tblToColor(v)
            elseif type(v) == "table" then
                n[k] = walk(v)
            else
                n[k] = v
            end
        end
        return n
    end
    return walk(packet.features or {})
end

function Config.Load()
    return data
end

function Config.Save()
end

return Config
