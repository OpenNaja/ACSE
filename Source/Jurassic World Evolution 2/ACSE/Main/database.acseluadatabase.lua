-----------------------------------------------------------------------
--/  @file   ACSELuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Handles ACSE loading and database creation
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local table = global.table
local pairs = global.pairs
local ipairs = global.ipairs
local type  = global.type
local require = require
local ACSEDatabase = module(...)

global.api.debug.Trace("Database.ACSELuaDatabase.lua loaded")

-- @brief setup a custom debug/trace system to use
global.api.acse = {}
global.api.acse.versionNumber = 0.513
global.api.acse.GetACSEVersionString = function()
    return global.tostring(global.api.acse.versionNumber)
end

-- Tweakable support
global.api.acse.tTweakables = {}

global.api.acse.GetTweakables = function()
    return global.api.acse.tTweakables
end

--/@brief make our own tweakables manager
global.api.acse.CreateDebugTweakable = function(ttype, id, arg1, arg2, arg3, arg4)
    --/ Tweakable types: 22  boolean, 11 float, 8 integer64, 7 integer32
    --/ tweakable exists, return the original one

    local nid = global.string.lower(id)

    if global.api.acse.tTweakables[nid] then
        return global.api.acse.tTweakables[nid]
    end

    --/ make a new tweakable
    local tweakable = {}
    tweakable.index = {}
    tweakable.metatable = {__index = tweakable.index}
    tweakable.id = id
    tweakable.type = ttype
    tweakable.value = arg1
    tweakable.min = arg2
    tweakable.max = arg3
    tweakable.step = arg4
    tweakable.GetValue = function(self)
        return self.value
    end
    tweakable.SetValue = function(self, newValue)
        self.value = newValue
    end

    --/ save the tweakable
    global.api.acse.tTweakables[nid] = tweakable
    return tweakable
end

--/@brief retrieve a tweakable object from the list if exists.
global.api.acse.GetDebugTweakable = function(id)
    local nid = global.string.lower(id)

    if global.api.acse.tTweakables[nid] then
        return global.api.acse.tTweakables[nid]
    end

    return nil
end


global.api.acse.Trace = function(msg)
	global.loadfile("acse :" .. msg)
end
global.api.acse.Error = function(msg)
	global.api.acse.Trace("acse -Err- " .. msg)
end

--global.api.debug.Trace = global.api.acse.Trace
--global.api.debug.Error = global.api.acse.Error


-- @brief add our custom databases
ACSEDatabase.AddContentToCall = function(_tContentToCall)
	table.insert(_tContentToCall, require("Database.ACSE"))
end

