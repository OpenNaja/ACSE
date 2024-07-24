-----------------------------------------------------------------------
--/  @file   ACSEDebug.Default.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes some of the debugging features disabled
--/          in the release version to improve debugging while modding the
--/          game.
--/
--/          Initializes a default log system.
--/          TODO: initializes an output console system.
--/  @Note   This module doesn't have a Shutdown function to close the current
--/          file descriptors used to log information, the process will do.
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global     = _G
local api        = global.api
local package    = global.package
local tostring   = global.tostring
local ipairs     = global.ipairs
local string     = global.string
local require    = global.require
local tryrequire = global.tryrequire
local table      = require('common.tableplus')

global.loadfile("acse : acsedebug.lua loaded")

local ACSEDebug = module(...)

ACSEDebug.version = 0.014

local API_ReloadModule = function(sModuleName)
    api.debug.Trace("Reloading module: " .. tostring(sModuleName))
    sModuleName = string.lower(sModuleName)
    local tMod = package.loaded[sModuleName]
    if global.type(tMod) ~= "table" then
        local sErr = "Module not loaded, not reloading."
        api.debug.Trace(sErr)
        return false, sErr
    end

    local fnModLoadError = function(sStage, sErrorMessage)
        local sErr = "Module reload failed, error while attempting to " .. sStage .. " module:\n\n" .. sErrorMessage
        api.debug.Trace(sErr)
        return false, sErr
    end

    local fnMod, sErrorMessage = global.loadresource(sModuleName)
    if not fnMod then
        return fnModLoadError("load", sErrorMessage)
    end
    local module = global.tryrequire(sModuleName)
    if module ~= nil then
        module.s_tInterfaces = nil
    end
    local bOk = nil
    bOk = global.pcall(fnMod, sModuleName)
    if not bOk then
        return fnModLoadError("execute", sErrorMessage)
    end
    return true
end

ACSEDebug.tModules = {
	'acsedebug.debug',
	'acsedebug.game',
	'acsedebug.global',
	'acsedebug.shellcommands',
	'acsedebug.entity',
	'acsedebug.database',
}

-- TODO: Change this OnInit for a custom method, and attach this script to a 
-- database, component or manager methods for Init and Shutdown??
ACSEDebug.OnInit = function()

	-- Save as an API handler for other modules to access.
	global.api.acsedebug = ACSEDebug

	for _, sModuleName in ipairs(ACSEDebug.tModules) do
	    sModuleName = string.lower(sModuleName)
	    global.loadfile("acse : ACSEDebug.lua loading " .. sModuleName)
	    local tModule = tryrequire(sModuleName)
	    if tModule ~= nil then
	    	--ACSE.tModules[v] =
	        tModule:Init()
	    end
	end

    global.loadfile("acse : ACSEDebug.lua reloading modules")

    global.api.debug.CreateLog( api.game.GetGameName() .. ".log" )
    global.api.debug.Trace( string.format("ACSE %0.3f for %s %s", api.acse.versionNumber, tostring(api.game.GetGameName()), tostring(api.game.GetRawVersionString())  ))
    global.api.debug.Trace( string.format("ACSEDebug %0.3f started on %s", ACSEDebug.version, api.time.GetCurrentTimeString()))
    global.api.debug.Trace( string.format("Command Line: %s", global.api.game.GetCommandLine() ))

	-- Reload Environment module to refresh all the modified APIS of that module (specially require())
    API_ReloadModule('Environment.Environment')
    --API_ReloadModule('GameObject.Environment')
    --API_ReloadModule('Environments.CPTEnvironment')
	API_ReloadModule('Game.BaseGame')
	API_ReloadModule('Game.GameScript')
end

