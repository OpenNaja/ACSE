-----------------------------------------------------------------------
--/  @file   ACSE.Debug.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the debug core api of the engine
--/
--/  @Note   This module doesn't do anything at the moment
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local require      = global.require
local package      = global.package
local type         = global.type
local tostring     = global.tostring
local table        = require('common.tableplus')
local GameDatabase = require("Database.GameDatabase")

local Object       = require("Common.object")

global.loadfile("acse : ACSE.debug.lua loaded")

local Debug = module(..., Object.class)

Debug.Init = function(self)

    -- List of modifications
    self._tHandlers = {}

    api.acse.debug = Debug
end

Debug.Shutdown = function(self)

end

