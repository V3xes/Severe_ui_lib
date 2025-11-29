local Library = {}
Library.__index = Library

local DrawingObjects = {}
local Notifications = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CONFIG = {
    TOGGLE_KEY = 0x2D,
    
    WINDOW = {
        X = 300,
        Y = 200,
        WIDTH = 500,
        HEIGHT = 400,
        MIN_WIDTH = 400,
        MIN_HEIGHT = 300,
        SIDEBAR_WIDTH = 140,
        TITLE_HEIGHT = 30,
        TAB_HEIGHT = 30,
        SCALE_MARGIN = 15
    },
    
    COLORS = {
        TITLE = Color3.fromRGB(0, 88, 238),
        TITLE_HIGH = Color3.fromRGB(60, 160, 255),
        BODY = Color3.fromRGB(240, 240, 245),
        SIDEBAR = Color3.fromRGB(225, 225, 230),
        BORDER = Color3.fromRGB(0, 50, 150),
        SHADOW = Color3.fromRGB(0, 0, 0),
        TEXT = Color3.fromRGB(50, 50, 50),
        TEXT_DARK = Color3.fromRGB(30, 30, 30),
        TEXT_LIGHT = Color3.fromRGB(150, 150, 150),
        ACCENT = Color3.fromRGB(0, 200, 100),
        WHITE = Color3.fromRGB(255, 255, 255),
        TOGGLE_OFF = Color3.fromRGB(180, 180, 180),
        SLIDER_BG = Color3.fromRGB(200, 200, 200),
        DROPDOWN_BG = Color3.fromRGB(255, 255, 255),
        DROPDOWN_HOVER = Color3.fromRGB(220, 230, 255),
        BUTTON_BG = Color3.fromRGB(220, 220, 225),
        BUTTON_HOVER = Color3.fromRGB(200, 200, 210),
        INPUT_BG = Color3.fromRGB(255, 255, 255),
        SEPARATOR = Color3.fromRGB(200, 200, 200),
        NOTIFICATION_BG = Color3.fromRGB(40, 40, 45),
        NOTIFICATION_SUCCESS = Color3.fromRGB(0, 200, 100),
        NOTIFICATION_ERROR = Color3.fromRGB(255, 80, 80),
        NOTIFICATION_INFO = Color3.fromRGB(0, 150, 255),
        NOTIFICATION_WARNING = Color3.fromRGB(255, 180, 0)
    },
    
    LAYOUT = {
        CONTENT_PADDING = 15,
        ITEM_HEIGHT = 25,
        ITEM_SPACING = 10,
        TOGGLE_WIDTH = 40,
        TOGGLE_HEIGHT = 14,
        SLIDER_HEIGHT = 6,
        DROPDOWN_HEIGHT = 25,
        DROPDOWN_ITEM_HEIGHT = 22,
        CHECKBOX_SIZE = 12,
        COLOR_PREVIEW_SIZE = 30,
        COLOR_PICKER_SIZE = 120,
        HUE_BAR_WIDTH = 20,
        BUTTON_HEIGHT = 28,
        INPUT_HEIGHT = 25,
        KEYBIND_WIDTH = 80,
        NOTIFICATION_WIDTH = 250,
        NOTIFICATION_HEIGHT = 60,
        NOTIFICATION_SPACING = 10
    },
    
    TEXT_SIZE = {
        TITLE = 16,
        TAB = 14,
        LABEL = 14,
        VALUE = 12,
        SMALL = 10,
        NOTIFICATION = 13
    },
    
    ZINDEX = {
        SHADOW = 0,
        BORDER = 1,
        BODY = 2,
        SIDEBAR = 3,
        TITLE = 4,
        CONTENT = 5,
        COMPONENT = 10,
        DROPDOWN = 50,
        PICKER = 60,
        NOTIFICATION = 100
    }
}

local Window = {
    pos = Vector2.new(CONFIG.WINDOW.X, CONFIG.WINDOW.Y),
    size = Vector2.new(CONFIG.WINDOW.WIDTH, CONFIG.WINDOW.HEIGHT),
    minimized = false,
    dragging = false,
    scaling = false,
    dragOffset = Vector2.new(0, 0),
    visible = true
}

local ActiveDropdown = nil
local ActivePicker = nil
local ActiveKeybind = nil
local ActiveInput = nil

local function vec(x, y) return Vector2.new(x, y) end
local function mousePos() return getmouseposition() end
local function mouseDown() return isleftpressed() end

local function isInside(pos, size, point)
    return point.X >= pos.X and point.X <= pos.X + size.X
       and point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

local function hsvToRgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return Color3.fromRGB(r * 255, g * 255, b * 255)
end

local function keyCodeToString(keyCode)
    local name = tostring(keyCode)
    if string.find(name, "Enum.KeyCode.") then
        return string.gsub(name, "Enum.KeyCode.", "")
    end
    return name
end

local function createDrawing(drawingType, properties)
    local obj = Drawing.new(drawingType)
    for k, v in pairs(properties or {}) do
        obj[k] = v
    end
    obj.Visible = false
    table.insert(DrawingObjects, obj)
    return obj
end

local function makeSquare(color, size, pos, filled, opacity, z)
    return createDrawing("Square", {
        Color = color,
        Size = size,
        Position = pos,
        Filled = filled,
        Transparency = opacity or 1,
        Thickness = 1,
        ZIndex = z or 1
    })
end

local function makeLine(color, from, to, thick, z)
    return createDrawing("Line", {
        Color = color,
        From = from,
        To = to,
        Thickness = thick or 1,
        ZIndex = z or 1
    })
end

local function makeText(text, size, pos, color, z)
    return createDrawing("Text", {
        Text = text,
        Size = size,
        Position = pos,
        Color = color,
        Center = false,
        Outline = true,
        OutlineColor = CONFIG.COLORS.WHITE,
        ZIndex = z or 5
    })
end

local function makeCircle(color, radius, pos, filled, z)
    return createDrawing("Circle", {
        Color = color,
        Radius = radius,
        Position = pos,
        Filled = filled,
        Thickness = 1,
        ZIndex = z or 1
    })
end

-- COMPONENT: Toggle
local Toggle = {}
Toggle.__index = Toggle

function Toggle.new(options, accentColor)
    local self = setmetatable({}, Toggle)
    self.name = options.Name or "Toggle"
    self.value = options.Default or false
    self.callback = options.Callback
    self.accent = accentColor or CONFIG.COLORS.ACCENT
    self.tooltip = options.Tooltip
    
    self.boxOut = makeSquare(CONFIG.COLORS.BORDER, vec(CONFIG.LAYOUT.TOGGLE_WIDTH, CONFIG.LAYOUT.TOGGLE_HEIGHT), vec(0,0), false, 1, CONFIG.ZINDEX.COMPONENT)
    self.boxFill = makeSquare(self.accent, vec(CONFIG.LAYOUT.TOGGLE_WIDTH - 4, CONFIG.LAYOUT.TOGGLE_HEIGHT - 4), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT + 1)
    self.label = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    
    return self
end

function Toggle:Update(x, y)
    self.boxOut.Position = vec(x, y)
    self.boxFill.Position = vec(x + 2, y + 2)
    self.boxFill.Visible = self.value and Window.visible
    self.label.Position = vec(x + CONFIG.LAYOUT.TOGGLE_WIDTH + 10, y - 2)
end

function Toggle:HandleClick(mx, my)
    if isInside(self.boxOut.Position, vec(200, 20), vec(mx, my)) then
        self.value = not self.value
        if self.callback then self.callback(self.value) end
        return true
    end
    return false
end

function Toggle:SetVisible(visible)
    self.boxOut.Visible = visible and Window.visible
    self.boxFill.Visible = visible and Window.visible and self.value
    self.label.Visible = visible and Window.visible
end

function Toggle:GetValue() return self.value end
function Toggle:SetValue(v) self.value = v; if self.callback then self.callback(v) end end

-- COMPONENT: Slider
local Slider = {}
Slider.__index = Slider

function Slider.new(options, accentColor)
    local self = setmetatable({}, Slider)
    self.name = options.Name or "Slider"
    self.min = options.Min or 0
    self.max = options.Max or 100
    self.value = options.Default or 50
    self.increment = options.Increment or 1
    self.suffix = options.Suffix or ""
    self.callback = options.Callback
    self.accent = accentColor or CONFIG.COLORS.TITLE
    self.dragging = false
    self.width = 150
    
    self.label = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    self.bg = makeSquare(CONFIG.COLORS.SLIDER_BG, vec(self.width, CONFIG.LAYOUT.SLIDER_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT)
    self.fill = makeSquare(self.accent, vec(0, CONFIG.LAYOUT.SLIDER_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT + 1)
    self.knob = makeSquare(CONFIG.COLORS.WHITE, vec(6, 14), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT + 2)
    self.valueText = makeText("0", CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.valueText.Outline = false
    
    return self
end

function Slider:Update(x, y)
    self.label.Position = vec(x, y)
    self.bg.Position = vec(x, y + 20)
    
    local percent = (self.value - self.min) / (self.max - self.min)
    local fillW = self.width * percent
    
    self.fill.Position = vec(x, y + 20)
    self.fill.Size = vec(fillW, CONFIG.LAYOUT.SLIDER_HEIGHT)
    self.knob.Position = vec(x + fillW - 3, y + 16)
    
    local displayVal = math.floor(self.value / self.increment) * self.increment
    self.valueText.Text = tostring(displayVal) .. self.suffix
    self.valueText.Position = vec(x + self.width + 10, y + 16)
end

function Slider:HandleDrag(mx, my)
    if self.dragging then
        local percent = math.clamp((mx - self.bg.Position.X) / self.width, 0, 1)
        local rawValue = self.min + (self.max - self.min) * percent
        self.value = math.floor(rawValue / self.increment) * self.increment
        if self.callback then self.callback(self.value) end
        return true
    end
    return false
end

function Slider:StartDrag(mx, my)
    if isInside(self.bg.Position - vec(5, 5), vec(self.width + 10, 16), vec(mx, my)) then
        self.dragging = true
        return true
    end
    return false
end

function Slider:StopDrag() self.dragging = false end

function Slider:SetVisible(visible)
    self.label.Visible = visible and Window.visible
    self.bg.Visible = visible and Window.visible
    self.fill.Visible = visible and Window.visible
    self.knob.Visible = visible and Window.visible
    self.valueText.Visible = visible and Window.visible
end

function Slider:GetValue() return self.value end
function Slider:SetValue(v) self.value = math.clamp(v, self.min, self.max); if self.callback then self.callback(self.value) end end

-- COMPONENT: Dropdown
local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(options, accentColor)
    local self = setmetatable({}, Dropdown)
    self.name = options.Name or "Dropdown"
    self.options = options.Options or {}
    self.selected = options.Default or 1
    self.callback = options.Callback
    self.accent = accentColor or CONFIG.COLORS.TITLE
    self.isOpen = false
    self.width = 150
    
    self.label = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    self.box = makeSquare(CONFIG.COLORS.DROPDOWN_BG, vec(self.width, CONFIG.LAYOUT.DROPDOWN_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT)
    self.boxBorder = makeSquare(CONFIG.COLORS.BORDER, vec(self.width, CONFIG.LAYOUT.DROPDOWN_HEIGHT), vec(0,0), false, 1, CONFIG.ZINDEX.COMPONENT + 1)
    self.text = makeText("", CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT + 2)
    self.text.Outline = false
    self.arrow = makeText("v", CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT + 2)
    self.arrow.Outline = false
    
    self.items = {}
    for i, opt in ipairs(self.options) do
        self.items[i] = {
            bg = makeSquare(CONFIG.COLORS.DROPDOWN_BG, vec(self.width, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.DROPDOWN),
            hoverBg = makeSquare(CONFIG.COLORS.DROPDOWN_HOVER, vec(self.width, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.DROPDOWN),
            text = makeText(opt, CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.DROPDOWN + 1)
        }
        self.items[i].text.Outline = false
    end
    
    return self
end

function Dropdown:Update(x, y)
    self.label.Position = vec(x, y)
    self.box.Position = vec(x, y + 20)
    self.boxBorder.Position = vec(x, y + 20)
    self.text.Text = self.options[self.selected] or ""
    self.text.Position = vec(x + 5, y + 25)
    self.arrow.Position = vec(x + self.width - 15, y + 25)
    
    for i, item in ipairs(self.items) do
        local itemY = y + 20 + (i * CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT)
        item.bg.Position = vec(x, itemY)
        item.hoverBg.Position = vec(x, itemY)
        item.text.Position = vec(x + 5, itemY + 4)
        
        if self.isOpen then
            local mp = mousePos()
            local hovered = isInside(vec(x, itemY), vec(self.width, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT), mp)
            item.hoverBg.Visible = hovered and Window.visible
            item.bg.Visible = not hovered and Window.visible
            item.text.Visible = Window.visible
        else
            item.bg.Visible = false
            item.hoverBg.Visible = false
            item.text.Visible = false
        end
    end
end

function Dropdown:HandleClick(mx, my)
    if isInside(self.box.Position, vec(self.width, CONFIG.LAYOUT.DROPDOWN_HEIGHT), vec(mx, my)) then
        self.isOpen = not self.isOpen
        if self.isOpen then
            if ActiveDropdown and ActiveDropdown ~= self then ActiveDropdown.isOpen = false end
            ActiveDropdown = self
        else
            ActiveDropdown = nil
        end
        return true
    end
    
    if self.isOpen then
        for i, item in ipairs(self.items) do
            local itemY = self.box.Position.Y + (i * CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT)
            if isInside(vec(self.box.Position.X, itemY), vec(self.width, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT), vec(mx, my)) then
                self.selected = i
                self.isOpen = false
                ActiveDropdown = nil
                if self.callback then self.callback(self.options[i]) end
                return true
            end
        end
    end
    return false
end

function Dropdown:SetVisible(visible)
    self.label.Visible = visible and Window.visible
    self.box.Visible = visible and Window.visible
    self.boxBorder.Visible = visible and Window.visible
    self.text.Visible = visible and Window.visible
    self.arrow.Visible = visible and Window.visible
    if not visible then
        for _, item in ipairs(self.items) do
            item.bg.Visible = false
            item.hoverBg.Visible = false
            item.text.Visible = false
        end
    end
end

function Dropdown:GetValue() return self.options[self.selected] end
function Dropdown:SetValue(v) for i, opt in ipairs(self.options) do if opt == v then self.selected = i; break end end end
function Dropdown:Refresh(newOptions) 
    self.options = newOptions 
    self.selected = 1
    for i, item in ipairs(self.items) do
        item.text.Text = newOptions[i] or ""
    end
end

-- COMPONENT: MultiSelect
local MultiSelect = {}
MultiSelect.__index = MultiSelect

function MultiSelect.new(options, accentColor)
    local self = setmetatable({}, MultiSelect)
    self.name = options.Name or "Multi Select"
    self.options = options.Options or {}
    self.values = {}
    self.callback = options.Callback
    self.accent = accentColor or CONFIG.COLORS.ACCENT
    self.isOpen = false
    self.width = 150
    
    for _, opt in ipairs(self.options) do self.values[opt] = false end
    if options.Default then
        for _, v in ipairs(options.Default) do self.values[v] = true end
    end
    
    self.label = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    self.box = makeSquare(CONFIG.COLORS.DROPDOWN_BG, vec(self.width, CONFIG.LAYOUT.DROPDOWN_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT)
    self.boxBorder = makeSquare(CONFIG.COLORS.BORDER, vec(self.width, CONFIG.LAYOUT.DROPDOWN_HEIGHT), vec(0,0), false, 1, CONFIG.ZINDEX.COMPONENT + 1)
    self.text = makeText("Select...", CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT + 2)
    self.text.Outline = false
    self.arrow = makeText("v", CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT + 2)
    self.arrow.Outline = false
    
    self.items = {}
    for i, opt in ipairs(self.options) do
        self.items[i] = {
            name = opt,
            bg = makeSquare(CONFIG.COLORS.DROPDOWN_BG, vec(self.width, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.DROPDOWN),
            hoverBg = makeSquare(CONFIG.COLORS.DROPDOWN_HOVER, vec(self.width, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.DROPDOWN),
            checkBox = makeSquare(CONFIG.COLORS.BORDER, vec(CONFIG.LAYOUT.CHECKBOX_SIZE, CONFIG.LAYOUT.CHECKBOX_SIZE), vec(0,0), false, 1, CONFIG.ZINDEX.DROPDOWN + 1),
            checkFill = makeSquare(self.accent, vec(CONFIG.LAYOUT.CHECKBOX_SIZE - 4, CONFIG.LAYOUT.CHECKBOX_SIZE - 4), vec(0,0), true, 1, CONFIG.ZINDEX.DROPDOWN + 2),
            text = makeText(opt, CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.DROPDOWN + 1)
        }
        self.items[i].text.Outline = false
    end
    
    return self
end

function MultiSelect:Update(x, y)
    self.label.Position = vec(x, y)
    self.box.Position = vec(x, y + 20)
    self.boxBorder.Position = vec(x, y + 20)
    self.arrow.Position = vec(x + self.width - 15, y + 25)
    
    local count = 0
    for _, v in pairs(self.values) do if v then count = count + 1 end end
    self.text.Text = count > 0 and (count .. " selected") or "Select..."
    self.text.Position = vec(x + 5, y + 25)
    
    for i, item in ipairs(self.items) do
        local itemY = y + 20 + (i * CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT)
        item.bg.Position = vec(x, itemY)
        item.hoverBg.Position = vec(x, itemY)
        item.checkBox.Position = vec(x + 5, itemY + 5)
        item.checkFill.Position = vec(x + 7, itemY + 7)
        item.text.Position = vec(x + 22, itemY + 4)
        
        if self.isOpen then
            local mp = mousePos()
            local hovered = isInside(vec(x, itemY), vec(self.width, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT), mp)
            item.hoverBg.Visible = hovered and Window.visible
            item.bg.Visible = not hovered and Window.visible
            item.checkBox.Visible = Window.visible
            item.checkFill.Visible = self.values[item.name] and Window.visible
            item.text.Visible = Window.visible
        else
            item.bg.Visible = false
            item.hoverBg.Visible = false
            item.checkBox.Visible = false
            item.checkFill.Visible = false
            item.text.Visible = false
        end
    end
end

function MultiSelect:HandleClick(mx, my)
    if isInside(self.box.Position, vec(self.width, CONFIG.LAYOUT.DROPDOWN_HEIGHT), vec(mx, my)) then
        self.isOpen = not self.isOpen
        if self.isOpen then
            if ActiveDropdown and ActiveDropdown ~= self then ActiveDropdown.isOpen = false end
            ActiveDropdown = self
        else
            ActiveDropdown = nil
        end
        return true
    end
    
    if self.isOpen then
        for i, item in ipairs(self.items) do
            local itemY = self.box.Position.Y + (i * CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT)
            if isInside(vec(self.box.Position.X, itemY), vec(self.width, CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT), vec(mx, my)) then
                self.values[item.name] = not self.values[item.name]
                if self.callback then self.callback(self:GetSelected()) end
                return true
            end
        end
    end
    return false
end

function MultiSelect:SetVisible(visible)
    self.label.Visible = visible and Window.visible
    self.box.Visible = visible and Window.visible
    self.boxBorder.Visible = visible and Window.visible
    self.text.Visible = visible and Window.visible
    self.arrow.Visible = visible and Window.visible
    if not visible then
        for _, item in ipairs(self.items) do
            item.bg.Visible = false
            item.hoverBg.Visible = false
            item.checkBox.Visible = false
            item.checkFill.Visible = false
            item.text.Visible = false
        end
    end
end

function MultiSelect:GetSelected()
    local result = {}
    for k, v in pairs(self.values) do if v then table.insert(result, k) end end
    return result
end

function MultiSelect:SetSelected(vals)
    for k in pairs(self.values) do self.values[k] = false end
    for _, v in ipairs(vals or {}) do self.values[v] = true end
end

-- COMPONENT: ColorPicker
local ColorPicker = {}
ColorPicker.__index = ColorPicker

function ColorPicker.new(options, accentColor)
    local self = setmetatable({}, ColorPicker)
    self.name = options.Name or "Color"
    self.value = options.Default or Color3.fromRGB(255, 0, 0)
    self.callback = options.Callback
    self.isOpen = false
    self.hue = 0
    self.sat = 1
    self.val = 1
    self.draggingHue = false
    self.draggingSV = false
    
    self.label = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    self.preview = makeSquare(self.value, vec(CONFIG.LAYOUT.COLOR_PREVIEW_SIZE, CONFIG.LAYOUT.COLOR_PREVIEW_SIZE), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT)
    self.previewBorder = makeSquare(CONFIG.COLORS.BORDER, vec(CONFIG.LAYOUT.COLOR_PREVIEW_SIZE, CONFIG.LAYOUT.COLOR_PREVIEW_SIZE), vec(0,0), false, 1, CONFIG.ZINDEX.COMPONENT + 1)
    
    self.pickerBg = makeSquare(CONFIG.COLORS.BODY, vec(200, 180), vec(0,0), true, 1, CONFIG.ZINDEX.PICKER)
    self.pickerBorder = makeSquare(CONFIG.COLORS.BORDER, vec(200, 180), vec(0,0), false, 1, CONFIG.ZINDEX.PICKER + 1)
    
    local size = CONFIG.LAYOUT.COLOR_PICKER_SIZE
    local res = 10
    self.svSquares = {}
    for yi = 0, res - 1 do
        for xi = 0, res - 1 do
            local sq = makeSquare(CONFIG.COLORS.WHITE, vec(size/res + 1, size/res + 1), vec(0,0), true, 1, CONFIG.ZINDEX.PICKER + 2)
            table.insert(self.svSquares, {square = sq, xi = xi, yi = yi})
        end
    end
    
    self.svCursor = makeSquare(CONFIG.COLORS.WHITE, vec(8, 8), vec(0,0), false, 1, CONFIG.ZINDEX.PICKER + 3)
    self.svCursor.Thickness = 2
    
    self.hueSegments = {}
    local segCount = 12
    for i = 0, segCount - 1 do
        local seg = makeSquare(hsvToRgb(i / segCount, 1, 1), vec(CONFIG.LAYOUT.HUE_BAR_WIDTH, size / segCount + 1), vec(0,0), true, 1, CONFIG.ZINDEX.PICKER + 2)
        table.insert(self.hueSegments, seg)
    end
    
    self.hueCursor = makeSquare(CONFIG.COLORS.WHITE, vec(CONFIG.LAYOUT.HUE_BAR_WIDTH + 4, 4), vec(0,0), false, 1, CONFIG.ZINDEX.PICKER + 3)
    self.hueCursor.Thickness = 2
    
    self.resultPreview = makeSquare(self.value, vec(50, 30), vec(0,0), true, 1, CONFIG.ZINDEX.PICKER + 2)
    self.resultBorder = makeSquare(CONFIG.COLORS.BORDER, vec(50, 30), vec(0,0), false, 1, CONFIG.ZINDEX.PICKER + 3)
    
    self.rgbText = makeText("R:255 G:255 B:255", CONFIG.TEXT_SIZE.SMALL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.PICKER + 2)
    self.rgbText.Outline = false
    
    return self
end

function ColorPicker:Update(x, y)
    self.label.Position = vec(x, y)
    self.preview.Position = vec(x, y + 20)
    self.preview.Color = self.value
    self.previewBorder.Position = vec(x, y + 20)
    
    if self.isOpen then
        local px, py = x, y + 60
        self.pickerBg.Position = vec(px, py)
        self.pickerBg.Visible = Window.visible
        self.pickerBorder.Position = vec(px, py)
        self.pickerBorder.Visible = Window.visible
        
        local svX, svY = px + 10, py + 10
        local size = CONFIG.LAYOUT.COLOR_PICKER_SIZE
        local res = 10
        local cellSize = size / res
        
        for _, data in ipairs(self.svSquares) do
            local s = data.xi / (res - 1)
            local v = 1 - (data.yi / (res - 1))
            data.square.Position = vec(svX + data.xi * cellSize, svY + data.yi * cellSize)
            data.square.Color = hsvToRgb(self.hue, s, v)
            data.square.Visible = Window.visible
        end
        
        local cursorX = svX + (self.sat * size) - 4
        local cursorY = svY + ((1 - self.val) * size) - 4
        self.svCursor.Position = vec(cursorX, cursorY)
        self.svCursor.Visible = Window.visible
        
        local hueX = svX + size + 15
        local segHeight = size / #self.hueSegments
        for i, seg in ipairs(self.hueSegments) do
            seg.Position = vec(hueX, svY + (i - 1) * segHeight)
            seg.Visible = Window.visible
        end
        
        local hueCursorY = svY + (self.hue * size) - 2
        self.hueCursor.Position = vec(hueX - 2, hueCursorY)
        self.hueCursor.Visible = Window.visible
        
        self.resultPreview.Position = vec(hueX + 30, svY)
        self.resultPreview.Color = self.value
        self.resultPreview.Visible = Window.visible
        self.resultBorder.Position = vec(hueX + 30, svY)
        self.resultBorder.Visible = Window.visible
        
        local r, g, b = math.floor(self.value.R * 255), math.floor(self.value.G * 255), math.floor(self.value.B * 255)
        self.rgbText.Text = "R:" .. r .. " G:" .. g .. " B:" .. b
        self.rgbText.Position = vec(hueX + 30, svY + 35)
        self.rgbText.Visible = Window.visible
    else
        self.pickerBg.Visible = false
        self.pickerBorder.Visible = false
        for _, data in ipairs(self.svSquares) do data.square.Visible = false end
        self.svCursor.Visible = false
        for _, seg in ipairs(self.hueSegments) do seg.Visible = false end
        self.hueCursor.Visible = false
        self.resultPreview.Visible = false
        self.resultBorder.Visible = false
        self.rgbText.Visible = false
    end
end

function ColorPicker:HandleClick(mx, my)
    if isInside(self.preview.Position, vec(CONFIG.LAYOUT.COLOR_PREVIEW_SIZE, CONFIG.LAYOUT.COLOR_PREVIEW_SIZE), vec(mx, my)) then
        self.isOpen = not self.isOpen
        if self.isOpen then
            if ActivePicker and ActivePicker ~= self then ActivePicker.isOpen = false end
            ActivePicker = self
        else
            ActivePicker = nil
        end
        return true
    end
    
    if self.isOpen then
        local px = self.pickerBg.Position.X
        local py = self.pickerBg.Position.Y
        local svX, svY = px + 10, py + 10
        local size = CONFIG.LAYOUT.COLOR_PICKER_SIZE
        local hueX = svX + size + 15
        
        if isInside(vec(svX, svY), vec(size, size), vec(mx, my)) then
            self.draggingSV = true
            return true
        end
        
        if isInside(vec(hueX, svY), vec(CONFIG.LAYOUT.HUE_BAR_WIDTH, size), vec(mx, my)) then
            self.draggingHue = true
            return true
        end
    end
    return false
end

function ColorPicker:HandleDrag(mx, my)
    if not self.isOpen then return false end
    
    local px = self.pickerBg.Position.X
    local py = self.pickerBg.Position.Y
    local svX, svY = px + 10, py + 10
    local size = CONFIG.LAYOUT.COLOR_PICKER_SIZE
    local hueX = svX + size + 15
    
    if self.draggingSV then
        self.sat = math.clamp((mx - svX) / size, 0, 1)
        self.val = 1 - math.clamp((my - svY) / size, 0, 1)
        self.value = hsvToRgb(self.hue, self.sat, self.val)
        if self.callback then self.callback(self.value) end
        return true
    end
    
    if self.draggingHue then
        self.hue = math.clamp((my - svY) / size, 0, 0.999)
        self.value = hsvToRgb(self.hue, self.sat, self.val)
        if self.callback then self.callback(self.value) end
        return true
    end
    return false
end

function ColorPicker:StopDrag()
    self.draggingSV = false
    self.draggingHue = false
end

function ColorPicker:SetVisible(visible)
    self.label.Visible = visible and Window.visible
    self.preview.Visible = visible and Window.visible
    self.previewBorder.Visible = visible and Window.visible
    if not visible and self.isOpen then
        self.isOpen = false
        self:Update(0, 0)
    end
end

function ColorPicker:GetValue() return self.value end
function ColorPicker:SetValue(v) self.value = v end

-- COMPONENT: Button
local Button = {}
Button.__index = Button

function Button.new(options, accentColor)
    local self = setmetatable({}, Button)
    self.name = options.Name or "Button"
    self.callback = options.Callback
    self.accent = accentColor or CONFIG.COLORS.ACCENT
    self.width = options.Width or 150
    
    self.bg = makeSquare(CONFIG.COLORS.BUTTON_BG, vec(self.width, CONFIG.LAYOUT.BUTTON_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT)
    self.border = makeSquare(CONFIG.COLORS.BORDER, vec(self.width, CONFIG.LAYOUT.BUTTON_HEIGHT), vec(0,0), false, 1, CONFIG.ZINDEX.COMPONENT + 1)
    self.text = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT + 2)
    self.text.Outline = false
    self.text.Center = true
    
    return self
end

function Button:Update(x, y)
    self.bg.Position = vec(x, y)
    self.border.Position = vec(x, y)
    self.text.Position = vec(x + self.width / 2, y + 6)
    
    local mp = mousePos()
    local hovered = isInside(vec(x, y), vec(self.width, CONFIG.LAYOUT.BUTTON_HEIGHT), mp)
    self.bg.Color = hovered and CONFIG.COLORS.BUTTON_HOVER or CONFIG.COLORS.BUTTON_BG
end

function Button:HandleClick(mx, my)
    if isInside(self.bg.Position, vec(self.width, CONFIG.LAYOUT.BUTTON_HEIGHT), vec(mx, my)) then
        if self.callback then self.callback() end
        return true
    end
    return false
end

function Button:SetVisible(visible)
    self.bg.Visible = visible and Window.visible
    self.border.Visible = visible and Window.visible
    self.text.Visible = visible and Window.visible
end

-- COMPONENT: Keybind
local Keybind = {}
Keybind.__index = Keybind

function Keybind.new(options, accentColor)
    local self = setmetatable({}, Keybind)
    self.name = options.Name or "Keybind"
    self.value = options.Default or Enum.KeyCode.Unknown
    self.callback = options.Callback
    self.accent = accentColor or CONFIG.COLORS.ACCENT
    self.listening = false
    
    self.label = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    self.box = makeSquare(CONFIG.COLORS.INPUT_BG, vec(CONFIG.LAYOUT.KEYBIND_WIDTH, CONFIG.LAYOUT.INPUT_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT)
    self.boxBorder = makeSquare(CONFIG.COLORS.BORDER, vec(CONFIG.LAYOUT.KEYBIND_WIDTH, CONFIG.LAYOUT.INPUT_HEIGHT), vec(0,0), false, 1, CONFIG.ZINDEX.COMPONENT + 1)
    self.text = makeText("None", CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT + 2)
    self.text.Outline = false
    
    return self
end

function Keybind:Update(x, y)
    self.label.Position = vec(x, y)
    self.box.Position = vec(x + 100, y - 2)
    self.boxBorder.Position = vec(x + 100, y - 2)
    self.boxBorder.Color = self.listening and self.accent or CONFIG.COLORS.BORDER
    
    if self.listening then
        self.text.Text = "..."
    else
        self.text.Text = self.value ~= Enum.KeyCode.Unknown and keyCodeToString(self.value) or "None"
    end
    self.text.Position = vec(x + 105, y + 2)
end

function Keybind:HandleClick(mx, my)
    if isInside(self.box.Position, vec(CONFIG.LAYOUT.KEYBIND_WIDTH, CONFIG.LAYOUT.INPUT_HEIGHT), vec(mx, my)) then
        self.listening = not self.listening
        if self.listening then
            if ActiveKeybind and ActiveKeybind ~= self then ActiveKeybind.listening = false end
            ActiveKeybind = self
        else
            ActiveKeybind = nil
        end
        return true
    end
    return false
end

function Keybind:HandleKeyPress(keyCode)
    if self.listening then
        if keyCode == Enum.KeyCode.Escape then
            self.value = Enum.KeyCode.Unknown
        else
            self.value = keyCode
        end
        self.listening = false
        ActiveKeybind = nil
        if self.callback then self.callback(self.value) end
        return true
    end
    return false
end

function Keybind:SetVisible(visible)
    self.label.Visible = visible and Window.visible
    self.box.Visible = visible and Window.visible
    self.boxBorder.Visible = visible and Window.visible
    self.text.Visible = visible and Window.visible
end

function Keybind:GetValue() return self.value end
function Keybind:SetValue(v) self.value = v end
function Keybind:IsPressed() 
    local keys = getpressedkeys and getpressedkeys() or {}
    for _, k in ipairs(keys) do
        if k == self.value.Value then return true end
    end
    return false
end

-- COMPONENT: TextBox (Input)
local TextBox = {}
TextBox.__index = TextBox

function TextBox.new(options, accentColor)
    local self = setmetatable({}, TextBox)
    self.name = options.Name or "Input"
    self.value = options.Default or ""
    self.placeholder = options.Placeholder or "Enter text..."
    self.callback = options.Callback
    self.accent = accentColor or CONFIG.COLORS.ACCENT
    self.focused = false
    self.width = options.Width or 150
    
    self.label = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    self.box = makeSquare(CONFIG.COLORS.INPUT_BG, vec(self.width, CONFIG.LAYOUT.INPUT_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT)
    self.boxBorder = makeSquare(CONFIG.COLORS.BORDER, vec(self.width, CONFIG.LAYOUT.INPUT_HEIGHT), vec(0,0), false, 1, CONFIG.ZINDEX.COMPONENT + 1)
    self.text = makeText("", CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT + 2)
    self.text.Outline = false
    
    return self
end

function TextBox:Update(x, y)
    self.label.Position = vec(x, y)
    self.box.Position = vec(x, y + 20)
    self.boxBorder.Position = vec(x, y + 20)
    self.boxBorder.Color = self.focused and self.accent or CONFIG.COLORS.BORDER
    
    if self.value == "" then
        self.text.Text = self.placeholder
        self.text.Color = CONFIG.COLORS.TEXT_LIGHT
    else
        self.text.Text = self.value .. (self.focused and "|" or "")
        self.text.Color = CONFIG.COLORS.TEXT
    end
    self.text.Position = vec(x + 5, y + 25)
end

function TextBox:HandleClick(mx, my)
    local wasClicked = isInside(self.box.Position, vec(self.width, CONFIG.LAYOUT.INPUT_HEIGHT), vec(mx, my))
    if wasClicked then
        self.focused = true
        if ActiveInput and ActiveInput ~= self then ActiveInput.focused = false end
        ActiveInput = self
        return true
    elseif self.focused then
        self.focused = false
        if self.callback then self.callback(self.value) end
        ActiveInput = nil
    end
    return false
end

function TextBox:HandleKeyPress(keyCode)
    if not self.focused then return false end
    
    if keyCode == Enum.KeyCode.Backspace then
        self.value = string.sub(self.value, 1, -2)
    elseif keyCode == Enum.KeyCode.Return then
        self.focused = false
        ActiveInput = nil
        if self.callback then self.callback(self.value) end
    elseif keyCode == Enum.KeyCode.Escape then
        self.focused = false
        ActiveInput = nil
    end
    return true
end

function TextBox:HandleTextInput(text)
    if self.focused then
        self.value = self.value .. text
        return true
    end
    return false
end

function TextBox:SetVisible(visible)
    self.label.Visible = visible and Window.visible
    self.box.Visible = visible and Window.visible
    self.boxBorder.Visible = visible and Window.visible
    self.text.Visible = visible and Window.visible
end

function TextBox:GetValue() return self.value end
function TextBox:SetValue(v) self.value = v end

-- COMPONENT: Label
local Label = {}
Label.__index = Label

function Label.new(options, accentColor)
    local self = setmetatable({}, Label)
    self.text = options.Text or "Label"
    self.color = options.Color or CONFIG.COLORS.TEXT
    self.size = options.Size or CONFIG.TEXT_SIZE.LABEL
    
    self.label = makeText(self.text, self.size, vec(0,0), self.color, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    
    return self
end

function Label:Update(x, y)
    self.label.Position = vec(x, y)
end

function Label:SetVisible(visible)
    self.label.Visible = visible and Window.visible
end

function Label:SetText(text) self.text = text; self.label.Text = text end
function Label:SetColor(color) self.color = color; self.label.Color = color end

-- COMPONENT: Separator
local Separator = {}
Separator.__index = Separator

function Separator.new(options, accentColor)
    local self = setmetatable({}, Separator)
    self.text = options.Text or ""
    self.width = 200
    self.accent = accentColor or CONFIG.COLORS.ACCENT
    
    self.lineLeft = makeLine(CONFIG.COLORS.SEPARATOR, vec(0,0), vec(0,0), 1, CONFIG.ZINDEX.COMPONENT)
    self.lineRight = makeLine(CONFIG.COLORS.SEPARATOR, vec(0,0), vec(0,0), 1, CONFIG.ZINDEX.COMPONENT)
    
    if self.text ~= "" then
        self.label = makeText(self.text, CONFIG.TEXT_SIZE.VALUE, vec(0,0), self.accent, CONFIG.ZINDEX.COMPONENT)
        self.label.Outline = false
    end
    
    return self
end

function Separator:Update(x, y)
    if self.text ~= "" then
        local textWidth = #self.text * 6
        self.lineLeft.From = vec(x, y + 6)
        self.lineLeft.To = vec(x + (self.width - textWidth) / 2 - 5, y + 6)
        self.lineRight.From = vec(x + (self.width + textWidth) / 2 + 5, y + 6)
        self.lineRight.To = vec(x + self.width, y + 6)
        self.label.Position = vec(x + (self.width - textWidth) / 2, y)
    else
        self.lineLeft.From = vec(x, y + 6)
        self.lineLeft.To = vec(x + self.width, y + 6)
        self.lineRight.Visible = false
    end
end

function Separator:SetVisible(visible)
    self.lineLeft.Visible = visible and Window.visible
    self.lineRight.Visible = visible and Window.visible and self.text ~= ""
    if self.label then self.label.Visible = visible and Window.visible end
end

-- COMPONENT: Paragraph
local Paragraph = {}
Paragraph.__index = Paragraph

function Paragraph.new(options, accentColor)
    local self = setmetatable({}, Paragraph)
    self.title = options.Title or ""
    self.content = options.Content or ""
    self.width = 200
    
    self.titleLabel = makeText(self.title, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT_DARK, CONFIG.ZINDEX.COMPONENT)
    self.titleLabel.Outline = false
    
    self.lines = {}
    local words = {}
    for word in string.gmatch(self.content, "%S+") do table.insert(words, word) end
    
    local currentLine = ""
    local lineIndex = 1
    for _, word in ipairs(words) do
        local testLine = currentLine == "" and word or (currentLine .. " " .. word)
        if #testLine * 6 > self.width then
            self.lines[lineIndex] = makeText(currentLine, CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT_LIGHT, CONFIG.ZINDEX.COMPONENT)
            self.lines[lineIndex].Outline = false
            lineIndex = lineIndex + 1
            currentLine = word
        else
            currentLine = testLine
        end
    end
    if currentLine ~= "" then
        self.lines[lineIndex] = makeText(currentLine, CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT_LIGHT, CONFIG.ZINDEX.COMPONENT)
        self.lines[lineIndex].Outline = false
    end
    
    self.height = 20 + #self.lines * 14
    
    return self
end

function Paragraph:Update(x, y)
    self.titleLabel.Position = vec(x, y)
    for i, line in ipairs(self.lines) do
        line.Position = vec(x, y + 18 + (i - 1) * 14)
    end
end

function Paragraph:SetVisible(visible)
    self.titleLabel.Visible = visible and Window.visible
    for _, line in ipairs(self.lines) do
        line.Visible = visible and Window.visible
    end
end

function Paragraph:GetHeight() return self.height end

-- COMPONENT: ProgressBar
local ProgressBar = {}
ProgressBar.__index = ProgressBar

function ProgressBar.new(options, accentColor)
    local self = setmetatable({}, ProgressBar)
    self.name = options.Name or "Progress"
    self.value = options.Default or 0
    self.max = options.Max or 100
    self.accent = accentColor or CONFIG.COLORS.ACCENT
    self.width = options.Width or 150
    self.showPercent = options.ShowPercent ~= false
    
    self.label = makeText(self.name, CONFIG.TEXT_SIZE.LABEL, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT)
    self.label.Outline = false
    self.bg = makeSquare(CONFIG.COLORS.SLIDER_BG, vec(self.width, 10), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT)
    self.fill = makeSquare(self.accent, vec(0, 10), vec(0,0), true, 1, CONFIG.ZINDEX.COMPONENT + 1)
    self.percentText = makeText("0%", CONFIG.TEXT_SIZE.VALUE, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.COMPONENT + 2)
    self.percentText.Outline = false
    
    return self
end

function ProgressBar:Update(x, y)
    self.label.Position = vec(x, y)
    self.bg.Position = vec(x, y + 20)
    
    local percent = math.clamp(self.value / self.max, 0, 1)
    self.fill.Position = vec(x, y + 20)
    self.fill.Size = vec(self.width * percent, 10)
    
    self.percentText.Text = math.floor(percent * 100) .. "%"
    self.percentText.Position = vec(x + self.width + 10, y + 18)
end

function ProgressBar:SetVisible(visible)
    self.label.Visible = visible and Window.visible
    self.bg.Visible = visible and Window.visible
    self.fill.Visible = visible and Window.visible
    self.percentText.Visible = visible and Window.visible and self.showPercent
end

function ProgressBar:GetValue() return self.value end
function ProgressBar:SetValue(v) self.value = math.clamp(v, 0, self.max) end
function ProgressBar:Increment(amount) self.value = math.clamp(self.value + (amount or 1), 0, self.max) end

-- Tab Class
local Tab = {}
Tab.__index = Tab

function Tab.new(name, accentColor)
    local self = setmetatable({}, Tab)
    self.name = name
    self.accent = accentColor
    self.components = {}
    self.isActive = false
    return self
end

function Tab:Toggle(options) local c = Toggle.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:Slider(options) local c = Slider.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:Dropdown(options) local c = Dropdown.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:MultiSelect(options) local c = MultiSelect.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:ColorPicker(options) local c = ColorPicker.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:Button(options) local c = Button.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:Keybind(options) local c = Keybind.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:TextBox(options) local c = TextBox.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:Label(options) local c = Label.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:Separator(options) local c = Separator.new(options or {}, self.accent); table.insert(self.components, c); return c end
function Tab:Paragraph(options) local c = Paragraph.new(options, self.accent); table.insert(self.components, c); return c end
function Tab:ProgressBar(options) local c = ProgressBar.new(options, self.accent); table.insert(self.components, c); return c end

-- Notification System
function Library:Notify(options)
    local notif = {
        title = options.Title or "Notification",
        message = options.Message or "",
        duration = options.Duration or 3,
        type = options.Type or "Info",
        startTime = tick(),
        alpha = 0
    }
    
    local typeColors = {
        Success = CONFIG.COLORS.NOTIFICATION_SUCCESS,
        Error = CONFIG.COLORS.NOTIFICATION_ERROR,
        Warning = CONFIG.COLORS.NOTIFICATION_WARNING,
        Info = CONFIG.COLORS.NOTIFICATION_INFO
    }
    
    notif.bg = makeSquare(CONFIG.COLORS.NOTIFICATION_BG, vec(CONFIG.LAYOUT.NOTIFICATION_WIDTH, CONFIG.LAYOUT.NOTIFICATION_HEIGHT), vec(0,0), true, 0.95, CONFIG.ZINDEX.NOTIFICATION)
    notif.accent = makeSquare(typeColors[notif.type] or CONFIG.COLORS.NOTIFICATION_INFO, vec(4, CONFIG.LAYOUT.NOTIFICATION_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.NOTIFICATION + 1)
    notif.title = makeText(notif.title, CONFIG.TEXT_SIZE.NOTIFICATION, vec(0,0), CONFIG.COLORS.WHITE, CONFIG.ZINDEX.NOTIFICATION + 2)
    notif.title.Outline = false
    notif.message = makeText(notif.message, CONFIG.TEXT_SIZE.SMALL, vec(0,0), CONFIG.COLORS.TEXT_LIGHT, CONFIG.ZINDEX.NOTIFICATION + 2)
    notif.message.Outline = false
    
    table.insert(Notifications, notif)
end

function Library:UpdateNotifications()
    local screenWidth = 1920
    local baseY = 100
    local activeNotifs = {}
    
    for i, notif in ipairs(Notifications) do
        local elapsed = tick() - notif.startTime
        
        if elapsed < notif.duration then
            if elapsed < 0.3 then
                notif.alpha = elapsed / 0.3
            elseif elapsed > notif.duration - 0.3 then
                notif.alpha = (notif.duration - elapsed) / 0.3
            else
                notif.alpha = 1
            end
            
            local y = baseY + (#activeNotifs * (CONFIG.LAYOUT.NOTIFICATION_HEIGHT + CONFIG.LAYOUT.NOTIFICATION_SPACING))
            local x = screenWidth - CONFIG.LAYOUT.NOTIFICATION_WIDTH - 20
            
            notif.bg.Position = vec(x, y)
            notif.bg.Visible = true
            notif.bg.Transparency = notif.alpha * 0.95
            
            notif.accent.Position = vec(x, y)
            notif.accent.Visible = true
            notif.accent.Transparency = notif.alpha
            
            notif.title.Position = vec(x + 12, y + 8)
            notif.title.Visible = true
            
            notif.message.Position = vec(x + 12, y + 28)
            notif.message.Visible = true
            
            table.insert(activeNotifs, notif)
        else
            notif.bg.Visible = false
            notif.accent.Visible = false
            notif.title.Visible = false
            notif.message.Visible = false
        end
    end
    
    Notifications = activeNotifs
end

-- Main Library Functions
function Library:Create(options)
    local self = setmetatable({}, Library)
    
    self.name = options.Name or "UI Library"
    self.accent = options.AccentColor or CONFIG.COLORS.ACCENT
    self.toggleKey = options.ToggleKey or CONFIG.TOGGLE_KEY
    
    self.tabs = {}
    self.tabButtons = {}
    self.activeTab = nil
    self.clickDebounce = false
    self.draggingSlider = nil
    self.draggingPicker = nil
    self.lastToggle = 0
    
    self.shadow = makeSquare(CONFIG.COLORS.SHADOW, Window.size, Window.pos, true, 0.4, CONFIG.ZINDEX.SHADOW)
    self.border = makeSquare(CONFIG.COLORS.BORDER, Window.size, Window.pos, false, 1, CONFIG.ZINDEX.BORDER)
    self.body = makeSquare(CONFIG.COLORS.BODY, Window.size, Window.pos, true, 0.95, CONFIG.ZINDEX.BODY)
    self.titleBar = makeSquare(CONFIG.COLORS.TITLE, vec(Window.size.X, CONFIG.WINDOW.TITLE_HEIGHT), Window.pos, true, 1, CONFIG.ZINDEX.TITLE)
    self.titleGloss = makeLine(CONFIG.COLORS.TITLE_HIGH, vec(0,0), vec(0,0), 2, CONFIG.ZINDEX.TITLE + 1)
    self.titleText = makeText(self.name, CONFIG.TEXT_SIZE.TITLE, vec(0,0), CONFIG.COLORS.WHITE, CONFIG.ZINDEX.TITLE + 2)
    self.titleText.OutlineColor = Color3.new(0,0,0)
    
    self.minBtn = makeSquare(CONFIG.COLORS.WHITE, vec(20, 20), vec(0,0), true, 1, CONFIG.ZINDEX.TITLE + 1)
    self.minTxt = makeText("_", 14, vec(0,0), CONFIG.COLORS.BORDER, CONFIG.ZINDEX.TITLE + 2)
    self.minTxt.Outline = false
    
    self.sidebar = makeSquare(CONFIG.COLORS.SIDEBAR, vec(CONFIG.WINDOW.SIDEBAR_WIDTH, 0), vec(0,0), true, 1, CONFIG.ZINDEX.SIDEBAR)
    self.sidebarLine = makeLine(Color3.new(0.8, 0.8, 0.8), vec(0,0), vec(0,0), 1, CONFIG.ZINDEX.SIDEBAR + 1)
    
    self.grip1 = makeLine(Color3.new(0.6,0.6,0.6), vec(0,0), vec(0,0), 2, CONFIG.ZINDEX.CONTENT)
    self.grip2 = makeLine(Color3.new(0.6,0.6,0.6), vec(0,0), vec(0,0), 2, CONFIG.ZINDEX.CONTENT)
    
    self:StartLoop()
    
    return self
end

function Library:Tab(options)
    local tab = Tab.new(options.Name or "Tab", self.accent)
    
    local btn = {
        tab = tab,
        bg = makeSquare(CONFIG.COLORS.SIDEBAR, vec(CONFIG.WINDOW.SIDEBAR_WIDTH, CONFIG.WINDOW.TAB_HEIGHT), vec(0,0), true, 1, CONFIG.ZINDEX.SIDEBAR + 1),
        text = makeText(tab.name, CONFIG.TEXT_SIZE.TAB, vec(0,0), CONFIG.COLORS.TEXT, CONFIG.ZINDEX.SIDEBAR + 2)
    }
    btn.text.Outline = false
    
    table.insert(self.tabs, tab)
    table.insert(self.tabButtons, btn)
    
    if not self.activeTab then
        tab.isActive = true
        self.activeTab = tab
    end
    
    return tab
end

function Library:SwitchTab(tab)
    for _, t in ipairs(self.tabs) do t.isActive = false end
    tab.isActive = true
    self.activeTab = tab
    if ActiveDropdown then ActiveDropdown.isOpen = false; ActiveDropdown = nil end
    if ActivePicker then ActivePicker.isOpen = false; ActivePicker = nil end
end

function Library:UpdateUI()
    local currentSize = Window.minimized and vec(Window.size.X, CONFIG.WINDOW.TITLE_HEIGHT) or Window.size
    
    self.shadow.Position = Window.pos + vec(5, 5)
    self.shadow.Size = currentSize
    self.shadow.Visible = Window.visible
    
    self.border.Position = Window.pos - vec(1, 1)
    self.border.Size = currentSize + vec(2, 2)
    self.border.Visible = Window.visible
    
    self.body.Position = Window.pos
    self.body.Size = currentSize
    self.body.Visible = Window.visible
    
    self.titleBar.Position = Window.pos
    self.titleBar.Size = vec(currentSize.X, CONFIG.WINDOW.TITLE_HEIGHT)
    self.titleBar.Visible = Window.visible
    
    self.titleGloss.From = Window.pos + vec(0, 1)
    self.titleGloss.To = Window.pos + vec(currentSize.X, 1)
    self.titleGloss.Visible = Window.visible
    
    self.titleText.Position = Window.pos + vec(8, 6)
    self.titleText.Visible = Window.visible
    
    self.minBtn.Position = Window.pos + vec(currentSize.X - 28, 5)
    self.minBtn.Visible = Window.visible
    self.minTxt.Position = Window.pos + vec(currentSize.X - 22, 2)
    self.minTxt.Text = Window.minimized and "+" or "_"
    self.minTxt.Visible = Window.visible
    
    if Window.minimized then
        self.sidebar.Visible = false
        self.sidebarLine.Visible = false
        self.grip1.Visible = false
        self.grip2.Visible = false
        for _, btn in ipairs(self.tabButtons) do btn.bg.Visible = false; btn.text.Visible = false end
        for _, tab in ipairs(self.tabs) do
            for _, comp in ipairs(tab.components) do comp:SetVisible(false) end
        end
        return
    end
    
    self.sidebar.Position = Window.pos + vec(0, CONFIG.WINDOW.TITLE_HEIGHT)
    self.sidebar.Size = vec(CONFIG.WINDOW.SIDEBAR_WIDTH, Window.size.Y - CONFIG.WINDOW.TITLE_HEIGHT)
    self.sidebar.Visible = Window.visible
    
    self.sidebarLine.From = Window.pos + vec(CONFIG.WINDOW.SIDEBAR_WIDTH, CONFIG.WINDOW.TITLE_HEIGHT)
    self.sidebarLine.To = Window.pos + vec(CONFIG.WINDOW.SIDEBAR_WIDTH, Window.size.Y)
    self.sidebarLine.Visible = Window.visible
    
    local corner = Window.pos + Window.size
    self.grip1.From = corner - vec(10, 0)
    self.grip1.To = corner - vec(0, 10)
    self.grip1.Visible = Window.visible
    self.grip2.From = corner - vec(5, 0)
    self.grip2.To = corner - vec(0, 5)
    self.grip2.Visible = Window.visible
    
    for i, btn in ipairs(self.tabButtons) do
        local tabY = Window.pos.Y + CONFIG.WINDOW.TITLE_HEIGHT + (i - 1) * CONFIG.WINDOW.TAB_HEIGHT
        btn.bg.Position = vec(Window.pos.X, tabY)
        btn.bg.Size = vec(CONFIG.WINDOW.SIDEBAR_WIDTH, CONFIG.WINDOW.TAB_HEIGHT)
        btn.bg.Color = btn.tab.isActive and CONFIG.COLORS.BODY or CONFIG.COLORS.SIDEBAR
        btn.bg.Visible = Window.visible
        btn.text.Position = vec(Window.pos.X + 10, tabY + 7)
        btn.text.Color = btn.tab.isActive and self.accent or CONFIG.COLORS.TEXT
        btn.text.Visible = Window.visible
    end
    
    local contentX = Window.pos.X + CONFIG.WINDOW.SIDEBAR_WIDTH + CONFIG.LAYOUT.CONTENT_PADDING
    local contentY = Window.pos.Y + CONFIG.WINDOW.TITLE_HEIGHT + CONFIG.LAYOUT.CONTENT_PADDING
    
    for _, tab in ipairs(self.tabs) do
        if tab.isActive then
            local y = contentY
            for _, comp in ipairs(tab.components) do
                comp:Update(contentX, y)
                comp:SetVisible(true)
                
                local height = CONFIG.LAYOUT.ITEM_HEIGHT + CONFIG.LAYOUT.ITEM_SPACING
                if comp.isOpen then 
                    height = height + (#comp.items or #comp.options or 0) * (CONFIG.LAYOUT.DROPDOWN_ITEM_HEIGHT or 22) + 10 
                end
                if comp.GetHeight then height = comp:GetHeight() + CONFIG.LAYOUT.ITEM_SPACING end
                
                y = y + height
            end
        else
            for _, comp in ipairs(tab.components) do comp:SetVisible(false) end
        end
    end
    
    self:UpdateNotifications()
end

function Library:HandleInput()
    local mp = mousePos()
    local mx, my = mp.X, mp.Y
    local click = mouseDown()
    
    if click then
        if self.draggingSlider then self.draggingSlider:HandleDrag(mx, my) end
        if self.draggingPicker then self.draggingPicker:HandleDrag(mx, my) end
        
        if not self.clickDebounce then
            if isInside(self.minBtn.Position, vec(20, 20), vec(mx, my)) then
                Window.minimized = not Window.minimized
                self.clickDebounce = true
                return
            end
            
            if not Window.minimized then
                for _, btn in ipairs(self.tabButtons) do
                    if isInside(btn.bg.Position, btn.bg.Size, vec(mx, my)) then
                        self:SwitchTab(btn.tab)
                        self.clickDebounce = true
                        return
                    end
                end
                
                if self.activeTab then
                    for _, comp in ipairs(self.activeTab.components) do
                        if comp.HandleClick and comp:HandleClick(mx, my) then self.clickDebounce = true; return end
                        if comp.StartDrag and comp:StartDrag(mx, my) then self.draggingSlider = comp; return end
                    end
                end
                
                local corner = Window.pos + Window.size - vec(CONFIG.WINDOW.SCALE_MARGIN, CONFIG.WINDOW.SCALE_MARGIN)
                if isInside(corner, vec(CONFIG.WINDOW.SCALE_MARGIN, CONFIG.WINDOW.SCALE_MARGIN), vec(mx, my)) then
                    Window.scaling = true
                    return
                end
            end
            
            if isInside(Window.pos, vec(Window.size.X - 30, CONFIG.WINDOW.TITLE_HEIGHT), vec(mx, my)) then
                Window.dragging = true
                Window.dragOffset = vec(mx, my) - Window.pos
            end
        end
    else
        Window.dragging = false
        Window.scaling = false
        self.clickDebounce = false
        if self.draggingSlider then self.draggingSlider:StopDrag(); self.draggingSlider = nil end
        if self.draggingPicker then self.draggingPicker:StopDrag(); self.draggingPicker = nil end
        for _, tab in ipairs(self.tabs) do
            for _, comp in ipairs(tab.components) do
                if comp.StopDrag then comp:StopDrag() end
            end
        end
    end
    
    if Window.dragging then Window.pos = vec(mx, my) - Window.dragOffset end
    if Window.scaling then
        Window.size = vec(
            math.max(CONFIG.WINDOW.MIN_WIDTH, mx - Window.pos.X),
            math.max(CONFIG.WINDOW.MIN_HEIGHT, my - Window.pos.Y)
        )
    end
end

function Library:HandleToggle()
    local keys = getpressedkeys and getpressedkeys() or {}
    for _, k in ipairs(keys) do
        if k == self.toggleKey then
            local now = tick()
            if now - self.lastToggle > 0.25 then
                Window.visible = not Window.visible
                if not Window.visible then
                    for _, obj in ipairs(DrawingObjects) do obj.Visible = false end
                end
                self.lastToggle = now
            end
            break
        end
    end
end

function Library:StartLoop()
    RunService.Render:Connect(function()
        self:HandleToggle()
        if not Window.visible then return end
        self:HandleInput()
        self:UpdateUI()
    end)
end

function Library:Unload()
    for _, obj in ipairs(DrawingObjects) do obj:Remove() end
    DrawingObjects = {}
    Notifications = {}
    Window.visible = false
end

function Library:Show() Window.visible = true end
function Library:Hide() Window.visible = false end
function Library:Toggle() Window.visible = not Window.visible end

return Library
