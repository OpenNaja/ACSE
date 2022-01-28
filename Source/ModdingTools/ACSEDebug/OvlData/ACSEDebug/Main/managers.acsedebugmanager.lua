-----------------------------------------------------------------------
--/  @file   Managers.ACSEDebugManager.lua
--/  @author My Self
--/
--/  @brief  ACSEDebug main manager and window controller
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = api
local pairs = pairs
local type = type
local string = string
local ipairs = ipairs
local require = require
local tostring = tostring
local coroutine = coroutine
local table = table
local math = math
local next = next
local Trace = global.api.debug.Trace
local Mutators = require("Environment.ModuleMutators")

local ACSEDebugManager = module(..., (Mutators.Manager)("Interfaces.IACSEDebugManager"))

-- We temporarily hook into the Trace function..
ACSEDebugManager.oldTrace = global.api.debug.Trace
ACSEDebugManager._tCommandHistory = {}

-- @brief list of key controls for the Debug Window UI
ACSEDebugManager.tUIKeys = {
    ACSEDebug_ToggleConsole = {
        isPressed = false,
        o = nil,
        status = false
    }
}

-- @brief list of special keys for text input.
ACSEDebugManager.tTextKeys = {
    UIText_Space = {
        val = " ",
        isPressed = false,
        o = nil
    },
    UIText_Backspace = {
        val = "BACKSPACE",
        isPressed = false,
        o = nil
    },
    UIText_PageUp = {
        val = "PAGEUP",
        isPressed = false,
        o = nil
    },
    UIText_PageDown = {
        val = "PAGEDOWN",
        isPressed = false,
        o = nil
    },
    UIText_UpArrow = {
        val = "HISTDOWN",
        isPressed = false,
        o = nil
    },
    UIText_DownArrow = {
        val = "HISTUP",
        isPressed = false,
        o = nil
    },
    UIText_Enter = {
        val = "ENTER",
        isPressed = false,
        o = nil
    }
}

-- @brief defines the control contexts, and loads the debug UI
ACSEDebugManager.Init = function(self, _tProperties, _tEnvironment)
    Trace("ACSEDebugManager.Init()")
    self._tCommandHistoryIndex = 1

    self.bTraceEnabled = true -- we start enabled by default
    self.bClearOnAdvance = false

    self.iUIManager = global.api.game.GetEnvironment():RequireInterface("Interfaces.IUIManager")
    self.uiMovie = self.iUIManager:GetGUIWrapper(self._NAME, "ACSEDebugWindow")
    self.uiMovie:Load()
    self.uiMovie:Hide()

    self._sCommand = ""

    -- Temporarily hook trace to get log messages
    local dTrace = function(text)
        ACSEDebugManager.oldTrace(text)
        if self.bTraceEnabled == true then 
            self.uiMovie:AddLog(text .. "\n")
        end
    end
    global.api.debug.Trace = dTrace

    self.tInput = {}
    self.tInput.keys = ACSEDebugManager.tUIKeys
    self.tInput.textkeys = ACSEDebugManager.tTextKeys
    self.tInput.oControlContext =
        global.api.input.CreatePlayerControlContext("acsedebug", global.api.player.GetGameOwner(), 0) -- _nPriority
    for k, v in pairs(self.tInput.keys) do
        v.o = self.tInput.oControlContext:GetButton(tostring(k))
    end
    self.tInput.oControlContext:Register()

    -- Build the rest of keyboard control keys, tInput.textkeys already has the default/odd ones
    --
    local keylist = 'abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ-=[];\'#,./$%^*()_+{}:@~|?"\\<>&'
    for i = 1, #keylist, 1 do
        local charval = global.string.sub(keylist, i, i)
        keyObject = {
            val = charval,
            isPressed = false,
            o = nil
        }
        self.tInput.textkeys["UIText_" .. charval] = keyObject
    end

    -- get a full keybd control context but don't register it yet
    self.tInput.oKeybdControlContext =
        global.api.input.CreatePlayerControlContext("uitext", global.api.player.GetGameOwner(), 0)
    for k, v in pairs(self.tInput.textkeys) do
        v.o = self.tInput.oKeybdControlContext:GetButton(tostring(k))
    end

    -- Register our own custom shell commands
    self.tShellCommands = {
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                self.uiMovie:ClearLog()
            end,
            "Clear",
            "Clears the log window.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 1 then
                    return false, "EnableConsoleTrace requires a frue or false argument.\n"
                end
                self.bTraceEnabled = tArgs[1]

                local sMsg = "Tracing disabled."
                if self.bTraceEnabled then sMsg = "Tracing enabled." end
                return true, sMsg
            end,
            "&S&u&press&Trace {bool}",
            "Redirects/hides trace output to the UI (useful for large text prints).\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 1 then
                    return false, "EnableClearOnAdvance requires a frue or false argument.\n"
                end
                self.bClearOnAdvance = tArgs[1]

                local sMsg = "Advance Clearing disabled."
                if self.bTraceEnabled then sMsg = "Advance Clearing enabled." end
                return true, sMsg
            end,
            "&Enable&ClearOn&Advance {bool}",
            "Clear the console every advance() tick (useful for printing from advance functions).\n"
        ),

		--[[
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                self.uiMovie:CopyLog()
				return true, "Log copied to clipboard"
            end,
            "Copy",
            "Copies the content of the log window to the clipboard. (Not working currently)\n"
        )
		]]
    }
end

ACSEDebugManager.Activate = function(self)
    global.api.debug.Trace("ACSEDebugManager.Activate()")
    self:_setVisible(false)
end

-- @brief ugly loop to track key down event
ACSEDebugManager._updateKeyStatus = function(self)
    -- update key presses
    for k, v in pairs(self.tInput.keys) do
        if v.o:IsDown() then
            if v.isPressed == false then
                v.status = true
                v.isPressed = true
            else
                v.status = false
            end
        else
            v.isPressed = false
            v.status = false
        end
    end
end

-- @brief ugly loop to control key down even on text input
ACSEDebugManager._updateTextKeyStatus = function(self)
    -- update key presses
    for k, v in pairs(self.tInput.textkeys) do
        if v.o:IsDown() then
            if v.isPressed == false then
                if v.val == "BACKSPACE" then
                    self._sCommand = self._sCommand:sub(1, #self._sCommand - 1)
                elseif v.val == "PAGEUP" then
                    self.uiMovie:DecreaseScroll()
                elseif v.val == "PAGEDOWN" then
                    self.uiMovie:IncreaseScroll()
                elseif v.val == "HISTUP" then
                    self:_loadNextCommand()
                elseif v.val == "HISTDOWN" then
                    self:_loadPrevCommand()
                elseif v.val == "ENTER" then
                    if self._sCommand and self._sCommand ~= '' then
						global.table.insert(self._tCommandHistory, self._sCommand)
						self._tCommandHistoryIndex = #self._tCommandHistory + 1
                        ret = global.api.debug.RunShellCommand(self._sCommand)
                        self._sCommand = ""
                    end
                else
                    self._sCommand = self._sCommand .. v.val
                end
                v.isPressed = true
            end
        else
            v.isPressed = false
        end
    end
end

-- @brief update UI visibility and key down events
ACSEDebugManager.Advance = function(self, _nDeltaTime)
    if self.bClearOnAdvance == true then
        self.uiMovie:ClearLog()
    end

    self:_updateKeyStatus()

    if self.tInput.keys["ACSEDebug_ToggleConsole"].status then
        if self.bVisible == true then
            self:_setVisible(false)
        else
            self:_setVisible(true)
        end
    end

    -- other keys only process if console is visible
    if self.bVisible then
        self:_updateTextKeyStatus()
        self.uiMovie:SetCommand(self._sCommand)
    end
end

ACSEDebugManager.Shutdown = function(self)
    global.api.debug.Trace("ACSEDebugManager.Shutdown()")
    global.api.debug.Trace = ACSEDebugManager.oldTrace

    self.uiMovie:Close()
    self.iUIManager:ReleaseGUIWrapper(self._NAME, self.uiMovie)
    self.iUIManager = nil
    self.uiMovie = nil

    self.tInput.oControlContext:Unregister()

    -- Remove custom commands
    for i, oCommand in ipairs(self.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end
end

-- Just to conform the interface ACSE API
ACSEDebugManager._setVisible = function(self, _bVisible)
    self.bVisible = _bVisible
    if self.bVisible then
        self.uiMovie:Show()
        self.tInput.oKeybdControlContext:Register()
    else
        self.uiMovie:Hide()
        self.tInput.oKeybdControlContext:Unregister()
    end
end

ACSEDebugManager._loadPrevCommand = function(self)
    self._tCommandHistoryIndex = self._tCommandHistoryIndex - 1
    if self._tCommandHistoryIndex < 1 then
        self._tCommandHistoryIndex = 1
    end
    if #self._tCommandHistory > 0 then
        self._sCommand = self._tCommandHistory[self._tCommandHistoryIndex]
    end
end

ACSEDebugManager._loadNextCommand = function(self)
    self._tCommandHistoryIndex = self._tCommandHistoryIndex + 1
    local maxval = #self._tCommandHistory
    if self._tCommandHistoryIndex > maxval + 1 then
        self._tCommandHistoryIndex = maxval + 1
        self._sCommand = ''
    else
        self._sCommand = self._tCommandHistory[self._tCommandHistoryIndex]
    end
end

-- Just to conform the interface ACSE API
ACSEDebugManager.SetVisible = function(self, _bVisible)
    self._setVisible(_bVisible)
end

Mutators.VerifyManagerModule(ACSEDebugManager)
