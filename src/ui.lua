--[[
    Flick · UI wired to Library (Linoria-style)
]]

local UI = {}

function UI.Init(Silent, ESP, Anti, Perf)
    local Library = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/K01dBy4spam935h/Flick_LarpSec/main/src/library.lua"
    ))()

    local Lib = Library.new({
        Title = "Flick · LarpSec",
        ToggleKey = Enum.KeyCode.RightShift,
    })

    local Window = Lib:CreateWindow({
        Title = "Flick · LarpSec",
        Size = Vector2.new(560, 460),
    })

    -- ── Combat ──────────────────────────────────────────────
    local TabCombat = Window:CreateTab("Combat")
    local GBSilent = TabCombat:CreateGroupbox("Silent Aim", "Left")
    local GBSilentR = TabCombat:CreateGroupbox("Targeting", "Right")

    GBSilent:AddToggle({
        Text = "Enabled",
        Default = Silent.Config.Enabled,
        Callback = function(v) Silent.Config.Enabled = v end,
    })
    GBSilent:AddSlider({
        Text = "FOV",
        Min = 20, Max = 400, Default = Silent.Config.FOV,
        Callback = function(v) Silent.Config.FOV = v end,
    })
    GBSilent:AddSlider({
        Text = "Hit Chance",
        Min = 1, Max = 100, Default = Silent.Config.HitChance,
        Suffix = "%",
        Callback = function(v) Silent.Config.HitChance = v end,
    })
    GBSilent:AddToggle({
        Text = "Show FOV",
        Default = Silent.Config.ShowFOV,
        Callback = function(v) Silent.Config.ShowFOV = v end,
    })

    GBSilentR:AddDropdown({
        Text = "Hit Part",
        Values = {"Torso", "Head", "HumanoidRootPart", "UpperTorso"},
        Default = "Torso",
        Callback = function(v)
            if v == "Torso" then
                Silent.Config.HitPart = "UpperTorso"
                Silent.Config.PreferTorso = true
            else
                Silent.Config.HitPart = v
                Silent.Config.PreferTorso = false
            end
        end,
    })
    GBSilentR:AddToggle({
        Text = "Visible Check",
        Default = Silent.Config.VisibleCheck,
        Callback = function(v) Silent.Config.VisibleCheck = v end,
    })
    GBSilentR:AddToggle({
        Text = "Sticky Aim",
        Default = Silent.Config.Sticky,
        Callback = function(v) Silent.Config.Sticky = v end,
    })
    GBSilentR:AddLabel("Torso = largest one-shot hitbox")
    GBSilentR:AddLabel("Falls back to any body part")

    -- ── Visuals ─────────────────────────────────────────────
    local TabVisuals = Window:CreateTab("Visuals")
    local GBPerf = TabVisuals:CreateGroupbox("Performance", "Left")
    local GBOverlay = TabVisuals:CreateGroupbox("Overlay", "Right")

    GBPerf:AddToggle({
        Text = "Performance Mode",
        Default = Perf.Config.Enabled,
        Callback = function(v) Perf.SetEnabled(v) end,
    })
    GBPerf:AddLabel("Lowers quality, shadows, particles")
    GBPerf:AddLabel("Reversible · does not break gameplay")

    GBOverlay:AddToggle({
        Text = "FPS / Ping Counter",
        Default = Perf.Config.ShowFPS,
        Callback = function(v) Perf.Config.ShowFPS = v end,
    })
    GBOverlay:AddLabel("Drag the counter freely")

    -- ── ESP ─────────────────────────────────────────────────
    local TabESP = Window:CreateTab("ESP")
    local GBESP = TabESP:CreateGroupbox("ESP", "Left")
    local GBESPStyle = TabESP:CreateGroupbox("Style", "Right")

    GBESP:AddToggle({
        Text = "Enabled",
        Default = ESP.Config.Enabled,
        Callback = function(v) ESP.Config.Enabled = v end,
    })
    GBESP:AddToggle({
        Text = "Boxes",
        Default = ESP.Config.Boxes,
        Callback = function(v) ESP.Config.Boxes = v end,
    })
    GBESP:AddToggle({
        Text = "Names",
        Default = ESP.Config.Names,
        Callback = function(v) ESP.Config.Names = v end,
    })
    GBESP:AddToggle({
        Text = "Distance",
        Default = ESP.Config.Distance,
        Callback = function(v) ESP.Config.Distance = v end,
    })
    GBESP:AddToggle({
        Text = "Tracers",
        Default = ESP.Config.Tracers,
        Callback = function(v) ESP.Config.Tracers = v end,
    })

    GBESPStyle:AddDropdown({
        Text = "Tracer Origin",
        Values = {"Bottom", "Center", "Mouse"},
        Default = ESP.Config.TracerFrom,
        Callback = function(v) ESP.Config.TracerFrom = v end,
    })
    GBESPStyle:AddSlider({
        Text = "Max Distance",
        Min = 100, Max = 2000, Default = ESP.Config.MaxDistance,
        Suffix = "m",
        Callback = function(v) ESP.Config.MaxDistance = v end,
    })
    GBESPStyle:AddDropdown({
        Text = "Color",
        Values = {"Purple", "Cyan", "Red", "Green", "White", "Orange", "Blue"},
        Default = "Blue",
        Callback = function(name)
            local map = {
                Purple = Color3.fromRGB(120, 90, 255),
                Cyan   = Color3.fromRGB(80, 200, 255),
                Red    = Color3.fromRGB(255, 70, 70),
                Green  = Color3.fromRGB(80, 255, 140),
                White  = Color3.fromRGB(240, 240, 245),
                Orange = Color3.fromRGB(255, 160, 60),
                Blue   = Color3.fromRGB(74, 144, 226),
            }
            local c = map[name] or map.Blue
            ESP.Config.Color = c
            Silent.Config.FOVColor = c
        end,
    })

    -- ── Misc ────────────────────────────────────────────────
    local TabMisc = Window:CreateTab("Misc")
    local GBAnti = TabMisc:CreateGroupbox("Anti-Cheat", "Left")
    local GBInfo = TabMisc:CreateGroupbox("Info", "Right")

    GBAnti:AddLabel("Adonis Detected / Kill neutered")
    GBAnti:AddLabel("indexInstance / namecall neutered")
    GBAnti:AddLabel("Heartbeat preserved")
    GBAnti:AddLabel("Kick swallow active")
    GBAnti:AddLabel("Watchdog every 4s")

    GBInfo:AddLabel("RightShift · toggle menu")
    GBInfo:AddLabel("Drag from title bar only")
    GBInfo:AddLabel("Torso priority · one-shot")

    -- show window
    Window.Frame.Visible = true
end

return UI
