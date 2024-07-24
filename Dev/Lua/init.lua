-----------------------------------------------------------------------
--  @file   dev/Lua/init.lua
--  @author inaki
--
--  @brief  Creates a development environment in the running game.
--
--  The purpose of this file is to allow rapid testing/debugging of
--  different things without needing to create a custom mod for it.
--
--  This file is added by ACSEDebug as a Database manager, exposing all
--  it CallOnContent methods to the game.
--  
--  @note requires ACSEDebug
-----------------------------------------------------------------------
local global  = _G
local api     = global.api
local type    = type
local pairs   = pairs
local ipairs  = ipairs
local next    = global.next
local string  = global.string
local require = global.require

local Dev = module(...)

-- Definition of our own database methods
Dev.tDatabaseMethods = {
    DevTest = function()
        return 42
    end,
    -- ...
}

-- @brief adds our custom database methods to the main game database
Dev.AddDatabaseFunctions = function(_tDatabaseFunctions)
    for sName, fnFunction in pairs(Dev.tDatabaseMethods) do
        _tDatabaseFunctions[sName] = fnFunction
    end
end

-- Definition of our own player methods
Dev.tPlayerMethods = {
    DevPlayerTest = function(_tPlayer, bTest)
        --_tPlayer.bBooleanValue = bTest
    end
    -- ...
}

-- @brief adds our custom methods to the player table
Dev.AddPlayerMethods = function(_tPlayerMethods)
    for sMethod, fnMethod in pairs(Dev.tPlayerMethods) do
        _tPlayerMethods[sMethod] = fnMethod
    end
end

-- @brief Allows adding attributes to a new player
Dev.AddPlayer = function(_tPlayer)
    global.api.debug.Trace("Dev:AddPlayer()")
    --_tPlayer.bBooleanValue = false
end

-- @brief Allows saving information to file in this player profile
Dev.SavePlayer = function(_tPlayer, _saver)
    global.api.debug.Trace("Dev:SavePlayer()")
    -- _saver is the table being saved with our data.
    --_saver.bBooleanValue = _tPlayer.bBooleanValue
end

-- @brief Allows loading information from file of this player profile
Dev.LoadPlayer = function(_tPlayer, _loader)
    global.api.debug.Trace("Dev:LoadPlayer()")
    -- _loader is the table loaded from the file with our data
    --_tPlayer.bBooleanValue = _loader.bBooleanValue
end

-- @brief Notifies a player is removed
Dev.RemovePlayer = function(_tPlayer)
    global.api.debug.Trace("Dev:RemovePlayer()")
    --_tPlayer.bBooleanValue = _loader.bBooleanValue
end

-- List of custom managers to force injection on the starting screen
Dev.tStartScreenManagers = {
--    ["Managers.MySceneryDebugManager"] = {},
}

-- @brief Add our custom Manager to the starting screen
Dev.AddStartScreenManagers = function(_fnAdd)
    local tData = Dev.tStartScreenManagers
    for sManagerName, tParams in pairs(tData) do
        global.api.debug.RunShellCommand("ImportModule " .. sManagerName)
        _fnAdd(sManagerName, tParams)
    end
end

-- List of custom managers to force injection on a park
Dev.tParkManagers = {
--    ["Managers.MySceneryDebugManager"] = {},
}

-- @brief Add our custom Manager to the starting screen
Dev.AddParkManagers = function(_fnAdd)
    local tData = Dev.tParkManagers
    for sManagerName, tParams in pairs(tData) do
        global.api.debug.RunShellCommand("ImportModule " .. sManagerName)
        _fnAdd(sManagerName, tParams)
    end
end

-- List of custom managers to force injection on different game environments
-- separated by environment
Dev.tManagers = {}

-- @brief Add our custom Manager to the starting screen
Dev.AddManagers = function(_fnAdd)
    local tData = Dev.tManagers
    for sEnvironmentName, tParams in pairs(tData) do
        _fnAdd(sEnvironmentName, tParams)
    end
end

-- List of custom prefabs
Dev.tPrefabs = {
    {
        -- You can either provide a new prefab or re-define an existing one
        Dev_Test_Prefab = {
            Components = {
                Transform = {

                }
            }
        }
    },
}

-- @brief add custom prefabs to the game
Dev.AddLuaPrefabs = function(_fnAdd)
    local tData = Dev.tPrefabs
    for k, tInfo in global.ipairs(tData) do
        for sPrefabName, tParams in pairs(tInfo) do
            _fnAdd(sPrefabName, tParams)
        end
    end
end



-- List of custom components to force injection to a park
Dev.tComponents = {
   -- RemoteConsole = 'components.debug.remoteconsole'
}

-- @brief add custom components to the game
Dev.AddLuaComponents = function(_fnAdd)
    local tData = Dev.tComponents
    for sComponentName, tParams in pairs(tData) do
        global.api.debug.RunShellCommand("ImportModule " .. tParams)
        _fnAdd(sComponentName, tParams)
    end
end

-- @brief Database after Init setup
Dev.Setup = function()
    global.api.debug.Trace("Dev:Setup()")
end

-- @brief Database soft restart
Dev.ShutdownForReInit = function()
    global.api.debug.Trace("Dev:ShutdownForReInit()")
end

-- @Brief Do not use, add your commands inside the init() function
Dev.tShellCommands = {}

-- @brief Database init
Dev.Init = function()
    global.api.debug.Trace("Dev:Init()")

    -- Register our own custom shell commands
    Dev.tShellCommands = {
        -- Custom command to do return the input as output 
        global.api.debug.RegisterShellCommand(
            -- Function to run
            function(tEnv, tArgs)
                if #tArgs < 1 then
                    return false, "Needs at least one argument."
                end
                return true, global.tostring(tArgs[1])
            end,
            "Echo {string}",
            "Writes the input string back to the console.\n"
        ),
        -- Crash to desktop
        global.api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                local t = require(tArgs[3]:value())
            end,
            "&Crash&To&Desktop",
            "Crash the game.\n"
        ),

        -- ...
    }
end

-- @brief Database Shutdown
Dev.Shutdown = function()
    global.api.debug.Trace("Dev:Shutdown()")

    -- Remove custom commands
    for i, oCommand in ipairs(Dev.tShellCommands) do
        global.api.debug.UnregisterShellCommand(oCommand)
    end

    Dev.tShellCommands = nil
end
