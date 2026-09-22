--[[
    Flick LarpSec · loader
    set your github user/repo below, then:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/REPO/main/loader.lua"))()
]]

local GITHUB_USER = "K01dBy4spam935h"
local GITHUB_REPO = "Flick_LarpSec"
local BRANCH      = "main"

local BASE = ("https://raw.githubusercontent.com/%s/%s/%s/src/"):format(GITHUB_USER, GITHUB_REPO, BRANCH)

local function fetch(name)
    return loadstring(game:HttpGet(BASE .. name))()
end

local Anti   = fetch("anti.lua")
Anti.Init()
task.wait(0.35)

local Silent = fetch("silent.lua")
local ESP    = fetch("esp.lua")
local UI     = fetch("ui.lua")

task.spawn(function()
    task.wait(1.1)
    Silent.Init()
end)
ESP.Init()
UI.Init(Silent, ESP, Anti)
