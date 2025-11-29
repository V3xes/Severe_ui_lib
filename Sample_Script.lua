local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/V3xes/Severe_ui_lib/refs/heads/main/Librarycode"))()

-- Or if the library is in the same script, just use it directly:
-- local Library = require(script.Library)

-- Create the main window
local Window = Library:Create({
    Name = "Project Chimera",
    AccentColor = Color3.fromRGB(0, 200, 100),
    ToggleKey = 0x2D -- Insert key
})

-- Create tabs
local CombatTab = Window:Tab({ Name = "Combat" })
local VisualsTab = Window:Tab({ Name = "Visuals" })
local SettingsTab = Window:Tab({ Name = "Settings" })

-- COMBAT TAB
local AimbotToggle = CombatTab:Toggle({
    Name = "Enable Aimbot",
    Default = false,
    Callback = function(value)
        send_notification("Aimbot:", value)
    end
})

local FOVSlider = CombatTab:Slider({
    Name = "FOV Radius",
    Min = 10,
    Max = 500,
    Default = 120,
    Callback = function(value)
        send_notification("FOV:", value)
    end
})

local TargetDropdown = CombatTab:Dropdown({
    Name = "Target Part",
    Options = {"Head", "Torso", "Legs"},
    Default = 1,
    Callback = function(value)
        send_notification("Target:", value)
    end
})

-- VISUALS TAB
local ESPToggle = VisualsTab:Toggle({
    Name = "Enable ESP",
    Default = true,
    Callback = function(value)
        send_notification("ESP:", value)
    end
})

local BoxToggle = VisualsTab:Toggle({
    Name = "Draw Boxes",
    Default = true,
    Callback = function(value)
        send_notification("Boxes:", value)
    end
})

local ESPColor = VisualsTab:ColorPicker({
    Name = "ESP Color",
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        send_notification("Color:", color.R, color.G, color.B)
    end
})

local RarityFilter = VisualsTab:MultiSelect({
    Name = "Rarity Filter",
    Options = {"Common", "Rare", "Epic", "Legendary"},
    Callback = function(selected)
        send_notification("Selected rarities:")
        for _, v in ipairs(selected) do
            send_notification("  -", v)
        end
    end
})

-- SETTINGS TAB
local SmoothSlider = SettingsTab:Slider({
    Name = "Smoothness",
    Min = 1,
    Max = 20,
    Default = 5,
    Callback = function(value)
        send_notification("Smooth:", value)
    end
})

local ThemeDropdown = SettingsTab:Dropdown({
    Name = "Theme",
    Options = {"Dark", "Light", "Blue"},
    Default = 1,
    Callback = function(value)
        send_notification("Theme:", value)
    end
})

-- Example: Getting and setting values after creation
task.wait(3)
send_notification("Current Aimbot state:", AimbotToggle:GetValue())
send_notification("Current FOV:", FOVSlider:GetValue())
send_notification("Current Target:", TargetDropdown:GetValue())
send_notification("Current ESP Color:", ESPColor:GetValue())
send_notification("Selected Rarities:", RarityFilter:GetSelected())

-- Example: Changing values programmatically
AimbotToggle:SetValue(true)
FOVSlider:SetValue(200)
RarityFilter:SetSelected({"Rare", "Legendary"})

send_notification("Window loaded! Press Insert to toggle visibility.")
