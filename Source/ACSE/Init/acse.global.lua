-----------------------------------------------------------------------
--/  @file   ACSE.Global.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the 'Require' Lua behaviour to 
--/          apply delegated hooks only once on loading time for any 
--/          game files.
--/
--/  @Note   This module doesn't have a Shutdown function yet
--/  @Note   This module is used in ACSE to inject managers into the 
--/          environments and inject settings controls.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local require      = global.require
local package      = global.package
local tostring     = global.tostring
local table        = require('common.tableplus')
local GameDatabase = require("Database.GameDatabase")

local Object       = require("Common.object")

global.loadfile("acse : ACSE.global.lua loaded")

local ACSEGlobal = module(..., Object.class)

ACSEGlobal.Init = function(self)

    -- This is a we can't mangle with their metatable, this is global.
    self._tHandlers = {}

    self._tHandlers.require = global.require
    global.require = function(...)
        return self:Api_Require(...)
    end

    self._tHandlers.tryrequire = global.tryrequire
    global.tryrequire = function(...)
        return self:Api_TryRequire(...)
    end

    self._tHooks = {}

    api.acse.acseglobal = ACSEGlobal
end

ACSEGlobal._GetHooksForModule = function(self, sModuleName)
    local tResult = {}
    if GameDatabase.GetLuaHooks then
        for _,value in global.ipairs( GameDatabase.GetLuaHooks() ) do
            -- api.debug.Trace("_GetHooksForModule " .. table.tostring(value.sName) .. " >> " .. table.tostring(sModuleName))
            if string.lower(value.sName) == string.lower(sModuleName) then
                table.insert(tResult, value.tData)
            end
        end
    end
    return tResult
end

ACSEGlobal.Api_Require = function(self, sModuleName)
    local tHooks = {}
    if not package.loaded[sModuleName] and not package.preload[sModuleName] then
        --  api.debug.Trace("Require: " .. tostring(sModuleName) )
        tHooks = self:_GetHooksForModule(sModuleName)
        -- if #tHooks > 0 then api.debug.Trace("* FOUND HOOKS FOR " .. sModuleName .. " " .. table.tostring(tHooks)) end
    end

    -- Check if patched previously 
    local ret = self._tHandlers.require(sModuleName)

    if global.type(ret) == "table" and ret.__ACSEHooks == nil and #tHooks > 0 then
        api.debug.Trace("Hooks pending for " .. sModuleName)
        for _, hook in global.ipairs(tHooks) do
            if global.type(hook) == 'function' then
                local status, err, retval = global.xpcall(hook, api.debug.Error, ret)
            end
        end
        ret.__ACSEHooks = true
    end

    return ret
end

ACSEGlobal.Api_TryRequire = function(self, sModuleName)
    local tHooks = {}

    if not package.loaded[sModuleName] and not package.preload[sModuleName] then
        --api.debug.Trace("TryRequire: " .. tostring(sModuleName) )
        tHooks = self:_GetHooksForModule(sModuleName)
        -- if #tHooks > 0 then api.debug.Trace("FOUND HOOKS FOR " .. sModuleName) end
    end

    -- check if patched
    local ret = self._tHandlers.tryrequire(sModuleName)

    if global.type(ret) == "table" and ret.__ACSEHooks == nil and #tHooks > 0 then
        api.debug.Trace("Hooks pending for " .. sModuleName)
        for _, hook in global.ipairs(tHooks) do
            if global.type(hook) == 'function' then
                local status, err, retval = global.xpcall(hook, api.debug.Error, ret)
            end
        end
        ret.__ACSEHooks = true
    end

    return ret
end

ACSEGlobal.Shutdown = function(self)
end

