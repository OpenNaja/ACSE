-----------------------------------------------------------------------
--/  @file   ACSEDebug.Game.lua
--/  @author Inaki
--/
--/  @brief  Patches and initializes the Game engine API.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local string       = global.string
local require      = global.require
local table        = global.table
local tostring     = global.tostring
local package      = global.package
local Object       = require("Common.object")
local setmetatable = global.setmetatable

global.loadfile("acse : ACSEDebug.game.lua loaded")

local Game = module(..., Object.class)

Game.Init = function(self)
    local raw            = api.game
    local GetCommandLine =  package.loadlib(".\\Win64\\ovldata\\ACSEDebug\\ACSEDebug", 'fnGetCommandLine')
    self.sCommandLine    = global.tostring(GetCommandLine())

    api.game = setmetatable(
        {
            GetCommandLine = function(...)
                return self:Api_GetCommandLine(raw, ...)
            end,
            GetCommandLineArgument = function(...)
                return self:Api_GetCommandLineArgument(raw, ...)
            end,
            HasCommandLineArgument = function(...)
                return self:Api_HasCommandLineArgument(raw, ...)
            end,
        },
        { 
            __index = raw 
        }
    )
    api.acsedebug.game = Game
end

Game._GetCommandLine = function(self)
    if self.sCommandLine == nil then 
        self.sCommandLine = self.GetCommandLine()
    end
    return self.sCommandLine
end

Game.Api_GetCommandLine = function(self, _raw)
    return self:_GetCommandLine() -- self.GetCommandLine()
end

Game.Api_GetCommandLineArgument = function(self, _raw, sArgument)
    -- api.debug.Trace("Game.Api_GetCommandLineArgument "  .. global.tostring(sArgument))
    local tArgs = {}
    local sCommandLine = self:_GetCommandLine() -- self:Api_GetCommandLine()
    for token in string.gmatch(sCommandLine, "[^%s]+") do
        table.insert(tArgs, token)
    end
    for k,v in global.ipairs(tArgs) do
        if v == sArgument then 
            if k >= #tArgs then return nil end
            return tArgs[k+1]
        end
    end
    return nil
end

Game.Api_HasCommandLineArgument = function(self, _raw, sArgument)
    -- api.debug.Trace("Game.Api_HasCommandLineArgument "  .. global.tostring(sArgument))
    local tArgs = {}
    local sCommandLine = self:_GetCommandLine() -- self:Api_GetCommandLine()
    for token in string.gmatch(sCommandLine, "[^%s]+") do
        tArgs[token] = true
    end
    return tArgs[sArgument] ~= nil
end

Game.Shutdown = function(self)
    api.game = global.getmetatable(api.game).__index
end