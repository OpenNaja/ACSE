-----------------------------------------------------------------------
--/  @file   ACSE.Game.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the Game engine API.
--/
--/  @Note   This module doesn't have a Shutdown function yet
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local require      = global.require
local tostring     = global.tostring
local table        = require('common.tableplus')
local Object       = require("Common.object")
local setmetatable = global.setmetatable

local Game = module(..., Object.class)

Game.Init = function(self)
    local raw = api.game

    api.game = setmetatable(
        {
            GetVersionString = function(...)
                return self:Api_GetVersionString(raw, ...)
            end,
            GetRawVersionString = function(...)
                return self:Api_GetRawVersionString(raw, ...)
            end
        },
        { 
            __index = raw 
        }
    )

    api.acse.game = Game
end

Game.Api_GetVersionString = function(self, _raw)
    local versionString = _raw.GetVersionString()
    for _, v in global.ipairs(api.acse.tAppendToVersionString) do
        local sep = tostring(v.sep)
        if api.game.GetGameName() == 'Planet Zoo' then
            sep = '&#xA;'
        end
        versionString = versionString .. sep .. tostring(v.text)
    end
    return versionString
end

Game.Api_GetRawVersionString = function(self, _raw)
    return _raw.GetVersionString()
end

Game.Shutdown = function(self)
    api.game = global.getmetatable(api.game).__index
end
