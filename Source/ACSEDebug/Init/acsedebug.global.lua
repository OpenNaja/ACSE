-----------------------------------------------------------------------
--/  @file   ACSEDebug.Global.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes some of the Lua default features 
--/          for debugging purposes, like checking Lua file errors etc.
--/
--/  @todo   Allow loading local lose files if exists.
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local require      = global.require
local package      = global.package
local tostring     = global.tostring

local Object       = require("Common.object")

global.loadfile("acse : ACSEDebug.global.lua loaded")

local ACSEDebugGlobal = module(..., Object.class)

ACSEDebugGlobal.Init = function(self)

    -- This is the only module we can't mangle with their metatable, because we are in the middle
    -- of a function that will change it within API.Debug.lua
    self._tHandlers = {}

    self._tHandlers.require = global.require
    global.require = function(...)
        return self:Api_Require(...)
    end

    self._tHandlers.tryrequire = global.tryrequire
    global.tryrequire = function(...)
        return self:Api_TryRequire(...)
    end

    self.debugrequire    = api.game.HasCommandLineArgument("-debugRequire")
    self.debugtryrequire = api.game.HasCommandLineArgument("-debugTryRequire")
    self.disableprint    = api.game.HasCommandLineArgument("-disablePrint")

    api.acsedebug.acsedebugglobal = ACSEDebugGlobal
end

ACSEDebugGlobal.Shutdown = function(self)
    -- api.debug = global.getmetatable(api.debug).__index
end

ACSEDebugGlobal._LoadLocalFileIfExists = function(self, sModuleName)
    local sName = string.gsub(sModuleName, "%.", "/")
    local pf, sMsg = global.loadfile("Dev/Lua/" .. sName .. ".lua")
    if pf ~= nil then 
        api.debug.Trace("loading local file: " .. tostring(sModuleName) )
    else
        if not string.find(sMsg, "No such file or directory") then
            api.debug.Trace("Error: " .. tostring(sMsg))
        end
    end
    return pf, sMsg
end

ACSEDebugGlobal.Api_Require = function(self, sModuleName)
    if not package.loaded[sModuleName] and not package.preload[sModuleName] then

        if self.debugrequire then
            api.debug.Trace("Debug require: " .. tostring(sModuleName))
        end

        --local tMod, sMsg = self:_LoadLocalFileIfExists(sModuleName)

        -- Test if file has errors
        local fnMod, sMsg = global.loadresource(sModuleName)
        if not fnMod then
          api.debug.Trace("Error: " .. sMsg)
        end
    end
    return self._tHandlers.require(sModuleName)
end

ACSEDebugGlobal.Api_TryRequire = function(self, sModuleName)
    if not package.loaded[sModuleName] and not package.preload[sModuleName] then
        if self.debugtryrequire then
            api.debug.Trace("Debug tryrequire: " .. tostring(sModuleName))
        end

        --local tMod, sMsg = self:_LoadLocalFileIfExists(sModuleName)

        -- Test if file has errors
        local fnMod, sMsg = global.loadresource(sModuleName)
        if not fnMod then
            if not string.find(sMsg, " not found.") then
                api.debug.Trace("Error: " .. sMsg)
            end
        end
    end
    return self._tHandlers.tryrequire(sModuleName)
end