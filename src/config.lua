--[[
    LarpSec · User Config (sounds etc.)
    Owned by you — script updates never overwrite these IDs.

    Load order:
      1. getgenv().LarpSecUserConfig  (set in autoexec if you want)
      2. readfile("LarpSec_config.json") if available
      3. empty defaults

    Example JSON:
    {
      "killSounds": {
        "Cracked": "rbxassetid://123456789",
        "Boom": "rbxassetid://987654321"
      },
      "selectedKillSound": "Cracked"
    }

    Or in autoexec before loader:
    getgenv().LarpSecUserConfig = {
      killSounds = { Cracked = "rbxassetid://123456789" },
      selectedKillSound = "Cracked",
    }
]]

local Config = {}

local defaults = {
    killSounds = {}, -- name -> asset id string
    selectedKillSound = "", -- name key, "" = off
}

local function deepCopy(t)
    local n = {}
    for k, v in pairs(t) do
        if type(v) == "table" then n[k] = deepCopy(v) else n[k] = v end
    end
    return n
end

local data = deepCopy(defaults)

local function merge(dst, src)
    if type(src) ~= "table" then return end
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
            merge(dst[k], v)
        else
            dst[k] = v
        end
    end
end

function Config.Load()
    data = deepCopy(defaults)
    pcall(function()
        local g = getgenv and getgenv() or _G
        if type(g.LarpSecUserConfig) == "table" then
            merge(data, g.LarpSecUserConfig)
        end
    end)
    pcall(function()
        if isfile and isfile("LarpSec_config.json") and readfile and game.HttpService then
            local raw = readfile("LarpSec_config.json")
            local decoded = game:GetService("HttpService"):JSONDecode(raw)
            if type(decoded) == "table" then merge(data, decoded) end
        end
    end)
    return data
end

function Config.Save()
    pcall(function()
        local g = getgenv and getgenv() or _G
        g.LarpSecUserConfig = data
    end)
    pcall(function()
        if writefile and game.HttpService then
            writefile("LarpSec_config.json", game:GetService("HttpService"):JSONEncode(data))
        end
    end)
end

function Config.Get()
    return data
end

function Config.GetKillSoundNames()
    local names = { "Off" }
    for name in pairs(data.killSounds or {}) do
        table.insert(names, name)
    end
    table.sort(names, function(a, b)
        if a == "Off" then return true end
        if b == "Off" then return false end
        return a:lower() < b:lower()
    end)
    return names
end

function Config.GetSelectedKillSoundId()
    local sel = data.selectedKillSound
    if not sel or sel == "" or sel == "Off" then return nil end
    return data.killSounds[sel]
end

function Config.SetSelectedKillSound(name)
    if name == "Off" or name == nil or name == "" then
        data.selectedKillSound = ""
    else
        data.selectedKillSound = name
    end
    Config.Save()
end

Config.Load()
return Config
