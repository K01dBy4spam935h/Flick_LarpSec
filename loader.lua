--[[
    Flick Silent · GitHub Loadstring Template
    Replace YOUR_USER / YOUR_REPO with your actual GitHub path
    Then execute this one-liner in any executor:

        loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/loader.lua"))()
]]

-- ═══════════════════════════════════════════════════════════
--  CONFIG — change these two lines only
-- ═══════════════════════════════════════════════════════════
local GITHUB_USER = "K01dBy4spam935h"
local GITHUB_REPO = "Flick_LarpSec"
local BRANCH      = "main"
-- ═══════════════════════════════════════════════════════════

local BASE = ("https://raw.githubusercontent.com/%s/%s/%s/src/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local function fetch(name)
    local url = BASE .. name
    local src = game:HttpGet(url)
    return loadstring(src)()
end

-- 1. Anti first
local Anti = fetch("anti.lua")
Anti.Init()
task.wait(0.4)

-- 2. Modules
local Silent = fetch("silent.lua")
local ESP    = fetch("esp.lua")
local UI     = fetch("ui.lua")

-- 3. Boot
task.spawn(function()
    task.wait(1.2)
    Silent.Init()
end)
ESP.Init()
UI.Init(Silent, ESP)

print("[Flick] loaded from GitHub · " .. GITHUB_USER .. "/" .. GITHUB_REPO)
