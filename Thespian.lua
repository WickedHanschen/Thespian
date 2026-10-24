--[[---------------------------------------------------------------------------
  Thespian
  One-click roleplay emotes with support for custom emotes.
  Works on Retail, Classic Era / Hardcore / Seasonal, Anniversary and MoP Classic.
  Slash commands: /thespian  (aliases: /rpe, /rpemotes)
---------------------------------------------------------------------------]]--

local ADDON_NAME = ...

local DB
local BackdropTemplate = BackdropTemplateMixin and "BackdropTemplate" or nil
local atan2 = math.atan2 or math.atan

local PREFIX = "|cffffd100Thespian:|r "
local function Print(msg) print(PREFIX .. msg) end

local function Trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

--------------------------------------------------------------------------------
-- Emote types
--------------------------------------------------------------------------------
local TYPES = {
    { key = "emote", name = "Emote (/me)",    channel = "EMOTE" },
    { key = "say",   name = "Say",            channel = "SAY"   },
    { key = "yell",  name = "Yell",           channel = "YELL"  },
    { key = "party", name = "Party",          channel = "PARTY" },
    { key = "token", name = "Standard emote" },
}
local TYPE_INDEX = {}
for i, t in ipairs(TYPES) do TYPE_INDEX[t.key] = i end

--------------------------------------------------------------------------------
-- Presets  (%t = your target's name, or "someone" if you have no target)
--------------------------------------------------------------------------------
local function E(label, text) return { label = label, kind = "emote", text = text } end
local function S(label, text) return { label = label, kind = "say",   text = text } end
local function Y(label, text) return { label = label, kind = "yell",  text = text } end
local function T(label, token) return { label = label, kind = "token", text = token } end

local CATEGORIES = { "Greetings", "Gestures", "Emotions", "Actions", "Speech", "Custom" }

local PRESETS = {
    Greetings = {
        T("Wave", "WAVE"), T("Bow", "BOW"), T("Salute", "SALUTE"),
        T("Kneel", "KNEEL"), T("Hello", "HELLO"), T("Welcome", "WELCOME"),
        T("Goodbye", "BYE"),
        E("Nod Hello", "nods in greeting to %t."),
        E("Tip Hat", "tips their hat to %t."),
        E("Raise Hand", "raises a hand in greeting."),
        E("Warm Smile", "gives %t a warm smile."),
        E("Clasp Arms", "clasps forearms with %t in a firm greeting."),
        E("Slight Bow", "bows slightly in farewell."),
        S("Well Met", "Well met, friend!"),
        S("Safe Travels", "Safe travels, friend. May we meet again."),
    },
    Gestures = {
        T("Nod", "NOD"), T("Shake Head", "NO"), T("Shrug", "SHRUG"),
        T("Point", "POINT"), T("Beckon", "BECKON"), T("Clap", "CLAP"),
        E("Cross Arms", "crosses their arms and watches carefully."),
        E("Stroke Chin", "strokes their chin thoughtfully."),
        E("Hand on Weapon", "rests a hand on the hilt of their weapon."),
        E("Hands Behind", "clasps their hands behind their back."),
        E("Raise Eyebrow", "raises an eyebrow, unconvinced."),
        E("Tap Foot", "taps their foot impatiently."),
        E("Lean Back", "leans back casually, arms folded."),
        E("Come Closer", "beckons %t closer with a finger."),
        E("Wave Off", "waves a dismissive hand."),
    },
    Emotions = {
        T("Laugh", "LAUGH"), T("Chuckle", "CHUCKLE"), T("Cry", "CRY"),
        T("Cheer", "CHEER"), T("Blush", "BLUSH"), T("Grin", "GRIN"),
        E("Sigh", "lets out a deep, weary sigh."),
        E("Smirk", "smirks knowingly."),
        E("Frown", "frowns, brow furrowed with worry."),
        E("Glare", "glares at %t coldly."),
        E("Surprised", "eyes widen in surprise."),
        E("Tremble", "trembles, struggling to hold back fear."),
        E("Tears Up", "blinks back tears, voice catching."),
        E("Shiver", "shivers as a cold wind passes by."),
    },
    Actions = {
        T("Sit", "SIT"), T("Sleep", "SLEEP"), T("Dance", "DANCE"),
        T("Eat", "EAT"), T("Drink", "DRINK"), T("Flex", "FLEX"),
        E("Read Tome", "reads carefully from an old, worn tome."),
        E("Sharpen Blade", "sharpens their blade with slow, practiced strokes."),
        E("Polish Armor", "polishes their armor until it gleams."),
        E("Raise Tankard", "raises a tankard in toast."),
        E("Study Map", "unrolls a map and studies it closely."),
        E("Examine Ground", "kneels down to examine the ground."),
        E("Scan Area", "scans the surroundings warily."),
        E("Stretch", "stretches and cracks their knuckles."),
        E("Pour Drink", "pours a drink and slides it across the table."),
    },
    Speech = {
        S("Excuse Me", "Excuse me, might I have a moment?"),
        S("Ahem", "*clears throat* Ahem."),
        S("No Harm", "I mean no harm."),
        S("Follow Me", "Follow me, and stay close."),
        S("Thank You", "You have my thanks."),
        S("Light Guide You", "May the Light guide your path."),
        S("Of Course", "Of course. Please, go ahead."),
        S("Indeed", "Indeed."),
        S("Hold On", "Hold on, give me a moment."),
        Y("To Arms!", "To arms!"),
        Y("Hold the Line!", "Hold the line!"),
        Y("Stand Ready!", "Stand ready!"),
        Y("Look Out!", "Look out!"),
        S("OOC: BRB", "(( brb ))"),
        S("OOC: Back", "(( back ))"),
    },
    Custom = {},
}

--------------------------------------------------------------------------------
-- Sending
--------------------------------------------------------------------------------
local function ExpandTokens(text)
    local target = UnitName("target") or "someone"
    return (text:gsub("%%t", function() return target end))
end

local function StripMe(text)
    text = text:gsub("^/me%s+", "")
    text = text:gsub("^/emote%s+", "")
    return text
end

local function Perform(kind, text)
    if not text or text == "" then return end

    if kind == "token" then
        DoEmote((text:upper():gsub("[^%w_]", "")))
        return
    end

    text = ExpandTokens(text)
    if kind == "emote" then text = StripMe(text) end
    text = text:sub(1, 255)

    local channel = TYPES[TYPE_INDEX[kind]].channel
    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    send(text, channel)
end

local function BuildPreview(kind, text)
    if not text or text == "" then return "" end
    local name = UnitName("player") or "You"
    if kind == "token" then
        return "|cffffd100/" .. text:lower():gsub("[^%w_]", "") .. "|r"
    elseif kind == "emote" then
        return "|cffff8040" .. name .. " " .. StripMe(ExpandTokens(text)) .. "|r"
    elseif kind == "say" then
        return "|cffffffff" .. name .. " says: " .. ExpandTokens(text) .. "|r"
    elseif kind == "yell" then
        return "|cffff4040" .. name .. " yells: " .. ExpandTokens(text) .. "|r"
    elseif kind == "party" then
        return "|cffaaaaff[Party] " .. name .. ": " .. ExpandTokens(text) .. "|r"
    end
    return text
end

--------------------------------------------------------------------------------
-- Styling
--------------------------------------------------------------------------------
local DIALOG_BACKDROP = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}
local PANEL_BACKDROP = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}

local function MakeDialog(name, width, height, titleText)
    local f = CreateFrame("Frame", name, UIParent, BackdropTemplate)
    f:SetSize(width, height)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetBackdrop(DIALOG_BACKDROP)

    local header = f:CreateTexture(nil, "ARTWORK")
    header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
    header:SetSize(300, 64)
    header:SetPoint("TOP", 0, 12)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOP", header, "TOP", 0, -14)
    f.title:SetText(titleText)

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    tinsert(UISpecialFrames, name)
    return f
end

local function MakeLabel(parent, text, x, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function MakeEditBox(parent, width, maxLetters)
    local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    eb:SetSize(width, 22)
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxLetters)
    eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return eb
end

--------------------------------------------------------------------------------
-- UI state
--------------------------------------------------------------------------------
local GRID_COLS, PER_PAGE = 3, 15
local BTN_W, BTN_H, GAP = 122, 30, 6

local mainFrame, editor
local gridButtons, tabButtons = {}, {}
local currentCat, currentPage = "Greetings", 1
local editingIndex, pendingDelete
local Refresh, OpenEditor, OpenOptions, ApplySettings, RefreshOptions

local function GetList(cat)
    local list = {}
    for _, e in ipairs(PRESETS[cat] or {}) do list[#list + 1] = e end
    for i, c in ipairs(DB.customs) do
        if c.cat == cat then
            list[#list + 1] = { label = c.label, kind = c.kind, text = c.text, customIndex = i }
        end
    end
    return list
end

--------------------------------------------------------------------------------
-- Main window
--------------------------------------------------------------------------------
local function SavePosition()
    local point, _, relPoint, x, y = mainFrame:GetPoint(1)
    DB.pos = { point, relPoint, x, y }
end

local function BuildMainFrame()
    local f = MakeDialog("ThespianFrame", 450, 384, "Thespian")
    mainFrame = f
    f:SetScript("OnDragStart", function(self) if not DB.locked then self:StartMoving() end end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePosition() end)
    f:SetScript("OnShow", function() Refresh() end)

    if DB.pos then
        f:SetPoint(DB.pos[1], UIParent, DB.pos[2], DB.pos[3], DB.pos[4])
    else
        f:SetPoint("CENTER")
    end
    f:SetScale(DB.scale or 1)
    f:Hide()

    -- Options button
    local optBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    optBtn:SetSize(62, 20)
    optBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -14)
    optBtn:SetText("Options")
    if GameFontNormalSmall then optBtn:SetNormalFontObject(GameFontNormalSmall) end
    if GameFontHighlightSmall then optBtn:SetHighlightFontObject(GameFontHighlightSmall) end
    optBtn:SetScript("OnClick", function() OpenOptions() end)

    -- Category tabs
    for i, cat in ipairs(CATEGORIES) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(64, 22)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", 24 + (i - 1) * 67, -38)
        b:SetText(cat)
        if GameFontNormalSmall then b:SetNormalFontObject(GameFontNormalSmall) end
        if GameFontHighlightSmall then b:SetHighlightFontObject(GameFontHighlightSmall) end
        b.cat = cat
        b:SetScript("OnClick", function(self)
            currentCat, currentPage = self.cat, 1
            Refresh()
        end)
        tabButtons[i] = b
    end

    -- Button panel
    local panel = CreateFrame("Frame", nil, f, BackdropTemplate)
    panel:SetPoint("TOPLEFT", 24, -66)
    panel:SetSize(402, 198)
    panel:SetBackdrop(PANEL_BACKDROP)
    panel:SetBackdropColor(0, 0, 0, 0.6)
    panel:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)

    f.empty = panel:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    f.empty:SetPoint("CENTER")
    f.empty:SetWidth(320)
    f.empty:SetText("Nothing here yet.\nClick \"New Emote\" below to create your own!")

    for i = 1, PER_PAGE do
        local col = (i - 1) % GRID_COLS
        local row = math.floor((i - 1) / GRID_COLS)
        local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        b:SetSize(BTN_W, BTN_H)
        b:SetPoint("TOPLEFT", 12 + col * (BTN_W + GAP), -10 - row * (BTN_H + GAP))
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        b:SetScript("OnClick", function(self, mouse)
            local e = self.entry
            if not e then return end
            if mouse == "RightButton" then
                if e.customIndex then OpenEditor(e.customIndex) end
            else
                Perform(e.kind, e.text)
                if DB.closeOnUse then mainFrame:Hide() end
            end
        end)
        b:SetScript("OnEnter", function(self)
            local e = self.entry
            if not e or DB.tooltips == false then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(e.label, 1, 1, 1)
            GameTooltip:AddLine(TYPES[TYPE_INDEX[e.kind]].name, 1, 0.82, 0)
            GameTooltip:AddLine(BuildPreview(e.kind, e.text), 1, 1, 1, true)
            if e.customIndex then
                GameTooltip:AddLine("Right-click to edit or delete", 0.5, 1, 0.5)
            end
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        gridButtons[i] = b
    end

    -- Paging
    local prev = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    prev:SetSize(30, 22); prev:SetText("<")
    prev:SetPoint("TOP", f, "TOP", -70, -270)
    prev:SetScript("OnClick", function() currentPage = currentPage - 1; Refresh() end)

    local nxt = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    nxt:SetSize(30, 22); nxt:SetText(">")
    nxt:SetPoint("TOP", f, "TOP", 70, -270)
    nxt:SetScript("OnClick", function() currentPage = currentPage + 1; Refresh() end)

    f.pageText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.pageText:SetPoint("TOP", f, "TOP", 0, -275)
    f.prev, f.nxt = prev, nxt

    -- Quick emote line
    MakeLabel(f, "Quick emote:", 28, -308)
    local quick = MakeEditBox(f, 215, 240)
    quick:SetPoint("TOPLEFT", f, "TOPLEFT", 118, -302)
    local function SendQuick()
        local txt = Trim(quick:GetText())
        if txt ~= "" then Perform("emote", txt) end
        quick:SetText("")
        quick:ClearFocus()
    end
    quick:SetScript("OnEnterPressed", SendQuick)
    local quickBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    quickBtn:SetSize(80, 24); quickBtn:SetText("Emote")
    quickBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 345, -301)
    quickBtn:SetScript("OnClick", SendQuick)

    -- New emote button + hint
    local newBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    newBtn:SetSize(150, 24); newBtn:SetText("+ New Emote")
    newBtn:SetPoint("TOP", f, "TOP", 0, -334)
    newBtn:SetScript("OnClick", function() OpenEditor(nil) end)

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("TOP", f, "TOP", 0, -364)
    hint:SetText("Use %t for your target's name  |  Green buttons are yours")
end

function Refresh()
    if not mainFrame then return end
    local list = GetList(currentCat)
    local pages = math.max(1, math.ceil(#list / PER_PAGE))
    if currentPage > pages then currentPage = pages end
    if currentPage < 1 then currentPage = 1 end

    for i, b in ipairs(gridButtons) do
        local entry = list[(currentPage - 1) * PER_PAGE + i]
        if entry then
            b.entry = entry
            local label = entry.label
            if entry.customIndex then label = "|cff7fff7f" .. label .. "|r" end
            b:SetText(label)
            b:Show()
        else
            b.entry = nil
            b:Hide()
        end
    end

    if #list == 0 then mainFrame.empty:Show() else mainFrame.empty:Hide() end
    mainFrame.pageText:SetText(("Page %d / %d"):format(currentPage, pages))
    if currentPage > 1 then mainFrame.prev:Enable() else mainFrame.prev:Disable() end
    if currentPage < pages then mainFrame.nxt:Enable() else mainFrame.nxt:Disable() end

    for _, tab in ipairs(tabButtons) do
        if tab.cat == currentCat then
            tab:LockHighlight()
            tab:SetText("|cffffffff" .. tab.cat .. "|r")
        else
            tab:UnlockHighlight()
            tab:SetText(tab.cat)
        end
    end
end

--------------------------------------------------------------------------------
-- Emote editor
--------------------------------------------------------------------------------
local function UpdateEditorUI()
    local e = editor
    e.typeBtn:SetText(TYPES[e.typeIndex].name)
    e.catBtn:SetText(e.cat)
    e.preview:SetText(BuildPreview(TYPES[e.typeIndex].key, Trim(e.textBox:GetText())))
    if TYPES[e.typeIndex].key == "token" then
        e.textLabel:SetText("Emote token (e.g. WAVE, BOW, LAUGH)")
    else
        e.textLabel:SetText("Text (without /me or /say)")
    end
end

local function BuildEditor()
    local e = MakeDialog("ThespianEditor", 400, 340, "New Emote")
    editor = e
    e:SetFrameStrata("FULLSCREEN_DIALOG")
    e:SetPoint("CENTER")
    e:SetScript("OnDragStart", e.StartMoving)
    e:SetScript("OnDragStop", e.StopMovingOrSizing)
    e:Hide()

    e.typeIndex, e.cat = 1, "Custom"

    MakeLabel(e, "Button label", 28, -46)
    e.labelBox = MakeEditBox(e, 200, 18)
    e.labelBox:SetPoint("TOPLEFT", 34, -60)

    MakeLabel(e, "Type", 28, -94)
    e.typeBtn = CreateFrame("Button", nil, e, "UIPanelButtonTemplate")
    e.typeBtn:SetSize(168, 24)
    e.typeBtn:SetPoint("TOPLEFT", 28, -108)
    e.typeBtn:SetScript("OnClick", function()
        e.typeIndex = e.typeIndex % #TYPES + 1
        UpdateEditorUI()
    end)

    MakeLabel(e, "Category", 204, -94)
    e.catBtn = CreateFrame("Button", nil, e, "UIPanelButtonTemplate")
    e.catBtn:SetSize(168, 24)
    e.catBtn:SetPoint("TOPLEFT", 204, -108)
    e.catBtn:SetScript("OnClick", function()
        local idx = 1
        for i, c in ipairs(CATEGORIES) do if c == e.cat then idx = i end end
        e.cat = CATEGORIES[idx % #CATEGORIES + 1]
        UpdateEditorUI()
    end)

    e.textLabel = MakeLabel(e, "Text", 28, -146)
    e.textBox = MakeEditBox(e, 332, 240)
    e.textBox:SetPoint("TOPLEFT", 34, -160)
    e.textBox:SetScript("OnTextChanged", function() UpdateEditorUI() end)
    e.labelBox:SetScript("OnEnterPressed", function() e.textBox:SetFocus() end)
    e.textBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    local tip = e:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    tip:SetPoint("TOPLEFT", 28, -190)
    tip:SetWidth(344); tip:SetJustifyH("LEFT")
    tip:SetText("Tip: %t becomes your target's name. Click Type or Category to cycle through the options.")

    MakeLabel(e, "Preview", 28, -226)
    e.preview = e:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    e.preview:SetPoint("TOPLEFT", 28, -242)
    e.preview:SetWidth(344); e.preview:SetJustifyH("LEFT"); e.preview:SetJustifyV("TOP")
    e.preview:SetHeight(36)

    -- Buttons
    local save = CreateFrame("Button", nil, e, "UIPanelButtonTemplate")
    save:SetSize(100, 24); save:SetText("Save")
    save:SetPoint("BOTTOM", -108, 26)
    save:SetScript("OnClick", function()
        local label, text = Trim(e.labelBox:GetText()), Trim(e.textBox:GetText())
        if label == "" or text == "" then
            Print("Please fill in both the label and the text.")
            return
        end
        local entry = { label = label, kind = TYPES[e.typeIndex].key, text = text, cat = e.cat }
        if editingIndex then
            DB.customs[editingIndex] = entry
        else
            table.insert(DB.customs, entry)
            currentPage = 9999 -- jump to last page, where the new button lives
        end
        currentCat = entry.cat
        e:Hide()
        mainFrame:Show()
        Refresh()
    end)

    local cancel = CreateFrame("Button", nil, e, "UIPanelButtonTemplate")
    cancel:SetSize(100, 24); cancel:SetText("Cancel")
    cancel:SetPoint("BOTTOM", 0, 26)
    cancel:SetScript("OnClick", function() e:Hide() end)

    e.delete = CreateFrame("Button", nil, e, "UIPanelButtonTemplate")
    e.delete:SetSize(100, 24); e.delete:SetText("Delete")
    e.delete:SetPoint("BOTTOM", 108, 26)
    e.delete:SetScript("OnClick", function()
        pendingDelete = editingIndex
        StaticPopup_Show("THESPIAN_DELETE", DB.customs[editingIndex] and DB.customs[editingIndex].label or "")
    end)
end

StaticPopupDialogs["THESPIAN_DELETE"] = {
    text = "Delete the emote \"%s\"?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        if pendingDelete and DB.customs[pendingDelete] then
            table.remove(DB.customs, pendingDelete)
        end
        pendingDelete = nil
        if editor then editor:Hide() end
        Refresh()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function OpenEditor(index)
    editingIndex = index
    local data = index and DB.customs[index]
    editor.title:SetText(data and "Edit Emote" or "New Emote")
    editor.labelBox:SetText(data and data.label or "")
    editor.textBox:SetText(data and data.text or "")
    editor.typeIndex = data and TYPE_INDEX[data.kind] or 1
    editor.cat = data and data.cat or currentCat
    if data then editor.delete:Show() else editor.delete:Hide() end
    UpdateEditorUI()
    editor:Show()
    editor.labelBox:SetFocus()
end

--------------------------------------------------------------------------------
-- Minimap button
--------------------------------------------------------------------------------
local minimapButton

local function Toggle()
    if not mainFrame then return end
    if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show() end
end

local ROUND_QUADS = {
    ["ROUND"]               = { true,  true,  true,  true  },
    ["SQUARE"]              = { false, false, false, false },
    ["CORNER-TOPLEFT"]      = { false, false, false, true  },
    ["CORNER-TOPRIGHT"]     = { false, false, true,  false },
    ["CORNER-BOTTOMLEFT"]   = { false, true,  false, false },
    ["CORNER-BOTTOMRIGHT"]  = { true,  false, false, false },
    ["SIDE-LEFT"]           = { false, true,  false, true  },
    ["SIDE-RIGHT"]          = { true,  false, true,  false },
    ["SIDE-TOP"]            = { false, false, true,  true  },
    ["SIDE-BOTTOM"]         = { true,  true,  false, false },
    ["TRICORNER-TOPLEFT"]   = { false, true,  true,  true  },
    ["TRICORNER-TOPRIGHT"]  = { true,  false, true,  true  },
    ["TRICORNER-BOTTOMLEFT"]  = { true, true, false, true  },
    ["TRICORNER-BOTTOMRIGHT"] = { true, true, true,  false },
}

-- Places the button on the minimap edge (also works with square minimaps)
local function UpdateMinimapPosition()
    local rad = math.rad(DB.minimap.angle or 215)
    local x, y = math.cos(rad), math.sin(rad)
    local w = (Minimap:GetWidth() / 2) + 5
    local h = (Minimap:GetHeight() / 2) + 5
    local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
    local quads = ROUND_QUADS[shape] or ROUND_QUADS["ROUND"]
    local q = 1
    if x < 0 then q = q + 1 end
    if y > 0 then q = q + 2 end
    if quads[q] then
        x, y = x * w, y * h
    else
        local dw = math.sqrt(2 * w * w) - 10
        local dh = math.sqrt(2 * h * h) - 10
        x = math.max(-w, math.min(x * dw, w))
        y = math.max(-h, math.min(y * dh, h))
    end
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function BuildMinimapButton()
    local mb = CreateFrame("Button", "ThespianMinimapButton", Minimap)
    minimapButton = mb
    mb:SetSize(31, 31)
    mb:SetFrameStrata("MEDIUM")
    mb:SetFrameLevel(8)
    mb:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    mb:RegisterForDrag("LeftButton")
    mb:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local bg = mb:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20); bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    bg:SetPoint("TOPLEFT", 7, -5)

    local icon = mb:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20); icon:SetTexture("Interface\\AddOns\\Thespian\\Media\\MinimapIcon")
    icon:SetPoint("TOPLEFT", 6, -5)
    icon:SetTexCoord(0, 1, 0, 1)

    local border = mb:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetPoint("TOPLEFT")

    mb:SetScript("OnClick", function(_, button)
        if button == "RightButton" then OpenOptions() else Toggle() end
    end)
    mb:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            DB.minimap.angle = math.deg(atan2(py / scale - my, px / scale - mx))
            UpdateMinimapPosition()
        end)
    end)
    mb:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    mb:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Thespian", 1, 0.82, 0)
        GameTooltip:AddLine("Left-click: open / close", 1, 1, 1)
        GameTooltip:AddLine("Right-click: options", 1, 1, 1)
        GameTooltip:AddLine("Drag: move this button", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    mb:SetScript("OnLeave", function() GameTooltip:Hide() end)

    UpdateMinimapPosition()
end

--------------------------------------------------------------------------------
-- Defaults & applying settings
--------------------------------------------------------------------------------
local DEFAULTS = {
    scale      = 1,
    alpha      = 1,
    locked     = false,
    closeOnUse = false,
    tooltips   = true,
}

function ApplySettings()
    if mainFrame then
        mainFrame:SetScale(DB.scale)
        mainFrame:SetAlpha(DB.alpha)
    end
    if minimapButton then
        if DB.minimap.hide then
            minimapButton:Hide()
        else
            minimapButton:Show()
            UpdateMinimapPosition()
        end
    end
end

local function ResetWindowPosition()
    DB.pos = nil
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint("CENTER")
end

local function ResetOptions()
    for k, v in pairs(DEFAULTS) do DB[k] = v end
    DB.minimap.hide = false
    DB.minimap.angle = 215
    ResetWindowPosition()
    ApplySettings()
    RefreshOptions()
end

--------------------------------------------------------------------------------
-- Options panel  (Esc > Options > AddOns  /  Interface > AddOns)
--------------------------------------------------------------------------------
local optionsCategory, optionsPanel
local optionWidgets = {}

local function MakeCheckbox(parent, text, desc, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(26, 26)
    cb:SetPoint("TOPLEFT", x, y)
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")

    local label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText(text)

    local d = cb:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    d:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 30, 4)
    d:SetText(desc)

    cb:SetScript("OnClick", function(self) setter(self:GetChecked() and true or false) end)
    function cb:Refresh() self:SetChecked(getter()) end
    optionWidgets[#optionWidgets + 1] = cb
    return cb
end

local function MakeSlider(parent, text, x, y, minV, maxV, step, getter, setter)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)

    local sl = CreateFrame("Slider", nil, parent, BackdropTemplate)
    sl:SetOrientation("HORIZONTAL")
    sl:SetSize(220, 16)
    sl:SetPoint("TOPLEFT", x + 4, y - 22)
    sl:SetBackdrop({
        bgFile   = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 },
    })
    sl:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    sl:GetThumbTexture():SetSize(32, 32)
    sl:SetMinMaxValues(minV, maxV)
    sl:SetValueStep(step)
    if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
    sl:EnableMouse(true)

    local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    valueText:SetPoint("LEFT", sl, "RIGHT", 12, 0)

    local updating = false
    sl:SetScript("OnValueChanged", function(_, v)
        v = tonumber(("%.2f"):format(math.floor(v / step + 0.5) * step))
        valueText:SetText(("%d%%"):format(math.floor(v * 100 + 0.5)))
        if not updating then setter(v) end
    end)
    function sl:Refresh()
        updating = true
        self:SetValue(getter())
        valueText:SetText(("%d%%"):format(math.floor(getter() * 100 + 0.5)))
        updating = false
    end
    optionWidgets[#optionWidgets + 1] = sl
    return sl
end

local function MakeSection(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", 16, y)
    fs:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
    line:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
    line:SetColorTexture(1, 0.82, 0, 0.35)
end

function RefreshOptions()
    for _, w in ipairs(optionWidgets) do w:Refresh() end
end

local function BuildOptionsPanel()
    local panel = CreateFrame("Frame", "ThespianOptionsPanel", UIParent)
    panel.name = "Thespian"
    panel:Hide()

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Thespian")

    local sub = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    sub:SetText("Clickable roleplay emotes. Type |cffffd100/thespian|r to open the window.")

    MakeSection(panel, "General", -80)

    MakeCheckbox(panel, "Show minimap button",
        "Displays the book icon on your minimap. Drag it to reposition.", 16, -108,
        function() return not DB.minimap.hide end,
        function(v) DB.minimap.hide = not v; ApplySettings() end)

    MakeCheckbox(panel, "Close window after using an emote",
        "Hides Thespian as soon as you click an emote button.", 16, -152,
        function() return DB.closeOnUse end,
        function(v) DB.closeOnUse = v end)

    MakeCheckbox(panel, "Show button tooltips",
        "Shows a preview of the chat line when hovering over an emote.", 16, -196,
        function() return DB.tooltips end,
        function(v) DB.tooltips = v end)

    MakeCheckbox(panel, "Lock window position",
        "Prevents Thespian from being dragged by accident.", 16, -240,
        function() return DB.locked end,
        function(v) DB.locked = v end)

    MakeSection(panel, "Appearance", -294)

    MakeSlider(panel, "Window scale", 20, -322, 0.5, 1.5, 0.05,
        function() return DB.scale end,
        function(v) DB.scale = v; ApplySettings() end)

    MakeSlider(panel, "Window opacity", 20, -376, 0.4, 1.0, 0.05,
        function() return DB.alpha end,
        function(v) DB.alpha = v; ApplySettings() end)

    local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    open:SetSize(150, 24); open:SetText("Open Thespian")
    open:SetPoint("TOPLEFT", 16, -440)
    open:SetScript("OnClick", function() mainFrame:Show() end)

    local resetPos = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetPos:SetSize(170, 24); resetPos:SetText("Reset Window Position")
    resetPos:SetPoint("LEFT", open, "RIGHT", 8, 0)
    resetPos:SetScript("OnClick", ResetWindowPosition)

    local resetAll = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    resetAll:SetSize(130, 24); resetAll:SetText("Reset Options")
    resetAll:SetPoint("LEFT", resetPos, "RIGHT", 8, 0)
    resetAll:SetScript("OnClick", ResetOptions)

    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", open, "BOTTOMLEFT", 0, -10)
    note:SetText("\"Reset Options\" keeps your custom emotes.")

    panel:SetScript("OnShow", RefreshOptions)
    panel.refresh = RefreshOptions
    panel.okay, panel.cancel, panel.default = function() end, function() end, function() end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        optionsCategory = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(optionsCategory)
    elseif InterfaceOptions_AddCategory then
        optionsPanel = panel
        InterfaceOptions_AddCategory(panel)
    end
end

function OpenOptions()
    if optionsCategory and Settings and Settings.OpenToCategory then
        local id = optionsCategory.GetID and optionsCategory:GetID() or optionsCategory.ID
        Settings.OpenToCategory(id)
    elseif optionsPanel and InterfaceOptionsFrame_OpenToCategory then
        -- called twice on purpose: works around a long-standing Blizzard quirk
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
    else
        Print("Options panel is not available on this client.")
    end
end

--------------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------------
SLASH_THESPIAN1 = "/thespian"
SLASH_THESPIAN2 = "/rpe"
SLASH_THESPIAN3 = "/rpemotes"
SlashCmdList["THESPIAN"] = function(msg)
    msg = Trim((msg or ""):lower())
    local cmd, arg = msg:match("^(%S+)%s*(.*)$")

    if not cmd then
        Toggle()
    elseif cmd == "new" then
        mainFrame:Show(); OpenEditor(nil)
    elseif cmd == "options" or cmd == "config" or cmd == "settings" then
        OpenOptions()
    elseif cmd == "reset" then
        ResetWindowPosition()
        Print("Window position reset.")
    elseif cmd == "scale" then
        local v = tonumber(arg)
        if v and v >= 0.5 and v <= 1.5 then
            DB.scale = v; ApplySettings(); RefreshOptions()
            Print("Scale set to " .. v .. ".")
        else
            Print("Usage: /thespian scale <0.5 - 1.5>")
        end
    elseif cmd == "minimap" then
        DB.minimap.hide = not DB.minimap.hide
        ApplySettings(); RefreshOptions()
        Print("Minimap button " .. (DB.minimap.hide and "hidden." or "shown."))
    else
        Print("Commands:")
        print("  |cffffd100/thespian|r - open or close the window")
        print("  |cffffd100/thespian options|r - open the options panel")
        print("  |cffffd100/thespian new|r - create a new emote")
        print("  |cffffd100/thespian scale <0.5-1.5>|r - resize the window")
        print("  |cffffd100/thespian reset|r - reset window position")
        print("  |cffffd100/thespian minimap|r - show or hide the minimap button")
    end
end

-- Retail addon compartment (ignored by Classic clients)
function Thespian_OnAddonCompartmentClick(_, buttonName)
    if buttonName == "RightButton" then OpenOptions() else Toggle() end
end

--------------------------------------------------------------------------------
-- Init
--------------------------------------------------------------------------------
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
    if name ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")

    ThespianDB = ThespianDB or {}
    DB = ThespianDB
    DB.customs = DB.customs or {}
    DB.minimap = DB.minimap or {}
    if DB.minimap.angle == nil then DB.minimap.angle = 215 end
    if DB.minimap.hide == nil then DB.minimap.hide = false end
    for k, v in pairs(DEFAULTS) do
        if DB[k] == nil then DB[k] = v end
    end

    BuildMainFrame()
    BuildEditor()
    BuildMinimapButton()
    BuildOptionsPanel()
    ApplySettings()
    Print("Loaded. Type |cffffd100/thespian|r to open, |cffffd100/thespian options|r for settings.")
end)
