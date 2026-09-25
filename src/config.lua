--[[
    LarpSec · Config
    ONLY edit the table below.
]]

-- ========== EDIT THIS ==========
local SOUNDS = {
    ["uwu"] = "rbxassetid://139219844119994",
    ["oof"] = "rbxassetid://139019913635357",
    ["mm2"] = "rbxassetid://137392628136734",
    ["nani?!"] = "rbxassetid://77547270929945",
    ["fart"] = "rbxassetid://138132180123464",
    -- ["Cracked"] = "rbxassetid://123456789",
    -- ["Boom"]    = "rbxassetid://987654321",
}

local SELECTED = "" -- name from above, or "" for Off
-- ========== END EDIT ==========

local Config = {}
local data = {
    killSounds = SOUNDS,
    selectedKillSound = SELECTED,
}

function Config.Load()
    return data
end

function Config.Save()
end

function Config.Get()
    return data
end

function Config.GetKillSoundNames()
    local names = { "Off" }
    for name in pairs(data.killSounds) do
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
end

return Config
