-----------------------------------------------------------------------
-- @file    Components.ACSEDebugComponent.lua
-- @author  Inaki
--
-- @brief   ACSEDebug as a component would allow us to have the console
--          available regardless the world environment.
--
-- @see     https://github.com/OpenNaja/ACSE
-- @version 1.1
-- @require ACSE >= 0.641 to work.
--
--
-- Note: https://code.tutsplus.com/tutorials/quick-introduction-flash-text-input-and-text-area-components--active-5601
-- Note: This file has been created automatically with CobraModdingTool
-----------------------------------------------------------------------
local global       = _G

local api          = global.api
local require      = global.require
local tostring     = global.tostring
local pairs        = global.pairs
local string       = global.string
local require      = global.require
local tryrequire   = global.tryrequire
local coroutine    = global.coroutine
local table        = require("Common.tableplus")
local Object       = require("Common.object")
local Base         = require("LuaComponentManagerBase")

--
-- @package Components
-- @class ACSEDebugComponent
--
local ACSEDebugComponent = module(..., Object.subclass(Base))

--
-- @brief List of our supported APIs, accessible through:
-- - api.ACSEDebug:ApiExample1(nEntityID)
--
-- If no more implementors are added, consider if this interface is actually necessary rather
-- than just calling methods on the component manager directly.

-- .API Needs to exist
ACSEDebugComponent.tAPI = {
    "SetVisible",
    "WriteLine",
}

-- We no longer use Trace to print in the UI window
-- We temporarily hook into the Trace function..
-- ACSEDebugComponent.oldTrace = global.api.debug.Trace

ACSEDebugComponent._tCommandHistory = {}

ACSEDebugComponent.sToggleName = 'ACSEDebug_ToggleConsole'
if api.game.GetGameName() == "Planet Coaster" then
    ACSEDebugComponent.sToggleName = 'UIText_RightArrow'
end

-- @brief list of key controls for the Debug Window UI
ACSEDebugComponent.tUIKeys = {
    [ACSEDebugComponent.sToggleName] = {
        isPressed = false,
        o = nil,
        status = false
    }
}

-- @brief list of special keys for text input.
ACSEDebugComponent.tTextKeys = {
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

ACSEDebugComponent.GetMenuItems = function(self, tMenuItems, _sDeviceName)
    api.debug.Trace("ACSEDebugComponent.GetMenuItems() for device name " .. table.tostring(_sDeviceName))
    api.debug.Trace(table.tostring(tMenuItems, nil, nil, nil, true))

    --
    -- We provide menues for PC, JWE1, JWE2 and PZ
    --

    if api.game.GetGameName() == "Planet Coaster" then

        local InputSubstitution = require("Helpers.InputSubstitution")
        local tInputButtonLookupTable = table.copy(InputSubstitution.InputButtonLookupTable)
        local sActualString = InputSubstitution.LogicalButtonToString(ACSEDebugComponent.sToggleName, tInputButtonLookupTable)

        local tItem = {
            ["label"] = "[STRING_LITERAL:Value=\'Debug\']",
            ["items"] =
            {
                {
                    ["label"] = "[STRING_LITERAL:Value=\'Console UI\']",
                    ["secondLabel"] =  "[OptionsMenu_Controls_Text:ControlText='" .. sActualString .. "']",
                    ["id"] = "customcontrols.ACSEDebugComponent.toggleconsole",
                    ["itemRendererClass"] = "DoubleLabelRenderer",
                    ["items"] =
                    {
                            {
                                    ["toolTip"] = "[OptionsMenu_Controls_Rebind_Button]",
                                    ["toggled"] = false,
                                    ["id"] = "keyboardsettings:acsedebug:toggleconsole",
                                    ["text"] = "",
                                    ["streamedIcon"] = "PopUpIconEditName"
                            },
                            {
                                    ["toolTip"] = "[OptionsMenu_Controls_Unbind_Button]",
                                    ["toggled"] = false,
                                    ["text"] = "",
                                    ["id"] = "keyboardsettings:acsedebug:unbind:toggleconsole",
                                    ["enabled"] = api.input.GetLogicalButtonRebound(ACSEDebugComponent.sToggleName),
                                    ["streamedIcon"] = "PopUpIconResetMusic"
                            }
                    },
                }
            },
            ["id"] = "controls.ACSEDebugComponent.container",
            ["itemRendererClass"] = "ExpandableContainer",
            ["open"] = false
        }
        table.insert(tMenuItems, 4, tItem)
    end

    if api.game.GetGameName() == "Planet Zoo" then
        local tItem = {
            ["label"] = "[STRING_LITERAL:Value=\'Debug\']",
            ["items"] =
            {
                {
                    ["label"] = "[STRING_LITERAL:Value=\'Console UI\']",
                    ["secondLabel"] = "[OptionsMenu_Controls_Text:ControlText='".. api.input.GetTextDescriptionForLogicalButton('ACSEDebug_ToggleConsole') .."']",
                    ["id"] = "customcontrols.ACSEDebugComponent.toggleconsole",
                    ["itemRendererClass"] = "DoubleLabelRenderer",
                    ["items"] =
                    {
                            {
                                    ["toolTip"] = "[OptionsMenu_Controls_Rebind_Button]",
                                    ["toggled"] = false,
                                    ["id"] = "keyboardsettings:acsedebug:toggleconsole",
                                    ["text"] = "",
                                    ["streamedIcon"] = "PopUpIconEditName"
                            },
                            {
                                    ["toolTip"] = "[OptionsMenu_Controls_Unbind_Button]",
                                    ["toggled"] = false,
                                    ["text"] = "",
                                    ["id"] = "keyboardsettings:acsedebug:unbind:toggleconsole",
                                    ["enabled"] = api.input.GetLogicalButtonRebound('ACSEDebug_ToggleConsole'),
                                    ["streamedIcon"] = "PopUpIconResetMusic"
                            }
                    },
                }
            },
            ["id"] = "controls.ACSEDebugComponent.container",
            ["itemRendererClass"] = "ExpandableContainer",
            ["open"] = false
        }
        table.insert(tMenuItems, 4, tItem)
    end

    if api.game.GetGameName() == 'Jurassic World Evolution' and _sDeviceName == 'mousekeyboard' then
        api.debug.Trace("Adding debug binding for JWE")
        local tItem = {
            ["label"] = "[STRING_LITERAL:Value=\'Debug\']",
            ["id"] = "keyboardsettings_debug",
            ["itemRendererClass"] = 5                
        }
        table.insert(tMenuItems, 1, tItem)

        local tItem = {
            ["label"] = "[STRING_LITERAL:Value=\'Toggle Console\']",
            ["valueLabel"] = "[INPUT_ICON:InputName=#LogicalButton.ACSEDebug_ToggleConsole:device=keyboard#]",
            ["tooltipDescription"] = "[STRING_LITERAL:Value=\'Toggles visibility of the debug consonle On/Off\']",
            ["tooltipTitle"] = "[STRING_LITERAL:Value=\'Toggle Console\']",
            ["id"] = "keyboardsettings:acsedebug:toggleconsole",
            ["itemRendererClass"] = 6
        }
        table.insert(tMenuItems, 2, tItem)
    end

    if api.game.GetGameName() == 'Jurassic World Evolution 2' then
        local tItem = {
            ["label"] = "[STRING_LITERAL:Value=\'Debug\']",
            ["id"] = "keyboardsettings_debug",
            ["itemRendererClass"] = 4                
        }
        table.insert(tMenuItems, 1, tItem)

        local tItem = {
            ["label"] = "[STRING_LITERAL:Value=\'Toggle Console\']",
            ["valueLabel"] = "[INPUT_ICON:InputName=#LogicalButton.ACSEDebug_ToggleConsole:device=keyboard#]",
            ["tooltipDescription"] = "[STRING_LITERAL:Value=\'Toggles visibility of the debug consonle On/Off\']",
            ["tooltipTitle"] = "[STRING_LITERAL:Value=\'Toggle Console\']",
            ["id"] = "keyboardsettings:acsedebug:toggleconsole",
            ["itemRendererClass"] = 5
        }
        table.insert(tMenuItems, 2, tItem)
    end

end

--
-- @brief Called to initalize the component on environment start
-- @param _tWorldAPIs (table) table of api methods available from the current environment.
--
ACSEDebugComponent.Init = function(self, _tWorldAPIs)
    api.debug.Trace("ACSEDebug:Init()")
    --api.debug.Trace("worldAPIS " .. global.tostring(_tWorldAPIs))
    self._tCommandHistoryIndex = 1

    self.bTraceEnabled = true -- we start enabled by default
    self.bClearOnAdvance = false

    self.tEnvironment = global.api.game.GetEnvironment()
    self.tEnvironment.DebugUI = true

    self.iUIManager = self.tEnvironment:RequireInterface("Interfaces.IUIManager")
    self.uiMovie = self.iUIManager:GetGUIWrapper(self._NAME, "ACSEDebugWindow")
    self.uiMovie:Load()
    self.uiMovie:Hide()
    self._sCommand = ""

    self.tInput = {}
    self.tInput.keys = ACSEDebugComponent.tUIKeys
    self.tInput.textkeys = ACSEDebugComponent.tTextKeys

    self.tInput.oControlContext = global.api.input.CreatePlayerControlContext("acsedebug", global.api.player.GetGameOwner(), 0) -- _nPriority
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
    self.tInput.oKeybdControlContext = global.api.input.CreatePlayerControlContext("uitext", global.api.player.GetGameOwner(), 0)
    for k, v in pairs(self.tInput.textkeys) do
        v.o = self.tInput.oKeybdControlContext:GetButton(tostring(k))
    end

    -- Register our own custom shell commands
    self.tShellCommands = {
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs < 1 then
                    return false, "Loadfilescript requires at least one argument, the name of the lua file (without the .lua extension). Other arguments will be passed to the script\n"
                end

                local sModuleName = global.tostring(tArgs[1])
                global.api.debug.WriteLine(tEnv.output, "Loading file: " .. sModuleName)
                local pf, sMsg = global.loadfile("Dev/Lua/" .. sModuleName .. ".lua")
                if pf == nil and global.string.find(sMsg, "No such file or directory") then
                    local sName = global.string.gsub(sModuleName, "%.", "/")
                    pf, sMsg = global.loadfile("Dev/Lua/" .. sName .. ".lua")
                end
                if pf ~= nil and global.type(pf) == "function" then
                    api.debug.Trace("calling StartScript")
                    self:_StartFileScript(pf(sModuleName), global.unpack(tArgs))
                    return true, nil
                else
                    return false, "Lua file not loaded: " .. global.tostring(sMsg) .. "\n"
                end
            end,
            "&Load&File&Script {string} [optional args]",
            "Loads and execute a Lua file from the game dev/ folder.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs < 1 then
                    return false, "Needs the name of the Script script to run"
                end
                -- TODO ADD THE REST OF ARGUMENTS TOO like in lf

                -- Try importing the file if exists, ideally from full path

                api.debug.Trace("calling StartScript")
                self:_StartScript(tArgs[1], global.unpack(tArgs))
                return true, nil
            end,
            "&Start&Script {string} [optional args]",
            "Runs a Script file.\n"
        ),

        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                self.uiMovie:ClearLog()
            end,
            "Cls",
            "Clears the debug window.\n"
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

    --/
    --/ Add Control Settings
    --/
    local fnGetItems = function(tMenuItems, _sDeviceName)
        api.debug.Trace("ACSEDEBUG fnGetItems")
        self:GetMenuItems(tMenuItems, _sDeviceName)
    end
    local fnHandleEvent = function(_sID, _arg, bHandled, bRefresh, rebindFunction, unbindFunction)
        --api.debug.Trace("Components ACSEDEBUG GOT EVENT: " .. table.tostring(_sID))

        if _sID == 'keyboardsettings:acsedebug:toggleconsole' then
            --api.debug.Trace("Calling Rebind")
            rebindFunction(ACSEDebugComponent.sToggleName)
            return true, true
        end
        if _sID == 'keyboardsettings:acsedebug:unbind:toggleconsole' then
            --api.debug.Trace("Calling Unbind")
            unbindFunction(ACSEDebugComponent.sToggleName)
            return true, true
        end
        if string.lower(_sID) == 'controls.acsedebugcomponent.container' then 
            return true, true
        end
        return bHandled, bRefresh
    end

    -- Register our custom control settings
     self.ControlsSettingsHandler = global.api.acse.RegisterControlsSettingsHandler(fnGetItems, fnHandleEvent)
end

--
-- @brief Called after Init when the world is about to load
--
ACSEDebugComponent.Configure = function(self)
    api.debug.Trace("ACSEDebug:Configure()")
    -- Nothing really..
end


--
-- @brief Called to add the component to an array of entity ID with parameters
-- @param _tArrayOfEntityIDAndParams (table) list of entities spawning with this
--        component defined in their prefab
--
ACSEDebugComponent.AddComponentsToEntities = function(self, _tArrayOfEntityIDAndParams)
--    api.debug.Trace("ACSEDebug:AddComponentsToEntities()")
    return true
end

--
-- @brief Called to remove the component from an array of entities
-- @param _tEntitiesArray (table) list of entities despawning that have this
--        component defined in their prefabs.
--
ACSEDebugComponent.RemoveComponentFromEntities = function(self, _tEntitiesArray)
--    api.debug.Trace("ACSEDebug:RemoveComponentFromEntities()")
end

--
-- @brief called when the world has been activated
--
ACSEDebugComponent.OnWorldActivation = function(self)
  api.debug.Trace("ACSEDebug:OnWorldActivation()")
  self:_setVisible(false)
end

--
-- @brief called when the world has been deactivated
--
ACSEDebugComponent.OnWorldDeactivation = function(self)
  api.debug.Trace("ACSEDebug:OnWorldDeactivation()")
  self:_setVisible(false)
end

-- @brief ugly loop to track key down event
ACSEDebugComponent._updateKeyStatus = function(self)
    -- update key presses
    for k, v in global.pairs(self.tInput.keys) do
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
ACSEDebugComponent._updateTextKeyStatus = function(self)
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

ACSEDebugComponent._StartFileScript = function(self, oScriptCode, ...)

    if oScriptCode == nil then
        api.debug.WriteLine(1,"Script object required")
        return 
    end

    self.oScript = oScriptCode:new()
    self.oScript:Init( {...} )
    self.tReceivedEvents = {}

    self.fnRunScriptCo =
        coroutine.wrap( function()
            self.oScript:Run()
            return true
        end
    )
    
end


ACSEDebugComponent._StartScript = function(self, sScript, ...)
    -- TODO: add tProperties.ScriptsPath after dir-separator replacement

    local sName = global.string.gsub(sScript, "%.", "/")
    local _sScript = string.lower(sName)

    local oScriptCode = tryrequire(_sScript)
    api.debug.Assert(oScriptCode ~= nil, "Script name '" .. _sScript .. "' doesn't match a lua file")
    self.oScript = oScriptCode:new()
    self.oScript:Init({...})
    self.tReceivedEvents = {}

    self.fnRunScriptCo =
        coroutine.wrap( function()
            self.oScript:Run()
            return true
        end
    )
end


ACSEDebugComponent._RunScript = function(self)
    if self.fnRunScriptCo and self.fnRunScriptCo() then
        self.fnRunScriptCo = nil
        self.oScript:Shutdown()
        self.oScript = nil
    end
end

--
-- @brief This component doesn't track any entities
-- @param _nDeltaTime (number) time in milisecs since the last update, affected by
--        the current simulation speed.
-- @param _nUnscaledDeltaTime (number) time in milisecs since the last update.
--
ACSEDebugComponent.Advance = function(self, _nDeltaTime, _nUnscaledDeltaTime)
    --api.debug.Trace("ACSEDebug:Advance() " .. global.tostring(_nDeltaTime) )

    self:_RunScript()

    api.debug.ClearScreen("Planet Zoo\x00") -- api.game.GetGameName())

    -- Clean console
    --api.debug.ClearConsole()

    if self.bClearOnAdvance == true then
        self.uiMovie:ClearLog()
    end
    self:_updateKeyStatus()

    if self.tInput.keys[ACSEDebugComponent.sToggleName].status then
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

--
-- @brief Called to clean up the component on environment shutdown
--
ACSEDebugComponent.Shutdown = function(self)
    api.debug.Trace("ACSEDebug:Shutdown()")

    if self.oldTrace then
        api.debug.Trace = self.oldTrace
        self.oldTrace = nil
    end

    self.tEnvironment.DebugUI = nil
    self.tEnvironment = nil

    -- Remove custom commands
    for _, oCommand in global.ipairs(self.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end
    ACSEDebugComponent.tShellCommands = {}

    -- we no longer use Trace to print in the UI window
    -- global.api.debug.Trace = ACSEDebugComponent.oldTrace

    self.uiMovie:Close()
    self.iUIManager:ReleaseGUIWrapper(self._NAME, self.uiMovie)
    self.iUIManager = nil
    self.uiMovie = nil

    self.tInput.oControlContext:Unregister()

    if self.ControlsSettingsHandler then
        api.acse.UnregisterControlsSettingsHandler(self.ControlsSettingsHandler)
    end
end

ACSEDebugComponent._loadPrevCommand = function(self)
    self._tCommandHistoryIndex = self._tCommandHistoryIndex - 1
    if self._tCommandHistoryIndex < 1 then
        self._tCommandHistoryIndex = 1
    end
    if #self._tCommandHistory > 0 then
        self._sCommand = self._tCommandHistory[self._tCommandHistoryIndex]
    end
end

ACSEDebugComponent._loadNextCommand = function(self)
    self._tCommandHistoryIndex = self._tCommandHistoryIndex + 1
    local maxval = #self._tCommandHistory
    if self._tCommandHistoryIndex > maxval + 1 then
        self._tCommandHistoryIndex = maxval + 1
        self._sCommand = ''
    else
        self._sCommand = self._tCommandHistory[self._tCommandHistoryIndex]
    end
end

--
-- @brief update UI visibility
-- @param _bVisible (bool) show/hide state.
--
ACSEDebugComponent._setVisible = function(self, _bVisible)
    self.bVisible = _bVisible
    if self.bVisible then
        self.uiMovie:Show()
        self.tInput.oKeybdControlContext:Register()
    else
        self.uiMovie:Hide()
        self.tInput.oKeybdControlContext:Unregister()
    end
end

--
-- @brief Allows showing/hiding the ACSEDebug UI
-- @param _bVisible (bool) visible or not
-- @usage global.api.acsedebugcomponent:SetVisible( true )
--
ACSEDebugComponent.SetVisible = function(self, _bVisible)
    self._setVisible(_bVisible)
    return true
end

--
-- @brief Allows adding a text line to the ACSEDebug UI
-- @param _sText (string) text line to add
-- @usage global.api.acsedebugcomponent:Write( "Test line" )
--
ACSEDebugComponent.WriteLine = function(self, _sText)
    self.uiMovie:AddLog(_sText .. "\n")
    return true
end



