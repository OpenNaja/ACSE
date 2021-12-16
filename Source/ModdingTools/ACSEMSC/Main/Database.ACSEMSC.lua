-----------------------------------------------------------------------
--/  @file   Database.ACSEMSC.lua
--/  @author My Self
--/
--/  @brief  Custom shell commands for Cobra runtime Engine 
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global  = _G
local api     = global.api
local table   = global.table
local pairs   = global.pairs
local ipairs  = global.ipairs
local require = require

--/ Module creation
local ACSEMSC = module(...)

-- Dummy list of functions to add to the database.
ACSEMSC.tDatabaseMethods   = {
  --/ Park environment hook
  isACSEMSCInstalled = function()
    return true
  end,
}
-- @brief Call to ensure the module stays loaded in memory through the game database live time,
-- Otherwise, the database manager will not need our custom commands mod and might unload it 
-- eventually.
ACSEMSC.AddDatabaseFunctions = function(_tDatabaseFunctions)
  for sName,fnFunction in pairs(ACSEMSC.tDatabaseMethods) do
    _tDatabaseFunctions[sName] = fnFunction
  end
end


-- @brief Database init
ACSEMSC.Init = function()
  global.api.debug.Trace("ACSEMSC:Init()")

    -- Register our own custom shell commands
  ACSEMSC.tShellCommands = {

    --/
    --/  Api.Game commands
    --/ 

    -- Custom command to do change the simulation speed through the debug console
    --api.debug.RegisterShellCommand(
    --  ACSEMSC.fnShellCmd_API_Game_Quit, 
    --  "&Quit [{bool}]", 
    --  "Quits the game, use true to force quit and skip the prompt.\n"
    --),


  }

end


-- Moved command to ACSE for being too generic
--@Brief quits the game, with/without prompting
--ACSEMSC.fnShellCmd_API_Game_Quit = function(_tEnv, _tArgs)
--  global.api.game.Quit(_tArgs[1] or false)
--end



-- @brief Environment Shutdown
ACSEMSC.Shutdown = function()
  global.api.debug.Trace("ACSEMSC:Shutdown()")

  -- Remove custom commands
  for i,oCommand in ipairs(ACSEMSC.tShellCommands) do
    api.debug.UnregisterShellCommand(oCommand)
  end

  ACSEMSC.tShellCommands = nil
end