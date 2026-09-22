--[[
    Flick Silent Aim + ESP + Anti-Adonis
    Entry point · load order is critical
]]

-- 1. Anti first (must run before anything Adonis can flag)
local Anti = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/src/anti.lua"))()
Anti.Init()

-- small delay so first neuter settles
task.wait(0.4)

-- 2. Feature modules
local Silent = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/src/silent.lua"))()
local ESP    = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/src/esp.lua"))()
local UI     = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/src/ui.lua"))()

-- 3. Init features
task.spawn(function()
    task.wait(1.2) -- let gun modules exist
    Silent.Init()
end)

ESP.Init()
UI.Init(Silent, ESP)

print("[Flick] full stack loaded · anti + silent + esp + ui")
