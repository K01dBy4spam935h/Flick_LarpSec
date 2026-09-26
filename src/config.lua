--[[
    LarpSec · Config
    Edit tables below OR add IDs in-UI (saved to LarpSec_save.json)
]]

-- ========== OPTIONAL DEFAULTS ==========
local DEFAULT_KILL = {
    -- ["Cracked"] = "rbxassetid://123456789",
}
local DEFAULT_DEATH = {
    -- ["Oof"] = "rbxassetid://0",
}
local DEFAULT_MUSIC = {
    -- ["Track1"] = "rbxassetid://0",
}
local DEFAULT_IMAGES = {
    -- ["Bg1"] = "123456789", -- raw numeric or rbxassetid:// both ok
}
-- ======================================

local HttpService = game:GetService("HttpService")
local Config = {}

local data = {
    killSounds = {},
    deathSounds = {},
    music = {},
    images = {},
    selectedKillSound = "",
    selectedDeathSound = "",
    selectedMusic = "",
    selectedBackground = "",
    musicVolume = 0.5,
    musicPlaying = false,
}

for k, v in pairs(DEFAULT_KILL) do data.killSounds[k] = v end
for k, v in pairs(DEFAULT_DEATH) do data.deathSounds[k] = v end
for k, v in pairs(DEFAULT_MUSIC) do data.music[k] = v end
for k, v in pairs(DEFAULT_IMAGES) do data.images[k] = v end

local SAVE_FILE = "LarpSec_save.json"

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local n = {}
    for k, v in pairs(t) do
        n[k] = deepCopy(v)
    end
    return n
end

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
        -- ImageLabel accepts rbxassetid; also keep raw for rbxthumb fallback
        return "rbxassetid://" .. num, num
    end
    if not s:find("rbxassetid") then
        return "rbxassetid://" .. num
    end
    return s
end

function Config.ResolveImage(id)
    local full, num = Config.NormalizeAssetId(id, "image")
    if not full then return "" end
    -- primary
    return full
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
        version = 1,
        killSounds = data.killSounds,
        deathSounds = data.deathSounds,
        music = data.music,
        images = data.images,
        selectedKillSound = data.selectedKillSound,
        selectedDeathSound = data.selectedDeathSound,
        selectedMusic = data.selectedMusic,
        selectedBackground = data.selectedBackground,
        musicVolume = data.musicVolume,
        features = extra or {},
    }
    -- serialize colors in features
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
    local ok, err = pcall(function()
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
    if type(packet.killSounds) == "table" then data.killSounds = packet.killSounds end
    if type(packet.deathSounds) == "table" then data.deathSounds = packet.deathSounds end
    if type(packet.music) == "table" then data.music = packet.music end
    if type(packet.images) == "table" then data.images = packet.images end
    data.selectedKillSound = packet.selectedKillSound or data.selectedKillSound
    data.selectedDeathSound = packet.selectedDeathSound or data.selectedDeathSound
    data.selectedMusic = packet.selectedMusic or data.selectedMusic
    data.selectedBackground = packet.selectedBackground or data.selectedBackground
    data.musicVolume = packet.musicVolume or data.musicVolume
    -- restore colors
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
    -- no-op for compat; use SaveFile
end

return Config
