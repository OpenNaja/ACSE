-----------------------------------------------------------------------
--/  @file   ACSE.Global.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the 'Require' Lua behaviour to 
--/          apply delegated hooks only once on loading time for any 
--/          game files.
--/
--/  @Note   This module doesn't have a Shutdown function yet
--/  @Note   This functionality has been requested by Kaiodenic and 
--/          hexabit because the original behaviour of tweakables was
--/          not usable.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local pairs        = global.pairs
local ipairs       = global.ipairs
local string       = global.string
local require      = global.require
local package      = global.package
local tostring     = global.tostring
local StringUtils  = require("Common.stringUtils")
local table        = require("Common.tableplus")
local Object       = require("Common.object")

global.loadfile("acse : ACSEDebug.Tweakables.lua loaded")

local Tweakables = module(..., Object.class)

Tweakables.Init = function(self)
    local raw  = api.debug

    -- This is a module we can't mangle with their metatable, because we are again
    -- modifying debug, which is original from API.Debug.lua
    self._tHandlers = {}

    self._tHandlers.CreateDebugTweakable = api.debug.CreateDebugTweakable
    api.debug.CreateDebugTweakable    = function(...)
        return self:Api_CreateDebugTweakable(raw, ...)
    end

    api.debug.GetDebugTweakable       = function(...)
        return self:Api_GetDebugTweakable(raw, ...)
    end

    api.debug.GetAllDebugTweakables   = function(...)
        return self:Api_GetAllDebugTweakables(raw, ...)
    end

    self.tTweakables = {}

    api.acse.tweakables = Tweakables
end

Tweakables.Api_GetDebugTweakable = function(self, _raw, id)

    local nid = global.string.lower(id)

    if self.tTweakables[nid] then
        return self.tTweakables[nid]
    end

    return nil
end

Tweakables.Api_GetAllDebugTweakables = function(self, _raw, id)
    return self.tTweakables
end

Tweakables.Api_CreateDebugTweakable = function(self, _raw, ttype, sId, default, nMin, nMax, nStep)
    --api.debug.Trace("CreateDebugTweakable: " .. tostring(sId))
    local nid = global.string.lower(sId)
    if self.tTweakables[nid] then return self.tTweakables[nid] end

    -- We delegate the creation of the tweakable to the original API, however it is useless since
    -- we will lose control of the new values when using GetValue, hence we override it completely.
    local tData = self._tHandlers.CreateDebugTweakable(ttype, sId, default, nMin, nMax, nStep)

    local tweakable = {}
    tweakable.index = {}
    tweakable.metatable = {__index = tData}
    tweakable.id = sId
    tweakable.type = ttype
    tweakable.value = default
    tweakable.min = nMin
    tweakable.max = nMax
    tweakable.step = nStep
    tweakable.GetValue = function(_self)
        return _self.value
    end
    tweakable.SetValue = function(_self, newValue)
        _self.value = newValue
    end
    self.tTweakables[nid] = tweakable
    return tweakable
end

Tweakables.Shutdown = function(self)

end

