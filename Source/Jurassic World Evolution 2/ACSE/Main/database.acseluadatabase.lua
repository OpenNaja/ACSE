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

global.api.acse.Trace = function(msg)
	global.loadfile("acse :" .. msg)
end
global.api.acse.Error = function(msg)
	global.api.acse.Trace("case -Err- " .. msg)
end

global.api.debug.Trace = global.api.acse.Trace
global.api.debug.Error = global.api.acse.Error


-- @brief add our custom databases
ACSEDatabase.AddContentToCall = function(_tContentToCall)
	table.insert(_tContentToCall, require("Database.ACSE"))
end

