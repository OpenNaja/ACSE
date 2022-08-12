-----------------------------------------------------------------------
--/  @file   ACSELuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Handles ACSE loading and database creation
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local table = global.table
local pairs = global.pairs
local ipairs = global.ipairs
local type  = global.type
local require = require
local ACSEDatabase = module(...)

-- @brief setup a custom debug/trace system to use
global.api.asec = {}
global.api.asec.Trace = function(msg)
	global.loadfile("acse :" .. msg)
end
global.api.asec.Error = function(msg)
	global.api.asec.Trace("Err- " .. msg)
end
global.api.debug.Trace = global.api.asec.Trace
global.api.debug.Error = global.api.asec.Error

global.api.debug.Trace("Database.ACSELuaDatabase.lua loaded on " .. global._VERSION)

-- @brief add our custom databases
ACSEDatabase.AddContentToCall = function(_tContentToCall)
	table.insert(_tContentToCall, require("Database.ACSE"))
end

