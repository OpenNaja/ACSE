-----------------------------------------------------------------------
--/  @file   ACSE.Default.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the core ACSE features require for
--/          mods to work in cobra engine, including engine API systems
--/
--/  @Note   This module doesn't have a Shutdown function yet
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local ipairs       = global.ipairs
local package      = global.package
local string       = global.string
local tostring     = global.tostring
local require      = global.require
local pcall        = global.pcall
local table        = require('common.tableplus')
local tryrequire   = global.tryrequire
local loadresource = global.loadresource

-- Harmless tracing when no debug is available
global.loadfile("acse : ACSE.Default.lua loaded")

local ACSE = module(...)

ACSE.versionNumber = 0.713

ACSE.tAppendToVersionString = {{
    text = string.format("ACSE %1.3f", ACSE.versionNumber),
    sep = "\n"
}}

-- List of core modules to load
ACSE.tModules = {
	'acse.global',
	'acse.entity',
	'acse.componentmanager',
    'acse.game',
    'acse.debug',
    'acse.tweakables',
}

ACSE.GetVersionString = function()
	return string.format("%1.3f", ACSE.versionNumber)
end

ACSE.OnInit = function()
	-- Save as a global resource
	api.acse = ACSE

	for _, sModuleName in ipairs(ACSE.tModules) do
	    sModuleName = string.lower(sModuleName)
	    global.loadfile("acse : ACSE.lua loading " .. sModuleName)
	    local tModule = tryrequire(sModuleName)
	    if tModule ~= nil then
	    	--ACSE.tModules[v] =
	        tModule:Init()
	    end
	end

    -- We still want tracing of this step
    global.loadfile("acse : ACSE.lua reloading modules")

    -- Module reload required to modify alrady loaded lua files.
    local ACSE_ReloadModule = function(sModuleName)
        api.debug.Trace("Reloading module: " .. tostring(sModuleName))
        sModuleName = string.lower(sModuleName)
        
        local tMod = package.loaded[sModuleName]
        if global.type(tMod) ~= "table" then
            return false, "Module not loaded, not reloading."
        end

        local fnModLoadError = function(sStage, sErrorMessage)
            local sErr = "Module reload failed, error while attempting to " .. sStage .. " module:\n\n" .. sErrorMessage
            api.debug.Trace(sErr)
            return false, sErr
        end

        local fnMod, sErrorMessage = loadresource(sModuleName)
        if not fnMod then
            return fnModLoadError("load", sErrorMessage)
        end

        local module = tryrequire(sModuleName)
        if module ~= nil then
            module.s_tInterfaces = nil
        end

        local bOk = pcall(fnMod, sModuleName)
        if not bOk then
            return fnModLoadError("execute", sErrorMessage)
        end
        return true
    end

	-- Force reload of the files we want the API changes to affect to.
	ACSE_ReloadModule('Environment.Environment')
	ACSE_ReloadModule('Game.BaseGame')
	ACSE_ReloadModule('Game.GameScript')
end

-- TODO: Move to its own module?
ACSE._tControlsSettingsRegistrations = {}

ACSE.RegisterControlsSettingsHandler = function( fGetItems, fHandleEvent, fApplyChanges)
    --api.debug.Trace("ACSE.RegisterControlsSettingsHandler")
    --api.debug.Trace(table.tostring(api.acse, nil, nil, nil, true))
    local tItem = {
        fGetItems     = fGetItems,
        fHandleEvent  = fHandleEvent,
        fApplyChanges = fApplyChanges,
    }
    table.insert(api.acse._tControlsSettingsRegistrations, tItem)
    return table.count(api.acse._tControlsSettingsRegistrations)
end

ACSE.UnregisterControlsSettingsHandler = function(nItem)
    table.remove(api.acse._tControlsSettingsRegistrations, nItem)
end

ACSE.OnShutdown = function()
end

