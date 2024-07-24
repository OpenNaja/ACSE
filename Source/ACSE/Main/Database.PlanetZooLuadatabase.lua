-----------------------------------------------------------------------
--/  @file   Database.PlanetZooLuaDatabase.lua
--/  @author Inaki
--/
--/  @brief  Creates the database prototypes for all ACSE information
--/          related to Planet Zoo game.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global          = _G
local api             = global.api
local tostring        = global.tostring
local pairs           = global.pairs
local type            = global.type
local ipairs          = global.ipairs
local next            = global.next
local string          = global.string
local require         = global.require
local tryrequire      = global.tryrequire
local table           = require("Common.tableplus")
local StringUtils     = require("Common.stringUtils")
local Main            = require("Database.Main")

local GameDatabase    = require("Database.GameDatabase")

local PlanetZooLuaDatabase = module(...)

PlanetZooLuaDatabase.Init = function()
    api.debug.Trace("PlanetZooLuaDatabase.Init()")
end

PlanetZooLuaDatabase.tManagers = {
--[[    
    ["Environments.StartScreenEnvironment"] = {
    },
    ["Environments.DarwinEnvironment"] = {
    }    
--]]
}

-- @brief Add our custom Manager to the different environments
PlanetZooLuaDatabase.AddLuaManagers = function(_fnAdd)
    for sManagerName, tParams in pairs(PlanetZooLuaDatabase.tManagers) do
        _fnAdd(sManagerName, tParams)
    end
end
