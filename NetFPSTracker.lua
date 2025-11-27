-- Enhanced NetFPSTracker with settings and options panel

local ADDON = "NetFPSTracker"

-- Default settings
defaults = {
  showHome = true,
  showWorld = true,
  showFPS = true,
  compact = false,
  fontSize = 12,
  updateInterval = 0.5,
  fpsCritical = 30,
  fpsWarn = 50,
  latencyCritical = 200,
  latencyWarn = 100,
  frameAlpha = 0.6,
  borderless = false,
  locked = false,
  fontFace = "Fonts\\FRIZQT__.TTF",
  backgroundColor = { r = 0, g = 0, b = 0 },
}

local function CloneDefaults()
  local copy = {}
  for k, v in pairs(defaults) do
    if type(v) == "table" then
      local nested = {}
      for nk, nv in pairs(v) do
        nested[nk] = nv
      end
      copy[k] = nested
    else
      copy[k] = v
    end
  end
  return copy
end

local function EnsureAccountSettings()
  NetFPSDB = NetFPSDB or {}
  NetFPSDB.account = NetFPSDB.account or {}
  if not NetFPSDB.account.settings then
    NetFPSDB.account.settings = CloneDefaults()
  else
    for k, v in pairs(defaults) do
      if NetFPSDB.account.settings[k] == nil then
        NetFPSDB.account.settings[k] = v
      end
    end
  end
  return NetFPSDB.account.settings
end

local function GetAccountSettings()
  if NetFPSDB and NetFPSDB.account and NetFPSDB.account.settings then
    return NetFPSDB.account.settings
  end
  return defaults
end

local fontChoices = {
  { text = "Friz Quadrata", value = "Fonts\\FRIZQT__.TTF" },
  { text = "Arial Narrow", value = "Fonts\\ARIALN.TTF" },
  { text = "Morpheus", value = "Fonts\\MORPHEUS.TTF" },
  { text = "Skurri", value = "Fonts\\SKURRI.TTF" },
}

local ToggleLockState

-- Main frame
local frame = CreateFrame("Frame", "NetFPSFrame", UIParent, "BackdropTemplate")
frame:SetSize(220, 48)
frame:SetPoint("CENTER", 0, 0)
frame:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 12,
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.6)
frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)

frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
frame.text:SetPoint("TOPLEFT", 8, -8)
frame.text:SetJustifyH("LEFT")

local lockButton = CreateFrame("Button", "NetFPSTracker_LockButton", frame, "UIPanelButtonTemplate")
lockButton:SetSize(32, 24)
lockButton:SetPoint("TOPRIGHT", -6, -6)
lockButton:SetNormalFontObject(GameFontNormalSmall)
lockButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
lockButton:Hide()
lockButton:SetScript("OnEnter", function(self)
  self:Show()
  GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
  GameTooltip:SetText("Toggle lock")
  GameTooltip:Show()
end)
lockButton:SetScript("OnLeave", function(self)
  GameTooltip:Hide()
  if frame and not frame:IsMouseOver() then
    self:Hide()
  end
end)
lockButton:SetScript("OnClick", function()
  ToggleLockState()
end)
frame.lockButton = lockButton

frame:SetScript("OnEnter", function(self)
  if self.lockButton then self.lockButton:Show() end
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:AddLine("NetFPSTracker")
  GameTooltip:AddLine("Drag to move. Use /netfps reset | show | hide | options")
  GameTooltip:Show()
end)
frame:SetScript("OnLeave", function(self)
  if self.lockButton and not self.lockButton:IsMouseOver() then self.lockButton:Hide() end
  GameTooltip:Hide()
end)

local function savePosition()
  NetFPSDB = NetFPSDB or {}
  NetFPSDB.pos = { frame:GetCenter() }
end

local function AdjustFrameToContent()
  local text = frame.text
  if not (frame and text) then return end

  local textWidth = text:GetStringWidth() or 0
  local horizontalPadding = 32
  local width = math.max(120, math.ceil(textWidth) + horizontalPadding)

  local textHeight = text:GetStringHeight() or 0
  local verticalPadding = 28
  local height = textHeight + verticalPadding

  frame:SetSize(width, height)
end

local function AdjustLockButtonSize()
  if not lockButton then return end
  local text = _G[lockButton:GetName() .. "Text"]
  if not text then return end
  local width = math.max(22, math.ceil(text:GetStringWidth()) + 16)
  lockButton:SetSize(width, lockButton:GetHeight() or 24)
end

local function UpdateLockVisuals(locked)
  frame.locked = locked
  if frame.lockButton then
    frame.lockButton:SetText(locked and "L" or "U")
    AdjustLockButtonSize()
  end
  frame:SetMovable(not locked)
end

ToggleLockState = function(locked)
  local settings = EnsureAccountSettings()
  local desired = locked
  if desired == nil then
    desired = not settings.locked
  end
  settings.locked = desired
  UpdateLockVisuals(desired)
  if panel and panel.lockFrame then
    panel.lockFrame:SetChecked(desired)
  end
end

local function ApplySettings()
  local s = GetAccountSettings()
  local font = s.fontFace or defaults.fontFace
  frame.text:SetFont(font, s.fontSize, "OUTLINE")
  local alpha = s.frameAlpha or defaults.frameAlpha
  local bgColor = s.backgroundColor or defaults.backgroundColor
  frame:SetBackdropColor(bgColor.r or 0, bgColor.g or 0, bgColor.b or 0, alpha)
  local borderAlpha = s.borderless and 0 or 0.8
  frame:SetBackdropBorderColor(0, 0, 0, borderAlpha)
  local locked = s.locked or defaults.locked
  UpdateLockVisuals(locked)
  if s.compact then
    frame.text:SetPoint("CENTER", 0, 0)
  else
    frame.text:SetPoint("TOPLEFT", 8, -8)
  end
  AdjustFrameToContent()
end

frame:SetScript("OnDragStart", function(self)
  if self.locked then return end
  self:StartMoving()
end)
frame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  savePosition()
end)

-- Restore on login and initialize settings
local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  EnsureAccountSettings()
  if NetFPSDB.pos and NetFPSDB.pos[1] and NetFPSDB.pos[2] then
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", NetFPSDB.pos[1], NetFPSDB.pos[2])
  end
  ApplySettings()
end)

-- OnUpdate: update per settings
  local acc = 0
frame:SetScript("OnUpdate", function(self, elapsed)
  acc = acc + elapsed
  local s = GetAccountSettings()
  local interval = s.updateInterval or defaults.updateInterval
  if acc < interval then return end
  acc = 0

  local fps = GetFramerate() or 0
  local bandwidthIn, bandwidthOut, latencyHome, latencyWorld = GetNetStats()
  latencyHome = latencyHome or 0
  latencyWorld = latencyWorld or 0

  local function colorForFPS(v)
    if v < (s.fpsCritical or defaults.fpsCritical) then return "|cffff0000" end
    if v < (s.fpsWarn or defaults.fpsWarn) then return "|cffffff00" end
    return "|cff00ff00"
  end
  local function colorForLatency(v)
    if v > (s.latencyCritical or defaults.latencyCritical) then return "|cffff0000" end
    if v > (s.latencyWarn or defaults.latencyWarn) then return "|cffffff00" end
    return "|cff00ff00"
  end

  local reset = "|r"
  if s.compact then
    local parts = {}
    if s.showFPS then
      table.insert(parts, string.format("%s%.0f%s FPS", colorForFPS(fps), fps, reset))
    end
    if s.showHome then table.insert(parts, string.format("%sH:%s%dms", colorForLatency(latencyHome), reset, latencyHome)) end
    if s.showWorld then table.insert(parts, string.format("%sW:%s%dms", colorForLatency(latencyWorld), reset, latencyWorld)) end
    self.text:SetText(table.concat(parts, "  "))
    AdjustFrameToContent()
  else
    local fpsColor = colorForFPS(fps)
    local homeColor = colorForLatency(latencyHome)
    local worldColor = colorForLatency(latencyWorld)
    local lines = {}
    if s.showFPS then
      table.insert(lines, string.format("%sFPS:%s %.0f", fpsColor, reset, fps))
    end
    if s.showHome then
      table.insert(lines, string.format("%sHome:%s %d ms", homeColor, reset, latencyHome))
    end
    if s.showWorld then
      table.insert(lines, string.format("%sWorld:%s %d ms", worldColor, reset, latencyWorld))
    end
    self.text:SetText(table.concat(lines, "\n"))
    AdjustFrameToContent()
  end
end)

-- Interface options panel (use BackdropTemplate for SetBackdrop support)
local panel = CreateFrame("Frame", "NetFPSTrackerOptionsPanel", UIParent, "BackdropTemplate")
panel.name = "NetFPSTracker"
panel:Hide()
panel:SetSize(380, 260)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
panel:SetFrameStrata("DIALOG")
panel:EnableMouse(true)
panel:SetMovable(true)
panel:RegisterForDrag("LeftButton")
panel:SetClampedToScreen(true)
panel:SetBackdrop({
  bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
  edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 8, right = 8, top = 8, bottom = 8 }
})
panel:SetBackdropColor(0,0,0,0.6)
panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

local function GetFontDisplay(name)
  for _, opt in ipairs(fontChoices) do
    if opt.value == name then return opt.text end
  end
  return fontChoices[1].text
end

local function AdjustOptionsPanelSize()
  local controls = {
    panel.title,
    panel.desc,
    panel.showHome,
    panel.showWorld,
    panel.showFPS,
    panel.compact,
    panel.borderless,
    panel.lockFrame,
    panel.fontSlider,
    panel.alphaSlider,
    panel.bgColorLabel,
    panel.bgColorSwatch,
    panel.intervalSlider,
    panel.fontDropdown,
    panel.close,
    panel.apply,
  }
  local minX, maxX = math.huge, -math.huge
  local minY, maxY = math.huge, -math.huge
  for _, ctrl in ipairs(controls) do
    if ctrl and ctrl:IsShown() then
      local left = ctrl:GetLeft()
      local right = ctrl:GetRight()
      local top = ctrl:GetTop()
      local bottom = ctrl:GetBottom()
      if left and left < minX then minX = left end
      if right and right > maxX then maxX = right end
      if top and top > maxY then maxY = top end
      if bottom and bottom < minY then minY = bottom end
    end
  end
  if minX == math.huge or maxX == -math.huge or minY == math.huge or maxY == -math.huge then return end
  local widthBuffer = 48
  local heightBuffer = 64
  local width = math.max(340, (maxX - minX) + widthBuffer)
  local height = math.max(220, (maxY - minY) + heightBuffer)
  panel:SetSize(width, height)
end

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText("NetFPSTracker")
panel.title = title

local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
desc:SetPoint("RIGHT", panel, -16, 0)
desc:SetJustifyH("LEFT")
desc:SetText("Configure display options for NetFPSTracker.")
panel.desc = desc

-- Utility to create a checkbox
local function CreateCheck(name, x, y, text, initial, onChange)
  local cb = CreateFrame("CheckButton", name, panel, "InterfaceOptionsCheckButtonTemplate")
  cb:SetPoint("TOPLEFT", 16 + x, -80 + y)
  cb.Text:SetText(text)
  cb:SetChecked(initial)
  cb:SetScript("OnClick", function(self)
    local val = self:GetChecked()
    onChange(val)
  end)
  return cb
end

-- Utility to create a slider
local function CreateSlider(name, x, y, text, min, max, step, initial, onChange)
  local s = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
  s:SetPoint("TOPLEFT", 16 + x, -140 + y)
  s:SetMinMaxValues(min, max)
  s:SetValueStep(step)
  s:SetValue(initial)
  _G[s:GetName() .. "Text"]:SetText(text)
  _G[s:GetName() .. "Low"]:SetText(tostring(min))
  _G[s:GetName() .. "High"]:SetText(tostring(max))
  s:SetScript("OnValueChanged", function(self, v)
    onChange(v)
  end)
  return s
end

-- Utility to create a font dropdown
local function CreateFontDropdown(name, x, y, options, initial, onChange)
  local dd = CreateFrame("Frame", name, panel, "UIDropDownMenuTemplate")
  dd:SetPoint("TOPLEFT", 16 + x, -200 + y)
  UIDropDownMenu_SetWidth(dd, 170)
  UIDropDownMenu_JustifyText(dd, "LEFT")

  local function SetValue(value)
    UIDropDownMenu_SetSelectedValue(dd, value)
    UIDropDownMenu_SetText(dd, GetFontDisplay(value))
  end

  UIDropDownMenu_Initialize(dd, function(self, level)
    for _, option in ipairs(options) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = option.text
      info.value = option.value
      info.func = function()
        SetValue(option.value)
        if onChange then onChange(option.value) end
      end
      info.checked = option.value == UIDropDownMenu_GetSelectedValue(dd)
      UIDropDownMenu_AddButton(info)
    end
  end)

  SetValue(initial)
  dd.SetValue = SetValue
  dd.options = options
  return dd
end

-- Populate controls from settings
local function UpdateOptionsControls()
  local s = GetAccountSettings()
  if panel.showHome then panel.showHome:SetChecked(s.showHome) end
  if panel.showWorld then panel.showWorld:SetChecked(s.showWorld) end
  if panel.showFPS then panel.showFPS:SetChecked(s.showFPS) end
  if panel.compact then panel.compact:SetChecked(s.compact) end
  if panel.borderless then panel.borderless:SetChecked(s.borderless) end
  if panel.lockFrame then panel.lockFrame:SetChecked(s.locked) end
  if panel.fontSlider then panel.fontSlider:SetValue(s.fontSize) end
  if panel.alphaSlider then panel.alphaSlider:SetValue(s.frameAlpha or defaults.frameAlpha) end
  if panel.intervalSlider then panel.intervalSlider:SetValue(s.updateInterval) end
  if panel.fontDropdown then panel.fontDropdown.SetValue(s.fontFace or defaults.fontFace) end
  if panel.bgColorSwatch then
    local color = s.backgroundColor or defaults.backgroundColor
    panel.bgColorSwatch:SetBackdropColor(color.r or 0, color.g or 0, color.b or 0, 1)
  end
end

-- Create settings controls
panel.showHome = CreateCheck("NetFPSTracker_ShowHome", 0, 0, "Show Home Latency", defaults.showHome, function(v)
  local settings = EnsureAccountSettings()
  settings.showHome = v
  ApplySettings()
end)
panel.showWorld = CreateCheck("NetFPSTracker_ShowWorld", 160, 0, "Show World Latency", defaults.showWorld, function(v)
  local settings = EnsureAccountSettings()
  settings.showWorld = v
  ApplySettings()
end)
panel.showFPS = CreateCheck("NetFPSTracker_ShowFPS", 0, -30, "Show FPS", defaults.showFPS, function(v)
  local settings = EnsureAccountSettings()
  settings.showFPS = v
  ApplySettings()
end)
panel.compact = CreateCheck("NetFPSTracker_Compact", 160, -30, "Compact Mode", defaults.compact, function(v)
  local settings = EnsureAccountSettings()
  settings.compact = v
  ApplySettings()
end)
panel.borderless = CreateCheck("NetFPSTracker_Borderless", 0, -60, "Hide Border", defaults.borderless, function(v)
  local settings = EnsureAccountSettings()
  settings.borderless = v
  ApplySettings()
end)
panel.lockFrame = CreateCheck("NetFPSTracker_LockFrame", 160, -60, "Lock Frame", defaults.locked, function(v)
  local settings = EnsureAccountSettings()
  settings.locked = v
  ApplySettings()
end)

panel.fontDropdown = CreateFontDropdown("NetFPSTracker_FontDropdown", 0, -130, fontChoices, defaults.fontFace, function(v)
  local settings = EnsureAccountSettings()
  settings.fontFace = v
  ApplySettings()
end)
panel.intervalSlider = CreateSlider("NetFPSTracker_IntervalSlider", 260, -130, "Update Interval (s)", 0.1, 5.0, 0.1, defaults.updateInterval, function(v)
  local settings = EnsureAccountSettings()
  settings.updateInterval = v
end)

local fontLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
fontLabel:SetPoint("BOTTOMLEFT", panel.fontDropdown, "TOPLEFT", 10, 24)
fontLabel:SetText("Font Type")
fontLabel:SetTextColor(1, 0.82, 0)
panel.fontLabel = fontLabel
local fontDescription = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
fontDescription:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -2)
fontDescription:SetPoint("RIGHT", panel, -16, 0)
fontDescription:SetJustifyH("LEFT")
fontDescription:SetText("Choose the font used by the tracker text.")
panel.fontDescription = fontDescription
panel.fontSlider = CreateSlider("NetFPSTracker_FontSlider", 0, -70, "Font Size", 8, 20, 1, defaults.fontSize, function(v)
  local settings = EnsureAccountSettings()
  settings.fontSize = v
  ApplySettings()
end)
panel.alphaSlider = CreateSlider("NetFPSTracker_AlphaSlider", 260, -70, "Frame Opacity", 0.0, 1.0, 0.05, defaults.frameAlpha, function(v)
  local settings = EnsureAccountSettings()
  settings.frameAlpha = v
  ApplySettings()
end)

local function ApplyBackgroundColorToSwatch(r, g, b)
  if panel.bgColorSwatch then
    panel.bgColorSwatch:SetBackdropColor(r or 0, g or 0, b or 0, 1)
  end
end

local function EnsureColorPicker()
  if not ColorPickerFrame then
    LoadAddOn("Blizzard_ColorPicker")
  end
  if ColorPickerFrame and not ColorPickerFrame.swatchFunc then
    ColorPickerFrame.swatchFunc = function() end
  end
  return ColorPickerFrame
end

local function SaveBackgroundColor(r, g, b)
  local settings = EnsureAccountSettings()
  settings.backgroundColor = { r = r or 0, g = g or 0, b = b or 0 }
  ApplySettings()
  ApplyBackgroundColorToSwatch(r, g, b)
end

local function SetPickerColor(r, g, b)
  if ColorPickerFrame_SetColorRGB then
    ColorPickerFrame_SetColorRGB(ColorPickerFrame, r, g, b)
    return
  end
  if ColorPickerFrame.SetColorRGB then
    ColorPickerFrame:SetColorRGB(r, g, b)
  end
end

local bgColorLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
bgColorLabel:SetPoint("TOPLEFT", panel.fontDropdown, "TOPRIGHT", 32, 0)
bgColorLabel:SetText("Background Color")
panel.bgColorLabel = bgColorLabel

local bgColorSwatch = CreateFrame("Button", "NetFPSTracker_BackgroundColorSwatch", panel, "BackdropTemplate")
bgColorSwatch:SetSize(24, 24)
bgColorSwatch:SetPoint("LEFT", bgColorLabel, "RIGHT", 8, 2)
bgColorSwatch:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 4,
})
bgColorSwatch:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
bgColorSwatch:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText("Pick background color")
  GameTooltip:Show()
end)
bgColorSwatch:SetScript("OnLeave", function()
  GameTooltip:Hide()
end)
bgColorSwatch:SetScript("OnClick", function()
  local current = GetAccountSettings().backgroundColor or defaults.backgroundColor
  local r, g, b = current.r or 0, current.g or 0, current.b or 0
  local picker = EnsureColorPicker()
  if not picker then return end
  local function ApplyPickerColor()
    local cr, cg, cb = picker:GetColorRGB()
    SaveBackgroundColor(cr, cg, cb)
  end
  picker.func = ApplyPickerColor
  picker.swatchFunc = ApplyPickerColor
  picker.cancelFunc = function(prev)
    if prev then
      SaveBackgroundColor(prev[1], prev[2], prev[3])
    end
  end
  SetPickerColor(r, g, b)
  picker.previousValues = { r, g, b }
  if ColorPickerFrame:IsShown() then
    ColorPickerFrame:Hide()
  end
  ShowUIPanel(ColorPickerFrame)
end)
panel.bgColorSwatch = bgColorSwatch
local initColor = GetAccountSettings().backgroundColor or defaults.backgroundColor
ApplyBackgroundColorToSwatch(initColor.r or 0, initColor.g or 0, initColor.b or 0)

-- Safely register the options panel once Blizzard's InterfaceOptions API is available
RegisterOptionsPanel = function()
  -- If API already available, register immediately
  if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(panel)
    return
  end

  -- Fallback: wait for ADDON_LOADED and register when available
  local waiter = CreateFrame("Frame")
  waiter:RegisterEvent("ADDON_LOADED")
  waiter:SetScript("OnEvent", function(self, addonName)
    if addonName == "Blizzard_InterfaceOptions" or InterfaceOptions_AddCategory then
      if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
      end
      self:UnregisterEvent("ADDON_LOADED")
      self:SetScript("OnEvent", nil)
    end
  end)
end

-- Options panel handlers
panel.refresh = UpdateOptionsControls
panel.okay = function()
  local settings = EnsureAccountSettings()
  settings.showHome = panel.showHome and panel.showHome:GetChecked() or defaults.showHome
  settings.showWorld = panel.showWorld and panel.showWorld:GetChecked() or defaults.showWorld
  settings.showFPS = panel.showFPS and panel.showFPS:GetChecked() or defaults.showFPS
  settings.compact = panel.compact and panel.compact:GetChecked() or defaults.compact
  settings.fontSize = panel.fontSlider and panel.fontSlider:GetValue() or defaults.fontSize
  settings.fontFace = panel.fontDropdown and UIDropDownMenu_GetSelectedValue(panel.fontDropdown) or defaults.fontFace
  settings.borderless = panel.borderless and panel.borderless:GetChecked() or defaults.borderless
  settings.locked = panel.lockFrame and panel.lockFrame:GetChecked() or defaults.locked
  settings.frameAlpha = panel.alphaSlider and panel.alphaSlider:GetValue() or defaults.frameAlpha
  settings.updateInterval = panel.intervalSlider and panel.intervalSlider:GetValue() or defaults.updateInterval
  local currentColor = settings.backgroundColor or defaults.backgroundColor
  settings.backgroundColor = { r = currentColor.r or 0, g = currentColor.g or 0, b = currentColor.b or 0 }
  ApplySettings()
end
panel.default = function()
  NetFPSDB = NetFPSDB or {}
  NetFPSDB.account = NetFPSDB.account or {}
  NetFPSDB.account.settings = CloneDefaults()
  UpdateOptionsControls()
  ApplySettings()
end

-- Try to register options now that panel/handlers exist
RegisterOptionsPanel()

-- Simple standalone show/hide for options if Blizzard Interface Options unavailable
local function ShowOptionsWindow()
  UpdateOptionsControls()
  panel:Show()
end

-- Add basic Close and Apply buttons to the panel so it can act standalone
do
  local close = CreateFrame("Button", "NetFPSTrackerOptions_Close", panel, "UIPanelButtonTemplate")
  close:SetSize(80, 22)
  close:SetPoint("BOTTOMRIGHT", -16, 12)
  close:SetText("Close")
  close:SetScript("OnClick", function() panel:Hide() end)

  local apply = CreateFrame("Button", "NetFPSTrackerOptions_Apply", panel, "UIPanelButtonTemplate")
  apply:SetSize(80, 22)
  apply:SetPoint("BOTTOMRIGHT", close, "BOTTOMLEFT", -8, 0)
  apply:SetText("Apply")
  apply:SetScript("OnClick", function()
    if panel.okay then panel.okay() end
    print("NetFPSTracker: settings applied")
  end)
  panel.close = close
  panel.apply = apply
end

AdjustOptionsPanelSize()
panel:SetScript("OnShow", AdjustOptionsPanelSize)

-- Slash commands
SLASH_NETFPSTRACKER1 = "/netfps"
SlashCmdList["NETFPSTRACKER"] = function(msg)
  msg = (msg or ""):lower():gsub("^%s*(.-)%s*$", "%1")
  if msg == "reset" or msg == "r" then
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    NetFPSDB = NetFPSDB or {}
    NetFPSDB.pos = { 0, 0 }
    print("NetFPSTracker: position reset.")
  elseif msg == "hide" then
    frame:Hide()
    print("NetFPSTracker: hidden. Use /netfps show to show.")
  elseif msg == "show" then
    frame:Show()
    print("NetFPSTracker: shown.")
  elseif msg == "lock" then
    ToggleLockState(true)
    print("NetFPSTracker: frame locked.")
  elseif msg == "unlock" then
    ToggleLockState(false)
    print("NetFPSTracker: frame unlocked.")
  elseif msg == "options" or msg == "opt" then
    -- Safely open the Interface Options panel for this addon
    if type(InterfaceOptionsFrame_OpenToCategory) == "function" then
      -- Blizzard quirk: call twice to ensure panel opens
      InterfaceOptionsFrame_OpenToCategory(panel)
      InterfaceOptionsFrame_OpenToCategory(panel)
    else
      -- Try to ensure our category is registered, then attempt again
      if type(RegisterOptionsPanel) == "function" then
        RegisterOptionsPanel()
      end
      if type(InterfaceOptionsFrame_OpenToCategory) == "function" then
        InterfaceOptionsFrame_OpenToCategory(panel)
        InterfaceOptionsFrame_OpenToCategory(panel)
      else
        -- Last-resort fallback: show our standalone options window if Interface Options are unavailable
        if type(InterfaceOptionsFrame_OpenToCategory) ~= "function" then
          ShowOptionsWindow()
          print("NetFPSTracker: Opened built-in options window.")
        elseif type(InterfaceOptionsFrame) == "table" or type(InterfaceOptionsFrame) == "userdata" then
          InterfaceOptionsFrame:Show()
          print("NetFPSTracker: Open Interface Options and select 'NetFPSTracker' under AddOns.")
        else
          print("NetFPSTracker: Interface Options unavailable right now. Open the built-in options with /netfps options later.")
        end
      end
    end
  else
    print("NetFPSTracker commands: /netfps reset | show | hide | lock | unlock | options")
  end
end
