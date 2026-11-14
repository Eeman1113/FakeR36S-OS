-- FakeR36S-OS: gamepad combos for the handheld, like the emulators' save/load hotkeys.
--   Select + R1  bookmark this page (again on a bookmarked page: remove it)
--   Select + L1  open the bookmark list (pick one with A to jump there)
-- Select alone does nothing in KOReader (see koreader.mk); Select+Start still closes Reader.
-- SDL gamepad buttons skip KOReader's modifier keys, so Select is tracked here from the
-- GamepadButtonDown/Up broadcasts, which the SDL device sends before turning a press into a key.
local Event = require("ui/event")
local Notification = require("ui/widget/notification")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local BTN_SELECT, BTN_L1, BTN_R1 = 4, 9, 10   -- SDL_GAMEPAD_BUTTON_BACK / LEFT_SHOULDER / RIGHT_SHOULDER

local FakeR36S = WidgetContainer:extend{
    name = "fakers36s",
    select_held = false,
}

function FakeR36S:onGamepadButtonDown(value)
    local b = value and value.button
    if b == BTN_SELECT then
        self.select_held = true
        return false
    end
    if not self.select_held then return false end
    local bookmark = self.ui and self.ui.bookmark
    if not bookmark then return false end   -- library: L1/R1 keep paging the list
    if b == BTN_R1 then
        bookmark:onToggleBookmark()
        Notification:notify(bookmark:isPageBookmarked() and _("Bookmark saved") or _("Bookmark removed"))
        return true
    elseif b == BTN_L1 then
        self.ui:handleEvent(Event:new("ShowBookmark"))
        return true
    end
    return false
end

function FakeR36S:onGamepadButtonUp(value)
    if value and value.button == BTN_SELECT then
        self.select_held = false
    end
    return false
end

return FakeR36S
