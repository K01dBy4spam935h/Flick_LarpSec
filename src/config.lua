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
    ["Paparazzi"] = "rbxassetid://76767355656506",
    ["Drunk And Honest"] = "rbxassetid://77185624204161",
    ["Misery"] = "rbxassetid://86317637164248",
    ["Terranova"] = "rbxassetid://82746224492420",
    ["Rap"] = "rbxassetid://110128107517269",
    ["Just The Way You Are"] = "rbxassetid://99625682843508",
    ["For My Girl"] = "rbxassetid://71393805905055",
}

-- per-song cutoff in seconds (only that song). 0 / missing = play full length
local DEFAULT_MUSIC_CUTOFFS = {
    ["For My Girl"] = 81,
    ["Drunk And Honest"] = 119,
    ["Misery"] = 88,
}

local DEFAULT_IMAGES = {
    ["Kanye West Funny"] = "5649884823",
    ["Dark Anime Girl"] = "6311243701",
    ["Hacker"] = "7167707594",
    ["Scary"] = "7255938910",
    ["Anime Girl Pink Aesthetic"] = "6675147490",
    ["Background 1"] = "1050669269",
    ["Funny Dude"] = "2184817907",
}
-- ==============================

local HttpService = game:GetService("HttpService")
local Config = {}

local data = {
    killSounds = {},
    deathSounds = {},
    music = {},
    musicCutoffs = {},
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
    return Config.SaveProfile("default", extra)
end

function Config.LoadFile()
    return Config.LoadProfile("default")
end

local function sanitizeName(name)
    name = tostring(name or "default"):gsub("[^%w%-%_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "default" end
    return name
end

local function profilePath(name)
    return "LarpSec_profile_" .. sanitizeName(name) .. ".json"
end

local INDEX_FILE = "LarpSec_profiles.json"

function Config.ListProfiles()
    local list = {}
    pcall(function()
        if isfile and isfile(INDEX_FILE) and readfile then
            local t = HttpService:JSONDecode(readfile(INDEX_FILE))
            if type(t) == "table" then list = t end
        end
    end)
    -- always include default if file exists
    local has = {}
    for _, n in ipairs(list) do has[n] = true end
    if not has["default"] then table.insert(list, 1, "default") end
    return list
end

local function writeIndex(list)
    pcall(function()
        if writefile then
            writefile(INDEX_FILE, HttpService:JSONEncode(list))
        end
    end)
end

function Config.SaveProfile(name, extra)
    name = sanitizeName(name)
    local packet = {
        version = 4,
        name = name,
        killSounds = data.killSounds,
        deathSounds = data.deathSounds,
        music = data.music,
        musicCutoffs = data.musicCutoffs,
        images = data.images,
        selectedKillSound = data.selectedKillSound,
        selectedDeathSound = data.selectedDeathSound,
        selectedBackground = data.selectedBackground,
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
            writefile(profilePath(name), HttpService:JSONEncode(packet))
        else
            local g = getgenv and getgenv() or _G
            g.LarpSecSaves = g.LarpSecSaves or {}
            g.LarpSecSaves[name] = packet
        end
    end)
    if ok then
        local list = Config.ListProfiles()
        local found = false
        for _, n in ipairs(list) do if n == name then found = true break end end
        if not found then table.insert(list, name) end
        writeIndex(list)
    end
    return ok
end

function Config.LoadProfile(name)
    name = sanitizeName(name)
    local packet
    pcall(function()
        local path = profilePath(name)
        if isfile and isfile(path) and readfile then
            packet = HttpService:JSONDecode(readfile(path))
        end
    end)
    if not packet then
        pcall(function()
            local g = getgenv and getgenv() or _G
            if g.LarpSecSaves then packet = g.LarpSecSaves[name] end
        end)
    end
    -- legacy single file
    if not packet and name == "default" then
        pcall(function()
            if isfile and isfile(SAVE_FILE) and readfile then
                packet = HttpService:JSONDecode(readfile(SAVE_FILE))
            end
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
    data.selectedBackground = packet.selectedBackground or data.selectedBackground
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

function Config.DeleteProfile(name)
    name = sanitizeName(name)
    if name == "default" then return false end
    pcall(function()
        if delfile and isfile and isfile(profilePath(name)) then
            delfile(profilePath(name))
        end
    end)
    local list, out = Config.ListProfiles(), {}
    for _, n in ipairs(list) do
        if n ~= name then table.insert(out, n) end
    end
    writeIndex(out)
    return true
end

function Config.Load()
    return data
end

function Config.Save()
end

return Config
