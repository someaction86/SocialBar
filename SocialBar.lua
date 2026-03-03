-- SocialBar.lua
-- Movable Friends/Guild bar with full customization

-- ============================================================
-- Saved Variables & Defaults
-- ============================================================
SocialBarDB = SocialBarDB or {}

local defaults = {
    x           = 200,
    y           = -200,
    point       = "TOPLEFT",
    relPoint    = "TOPLEFT",
    barA        = 0.85,
    fontSize    = 11,
    layout      = "horizontal",
    showCount   = true,
    showStatus  = true,
    showLevel   = true,
    showClass   = true,
}

local function GetSetting(key)
    if SocialBarDB[key] ~= nil then return SocialBarDB[key] end
    return defaults[key]
end

local function SetSetting(key, val)
    SocialBarDB[key] = val
end

-- ============================================================
-- Caches
-- ============================================================
local friendsCache = {}
local guildCache   = {}

local function RefreshFriendsCache()
    friendsCache = {}
    local total = BNGetNumFriends()
    for i = 1, total do
        local acc = C_BattleNet.GetFriendAccountInfo(i)
        if acc then
            local game = acc.gameAccountInfo
            if game and game.isOnline and game.clientProgram == "WoW" and game.wowProjectID == 1 then
                local status = ""
                if game.isGameBusy then
                    status = "dnd"
                elseif game.isGameAFK then
                    status = "afk"
                elseif acc.isDND then
                    status = "dnd"
                elseif acc.isAFK then
                    status = "afk"
                end
                friendsCache[#friendsCache + 1] = {
                    name       = game.characterName or "Unknown",
                    realm      = game.realmName or "",
                    battleTag  = acc.battleTag or "",
                    classKey   = (game.className or ""):upper():gsub("%s+", ""),
                    className  = game.className or "",
                    level      = game.characterLevel or 0,
                    zone       = game.areaName or "",
                    presenceID = acc.bnetAccountID,
                    playerGuid = game.playerGuid,
                    status     = status,
                }
            end
        end
    end
end

local function RefreshGuildCache()
    guildCache = {}
    if not IsInGuild() then return end
    local total = GetNumGuildMembers()
    for i = 1, total do
        local name, rank, _, level, class, zone, _, _, online, status = GetGuildRosterInfo(i)
        if online and name then
            local shortName, realm = name:match("^([^%-]+)-(.+)$")
            if not shortName then
                shortName = name
                realm = GetRealmName()
            end
            local memberStatus = ""
            if status == 1 then
                memberStatus = "afk"
            elseif status == 2 then
                memberStatus = "dnd"
            end
            guildCache[#guildCache + 1] = {
                name      = shortName,
                realm     = realm,
                rank      = rank or "",
                classKey  = (class or ""):upper():gsub("%s+", ""),
                className = class or "",
                level     = level or 0,
                zone      = zone or "",
                status    = memberStatus,
            }
        end
    end
end

-- ============================================================
-- Bar & Button references (forward declared for ApplySettings)
-- ============================================================
local bar, bg
local friendsBtn, guildBtn
local friendsBtnBg, guildBtnBg
local friendsText, guildText
local gearBtn

-- ============================================================
-- Apply Settings (called on load and after any change)
-- ============================================================
local function ApplySettings()
    local layout    = GetSetting("layout")
    local fontSize  = GetSetting("fontSize")
    local showCount = GetSetting("showCount")
    local a         = GetSetting("barA")

    bg:SetColorTexture(0, 0, 0, a)

    if layout == "vertical" then
        -- vertical: Friends / Guild stacked, gear icon small and centered at bottom
        bar:SetSize(100, 80)
        friendsBtn:ClearAllPoints()
        friendsBtn:SetPoint("TOP", bar, "TOP", 0, -4)
        friendsBtn:SetSize(90, 22)
        guildBtn:ClearAllPoints()
        guildBtn:SetPoint("TOP", bar, "TOP", 0, -28)
        guildBtn:SetSize(90, 22)
        if gearBtn then
            gearBtn:ClearAllPoints()
            gearBtn:SetPoint("TOP", bar, "TOP", 0, -56)
            gearBtn:SetSize(18, 18)
        end
    else
        -- horizontal: Friends / Guild side by side, gear icon on the right
        bar:SetSize(182, 28)
        friendsBtn:ClearAllPoints()
        friendsBtn:SetPoint("LEFT", bar, "LEFT", 4, 0)
        friendsBtn:SetSize(74, 22)
        guildBtn:ClearAllPoints()
        guildBtn:SetPoint("LEFT", bar, "LEFT", 82, 0)
        guildBtn:SetSize(74, 22)
        if gearBtn then
            gearBtn:ClearAllPoints()
            gearBtn:SetPoint("LEFT", bar, "LEFT", 161, 0)
            gearBtn:SetSize(18, 18)
        end
    end

    local font, _, flags = friendsText:GetFont()
    friendsText:SetFont(font or "Fonts\\FRIZQT__.TTF", fontSize, flags or "")
    guildText:SetFont(font or "Fonts\\FRIZQT__.TTF", fontSize, flags or "")

    local fCount = showCount and (" |cffaaaaaa(" .. #friendsCache .. ")|r") or ""
    local gCount = showCount and (" |cffaaaaaa(" .. #guildCache .. ")|r") or ""
    friendsText:SetText("|cff00ccffFriends|r" .. fCount)
    guildText:SetText("|cff00ff44Guild|r" .. gCount)
end

-- ============================================================
-- Bar Frame
-- ============================================================
bar = CreateFrame("Frame", "SocialBarFrame", UIParent)
bar:SetSize(182, 28)
bar:SetFrameStrata("MEDIUM")
bar:SetMovable(true)
bar:EnableMouse(true)
bar:RegisterForDrag("LeftButton")
bar:SetScript("OnDragStart", bar.StartMoving)
bar:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    SetSetting("point",    point)
    SetSetting("relPoint", relPoint)
    SetSetting("x",        x)
    SetSetting("y",        y)
end)

bg = bar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints()
bg:SetColorTexture(0, 0, 0, 0.85)

local function RestorePosition()
    bar:ClearAllPoints()
    bar:SetPoint(
        GetSetting("point"), UIParent, GetSetting("relPoint"),
        GetSetting("x"), GetSetting("y")
    )
end

-- ============================================================
-- Tooltips
-- ============================================================
local function GetStatusTag(status)
    if status == "afk" then
        return " |cffff9900[AFK]|r"
    elseif status == "dnd" then
        return " |cffff4444[DND]|r"
    end
    return ""
end

local function GetClassHex(classKey)
    if classKey and classKey ~= "" then
        local color = C_ClassColor.GetClassColor(classKey)
        if color then
            return color:GenerateHexColorMarkup()
        end
        local rc = RAID_CLASS_COLORS[classKey]
        if rc then
            return string.format("|cff%02x%02x%02x", rc.r*255, rc.g*255, rc.b*255)
        end
    end
    return "|cffffffff"
end

local function ShowFriendsTooltip(anchor)
    GameTooltip:SetOwner(anchor, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cff00ccffFriends Online (" .. #friendsCache .. ")|r")
    GameTooltip:AddLine(" ")
    if #friendsCache == 0 then
        GameTooltip:AddLine("|cff888888No friends online in WoW Retail.|r")
    else
        local showStatus = GetSetting("showStatus")
        local showLevel  = GetSetting("showLevel")
        local showClass  = GetSetting("showClass")
        for _, f in ipairs(friendsCache) do
            local hex = GetClassHex(f.classKey)
            local isCrossRealm = f.realm ~= "" and f.realm ~= GetRealmName()
            local realmSuffix = isCrossRealm and ("|cff666666-" .. f.realm .. "|r") or ""
            local statusTag   = showStatus and GetStatusTag(f.status) or ""
            local zone        = f.zone ~= "" and ("|cffaaaaaa - " .. f.zone .. "|r") or ""
            local infoTag = ""
            if showLevel or showClass then
                local parts = {}
                if showLevel and f.level > 0 then
                    parts[#parts + 1] = "Lvl " .. f.level
                end
                if showClass and f.className ~= "" then
                    parts[#parts + 1] = f.className
                end
                if #parts > 0 then
                    infoTag = " |cff888888(" .. table.concat(parts, " ") .. ")|r"
                end
            end
            GameTooltip:AddLine(hex .. f.name .. "|r" .. realmSuffix .. statusTag .. infoTag .. zone)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffddddddRight-click to invite|r")
    GameTooltip:Show()
end

local function ShowGuildTooltip(anchor)
    GameTooltip:SetOwner(anchor, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    if not IsInGuild() then
        GameTooltip:AddLine("|cffff4444Not in a guild.|r")
        GameTooltip:Show()
        return
    end
    GameTooltip:AddLine("|cff00ff44Guild Online (" .. #guildCache .. ")|r")
    GameTooltip:AddLine(" ")
    if #guildCache == 0 then
        GameTooltip:AddLine("|cff888888No guild members online.|r")
    else
        local showStatus = GetSetting("showStatus")
        local showLevel  = GetSetting("showLevel")
        local showClass  = GetSetting("showClass")
        for _, m in ipairs(guildCache) do
            local hex = GetClassHex(m.classKey)
            local zone      = m.zone ~= "" and ("|cffaaaaaa - " .. m.zone .. "|r") or ""
            local statusTag = showStatus and GetStatusTag(m.status) or ""
            local infoTag = ""
            if showLevel or showClass then
                local parts = {}
                if showLevel and m.level > 0 then
                    parts[#parts + 1] = "Lvl " .. m.level
                end
                if showClass and m.className ~= "" then
                    parts[#parts + 1] = m.className
                end
                if #parts > 0 then
                    infoTag = " |cff888888(" .. table.concat(parts, " ") .. ")|r"
                end
            end
            GameTooltip:AddLine(hex .. m.name .. "|r |cff888888(" .. m.rank .. ")|r" .. statusTag .. infoTag .. zone)
        end
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffddddddRight-click to invite|r")
    GameTooltip:Show()
end

-- ============================================================
-- Dropdowns: Invite menus
-- ============================================================
local friendsDropdown = CreateFrame("Frame", "SocialBarFriendsDropdown", UIParent, "UIDropDownMenuTemplate")
local function FriendsDropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "Invite Friend"; info.isTitle = true; info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)
    if #friendsCache == 0 then
        info = UIDropDownMenu_CreateInfo()
        info.text = "No friends online in WoW"; info.disabled = true; info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        return
    end
    for _, f in ipairs(friendsCache) do
        info = UIDropDownMenu_CreateInfo()
        local isCrossRealm = f.realm ~= "" and f.realm ~= GetRealmName()
        info.text = isCrossRealm and (f.name .. " (" .. f.realm .. ")") or f.name
        info.notCheckable = true
        local inviteName = f.realm ~= "" and (f.name .. "-" .. f.realm) or f.name
        info.func = function()
            print("|cff00ccffSocialBar|r: Inviting " .. inviteName)
            local ok, err = pcall(C_PartyInfo.InviteUnit, inviteName)
            if not ok then
                print("|cffff0000SocialBar invite error:|r " .. tostring(err))
            end
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

local guildDropdown = CreateFrame("Frame", "SocialBarGuildDropdown", UIParent, "UIDropDownMenuTemplate")
local function GuildDropdown_Initialize(self, level)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "Invite Guild Member"; info.isTitle = true; info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)
    if not IsInGuild() or #guildCache == 0 then
        info = UIDropDownMenu_CreateInfo()
        info.text = IsInGuild() and "No members online" or "Not in a guild"
        info.disabled = true; info.notCheckable = true
        UIDropDownMenu_AddButton(info, level)
        return
    end
    for _, m in ipairs(guildCache) do
        info = UIDropDownMenu_CreateInfo()
        info.text = m.name; info.notCheckable = true
        local n = m.name
        local r = m.realm
        info.func = function()
            local inviteName = n .. "-" .. r
            print("|cff00ccffSocialBar|r: Inviting " .. inviteName)
            local ok, err = pcall(C_PartyInfo.InviteUnit, inviteName)
            if not ok then
                print("|cffff0000SocialBar invite error:|r " .. tostring(err))
            end
        end
        UIDropDownMenu_AddButton(info, level)
    end
end

-- ============================================================
-- Config Panel (Interface > AddOns)
-- ============================================================
local configPanel = CreateFrame("Frame")
configPanel.name = "SocialBar"

local panelTitle = configPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
panelTitle:SetPoint("TOPLEFT", 16, -16)
panelTitle:SetText("SocialBar Options")

local panelSub = configPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
panelSub:SetPoint("TOPLEFT", panelTitle, "BOTTOMLEFT", 0, -4)
panelSub:SetText("You can also right-click the bar or use /socialbar config")

local function MakeSectionLabel(parent, text, anchorTo, offsetY)
    local lbl = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    lbl:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, offsetY or -12)
    lbl:SetText(text)
    return lbl
end

local function MakeCheckbox(parent, label, anchorTo, offsetY, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", -2, offsetY or -8)
    cb.text:SetText(label)
    cb:SetChecked(getter())
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked())
        ApplySettings()
    end)
    return cb
end

local function MakeSlider(parent, label, min, max, step, anchorTo, offsetY, getter, setter)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(200, 40)
    f:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, offsetY or -20)
    local sl = CreateFrame("Slider", nil, f, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    sl:SetWidth(200)
    sl:SetMinMaxValues(min, max)
    sl:SetValueStep(step)
    sl:SetValue(getter())
    sl.Low:SetText(tostring(min))
    sl.High:SetText(tostring(max))
    sl.Text:SetText(label .. ": " .. getter())
    sl:SetScript("OnValueChanged", function(self, val)
        val = math.floor(val / step + 0.5) * step
        self.Text:SetText(label .. ": " .. val)
        setter(val)
        ApplySettings()
    end)
    return f, sl
end

-- Build the panel UI
local sec1 = MakeSectionLabel(configPanel, "General", panelSub, -20)

local cbCount = MakeCheckbox(configPanel, "Show online count on buttons", sec1, -8,
    function() return GetSetting("showCount") end,
    function(v) SetSetting("showCount", v) end)

local sec1b = MakeSectionLabel(configPanel, "Tooltip Info", cbCount, -16)

local cbStatus = MakeCheckbox(configPanel, "Show AFK / DND status", sec1b, -8,
    function() return GetSetting("showStatus") end,
    function(v) SetSetting("showStatus", v) end)

local cbLevel = MakeCheckbox(configPanel, "Show character level", cbStatus, -4,
    function() return GetSetting("showLevel") end,
    function(v) SetSetting("showLevel", v) end)

local cbClass = MakeCheckbox(configPanel, "Show character class", cbLevel, -4,
    function() return GetSetting("showClass") end,
    function(v) SetSetting("showClass", v) end)

local sec2 = MakeSectionLabel(configPanel, "Layout", cbClass, -16)

local cbLayout = MakeCheckbox(configPanel, "Vertical layout (stacked buttons)", sec2, -8,
    function() return GetSetting("layout") == "vertical" end,
    function(v) SetSetting("layout", v and "vertical" or "horizontal") end)

local sec3 = MakeSectionLabel(configPanel, "Appearance", cbLayout, -16)

local alphaFrame, alphaSlider = MakeSlider(configPanel, "Transparency", 1, 10, 1, sec3, -8,
    function() return math.floor((1 - GetSetting("barA")) * 10 + 0.5) end,
    function(v) SetSetting("barA", 1 - v/10) end)

local fontFrame, fontSlider = MakeSlider(configPanel, "Font Size", 8, 18, 1, alphaFrame, -16,
    function() return GetSetting("fontSize") end,
    function(v) SetSetting("fontSize", v) end)

local resetBtn = CreateFrame("Button", nil, configPanel, "UIPanelButtonTemplate")
resetBtn:SetSize(140, 24)
resetBtn:SetPoint("TOPLEFT", fontFrame, "BOTTOMLEFT", 0, -20)
resetBtn:SetText("Reset Position")
resetBtn:SetScript("OnClick", function()
    SetSetting("x", defaults.x)
    SetSetting("y", defaults.y)
    SetSetting("point", defaults.point)
    SetSetting("relPoint", defaults.relPoint)
    RestorePosition()
    print("|cff00ccffSocialBar|r: Position reset.")
end)

-- Register with Blizzard's Interface > AddOns panel
local category = Settings.RegisterCanvasLayoutCategory(configPanel, "SocialBar")
Settings.RegisterAddOnCategory(category)

local function OpenSettingsPanel()
    Settings.OpenToCategory(category:GetID())
end

-- ============================================================
-- Right-click config menu on the bar background
-- ============================================================
local barMenu = CreateFrame("Frame", "SocialBarConfigDropdown", UIParent, "UIDropDownMenuTemplate")

local function BarMenu_Initialize(self, level)
    local info

    info = UIDropDownMenu_CreateInfo()
    info.text = "SocialBar Options"; info.isTitle = true; info.notCheckable = true
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    local isVert = GetSetting("layout") == "vertical"
    info.text = isVert and "Switch to Horizontal" or "Switch to Vertical"
    info.notCheckable = true
    info.func = function()
        SetSetting("layout", isVert and "horizontal" or "vertical")
        ApplySettings()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = GetSetting("showCount") and "Hide Online Count" or "Show Online Count"
    info.notCheckable = true
    info.func = function()
        SetSetting("showCount", not GetSetting("showCount"))
        ApplySettings()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = GetSetting("showStatus") and "Hide AFK/DND Status" or "Show AFK/DND Status"
    info.notCheckable = true
    info.func = function()
        SetSetting("showStatus", not GetSetting("showStatus"))
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = GetSetting("showLevel") and "Hide Character Level" or "Show Character Level"
    info.notCheckable = true
    info.func = function()
        SetSetting("showLevel", not GetSetting("showLevel"))
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = GetSetting("showClass") and "Hide Character Class" or "Show Character Class"
    info.notCheckable = true
    info.func = function()
        SetSetting("showClass", not GetSetting("showClass"))
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "Font Size +"; info.notCheckable = true
    info.func = function()
        local s = math.min(18, GetSetting("fontSize") + 1)
        SetSetting("fontSize", s)
        ApplySettings()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "Font Size -"; info.notCheckable = true
    info.func = function()
        local s = math.max(8, GetSetting("fontSize") - 1)
        SetSetting("fontSize", s)
        ApplySettings()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "More Transparent"; info.notCheckable = true
    info.func = function()
        local a = math.max(0.1, GetSetting("barA") - 0.1)
        SetSetting("barA", a)
        ApplySettings()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "Less Transparent"; info.notCheckable = true
    info.func = function()
        local a = math.min(1.0, GetSetting("barA") + 0.1)
        SetSetting("barA", a)
        ApplySettings()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "|cffaaaaaa Open Full Settings...|r"; info.notCheckable = true
    info.func = function()
        OpenSettingsPanel()
    end
    UIDropDownMenu_AddButton(info, level)

    info = UIDropDownMenu_CreateInfo()
    info.text = "Reset Position"; info.notCheckable = true
    info.func = function()
        SetSetting("x", defaults.x); SetSetting("y", defaults.y)
        SetSetting("point", defaults.point); SetSetting("relPoint", defaults.relPoint)
        RestorePosition()
        print("|cff00ccffSocialBar|r: Position reset.")
    end
    UIDropDownMenu_AddButton(info, level)
end

bar:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        if MouseIsOver(friendsBtn) or MouseIsOver(guildBtn) or MouseIsOver(gearBtn) then return end
        UIDropDownMenu_Initialize(barMenu, BarMenu_Initialize)
        ToggleDropDownMenu(1, nil, barMenu, self, 0, 0)
    end
end)

-- ============================================================
-- Buttons
-- ============================================================
local function CreateBarButton(parent, xOffset)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(74, 22)
    btn:SetPoint("LEFT", parent, "LEFT", xOffset, 0)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.08)
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetAllPoints()
    return btn, nil, text
end

friendsBtn, friendsBtnBg, friendsText = CreateBarButton(bar, 4)
friendsText:SetText("|cff00ccffFriends|r")

friendsBtn:RegisterForDrag("LeftButton")
friendsBtn:SetScript("OnDragStart", function() bar:StartMoving() end)
friendsBtn:SetScript("OnDragStop", function()
    bar:StopMovingOrSizing()
    local point, _, relPoint, x, y = bar:GetPoint()
    SetSetting("point",    point)
    SetSetting("relPoint", relPoint)
    SetSetting("x",        x)
    SetSetting("y",        y)
end)
friendsBtn:SetScript("OnEnter", function(self)
    RefreshFriendsCache()
    ShowFriendsTooltip(self)
end)
friendsBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
friendsBtn:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        GameTooltip:Hide()
        RefreshFriendsCache()
        UIDropDownMenu_Initialize(friendsDropdown, FriendsDropdown_Initialize)
        ToggleDropDownMenu(1, nil, friendsDropdown, self, 0, -4)
    end
    return true
end)

guildBtn, guildBtnBg, guildText = CreateBarButton(bar, 82)
guildText:SetText("|cff00ff44Guild|r")

guildBtn:RegisterForDrag("LeftButton")
guildBtn:SetScript("OnDragStart", function() bar:StartMoving() end)
guildBtn:SetScript("OnDragStop", function()
    bar:StopMovingOrSizing()
    local point, _, relPoint, x, y = bar:GetPoint()
    SetSetting("point",    point)
    SetSetting("relPoint", relPoint)
    SetSetting("x",        x)
    SetSetting("y",        y)
end)
guildBtn:SetScript("OnEnter", function(self)
    RefreshGuildCache()
    ShowGuildTooltip(self)
end)
guildBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
guildBtn:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        GameTooltip:Hide()
        RefreshGuildCache()
        UIDropDownMenu_Initialize(guildDropdown, GuildDropdown_Initialize)
        ToggleDropDownMenu(1, nil, guildDropdown, self, 0, -4)
    end
    return true
end)

-- ============================================================
-- Gear Button
-- ============================================================
gearBtn = CreateFrame("Button", nil, bar)
gearBtn:SetSize(18, 18)
gearBtn:SetPoint("LEFT", bar, "LEFT", 161, 0)
gearBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
gearBtn:RegisterForDrag("LeftButton")
gearBtn:SetScript("OnDragStart", function() bar:StartMoving() end)
gearBtn:SetScript("OnDragStop", function()
    bar:StopMovingOrSizing()
    local point, _, relPoint, x, y = bar:GetPoint()
    SetSetting("point",    point)
    SetSetting("relPoint", relPoint)
    SetSetting("x",        x)
    SetSetting("y",        y)
end)

local gearIcon = gearBtn:CreateTexture(nil, "ARTWORK")
gearIcon:SetAllPoints()
gearIcon:SetTexture("Interface\\GossipFrame\\GossipGossipIcon")

local gearHl = gearBtn:CreateTexture(nil, "HIGHLIGHT")
gearHl:SetAllPoints()
gearHl:SetColorTexture(1, 1, 1, 0.2)

gearBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cff00ccffSocialBar Settings|r")
    GameTooltip:AddLine("|cffaaaaaaLeft-click: Quick settings|r")
    GameTooltip:AddLine("|cffaaaaaaRight-click: Full settings panel|r")
    GameTooltip:Show()
end)
gearBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
gearBtn:SetScript("OnClick", function(self, button)
    GameTooltip:Hide()
    if button == "RightButton" then
        OpenSettingsPanel()
    else
        UIDropDownMenu_Initialize(barMenu, BarMenu_Initialize)
        ToggleDropDownMenu(1, nil, barMenu, self, 0, -4)
    end
    return true
end)

-- ============================================================
-- Events
-- ============================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("FRIENDLIST_UPDATE")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("BN_FRIEND_LIST_SIZE_CHANGED")
eventFrame:RegisterEvent("BN_CONNECTED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        RestorePosition()
        C_GuildInfo.GuildRoster()
        RefreshFriendsCache()
        RefreshGuildCache()
        ApplySettings()
        print("|cff00ccffSocialBar|r loaded! Right-click the bar to customize, or go to Interface > AddOns > SocialBar.")
    elseif event == "FRIENDLIST_UPDATE" or event == "BN_FRIEND_LIST_SIZE_CHANGED" or event == "BN_CONNECTED" then
        RefreshFriendsCache()
        ApplySettings()
        if GameTooltip:IsShown() and GameTooltip:GetOwner() == friendsBtn then
            ShowFriendsTooltip(friendsBtn)
        end
    elseif event == "GUILD_ROSTER_UPDATE" then
        RefreshGuildCache()
        ApplySettings()
        if GameTooltip:IsShown() and GameTooltip:GetOwner() == guildBtn then
            ShowGuildTooltip(guildBtn)
        end
    end
end)

-- ============================================================
-- /socialbar config  ->  open settings panel
-- /socialbar reset   ->  reset position
-- ============================================================
SLASH_SOCIALBAR1 = "/socialbar"
SlashCmdList["SOCIALBAR"] = function(msg)
    if msg == "config" then
        OpenSettingsPanel()
    elseif msg == "reset" then
        SetSetting("x", defaults.x); SetSetting("y", defaults.y)
        SetSetting("point", defaults.point); SetSetting("relPoint", defaults.relPoint)
        RestorePosition()
        print("|cff00ccffSocialBar|r: Position reset.")
    else
        print("|cff00ccffSocialBar|r commands:")
        print("  |cffaaaaaa/socialbar config|r  - Open settings panel")
        print("  |cffaaaaaa/socialbar reset|r   - Reset bar position")
        print("  Right-click the bar for quick options.")
    end
end

-- ============================================================
-- /sbdebug  ->  BNet diagnostic
-- ============================================================
SLASH_SBDEBUG1 = "/sbdebug"
SlashCmdList["SBDEBUG"] = function()
    print("|cffff9900== SocialBar Debug ==|r")
    local total, online = BNGetNumFriends()
    print("BNGetNumFriends() total=" .. tostring(total) .. " online=" .. tostring(online))
    local wowCount = 0
    for i = 1, total do
        local acc = C_BattleNet.GetFriendAccountInfo(i)
        if acc then
            local game = acc.gameAccountInfo
            if game and game.isOnline and game.clientProgram == "WoW" then
                wowCount = wowCount + 1
                if wowCount <= 3 then
                    print("--- WoW Friend #" .. i .. " ---")
                    print("  acc fields:")
                    for k, v in pairs(acc) do
                        if type(v) ~= "table" then
                            print("    acc." .. tostring(k) .. " = " .. tostring(v))
                        end
                    end
                    print("  gameAccountInfo fields:")
                    for k, v in pairs(game) do
                        if type(v) ~= "table" then
                            print("    game." .. tostring(k) .. " = " .. tostring(v))
                        end
                    end
                end
            end
        end
    end
    print("Total WoW friends online: " .. wowCount)
    print("friendsCache=" .. #friendsCache .. " guildCache=" .. #guildCache)
    print("|cffff9900== End ==|r")
end
