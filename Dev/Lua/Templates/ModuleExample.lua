-----------------------------------------------------------------------
--  @file   ModuleExample.lua
--  @author Inaki
--
--  @brief  Test Script
--
--  @note   Needs ACSEDebug to run as a script using LoadFileScript
--          The module scripts can yield() and wait, have init and shutdown.
--
-- Execution example:
-- lfs test/test arg1 arg2 23 
--
-- Result:
-- calling StartScript
-- ModuleExample:Init()
-- Args{
--  [1] = 
--    {
--      [1] = "test/ModuleExample",
--      [2] = "arg1",
--      [3] = "arg2",
--      [4] = "23"
--    }
--  }
-- ModuleExample:Run()
-- RunSub1 start
-- Slept 1 sec
-- Slept 2 secs
-- Slept 3 secs
-- RunSub1 end after 5 seconds
-- ModuleExample:Run() finished
-- ModuleExample:Shutdown()

--  @setup  Copy this into a file at the [GameFolder/]Dev/Lua/ModuleExample.lua
--  @run    open the ACSEDebug console and type:  lfs ModuleExample arg1 arg2 23
--
--  @note   The first argument is going to be the name of the script.
--  @note   Every other argument will be added to the vargarg list
--  @note   All arguments are strings, they will need to be converted
--
--  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global    = _G
local api       = global.api
local require   = global.require
local module    = global.module
local table     = require('common.tableplus')
local Object    = require("Common.object")
local Mutators  = require("Common.mutators")

local ModuleExample   = module(..., Object.subclass(Base))

ModuleExample.Init = function(self, ...)
	local args={...}
    api.debug.WriteLine(1, "ModuleExample:Init()")
    api.debug.WriteLine(1, "Args" .. table.tostring(args, nil, nil, nil, true))
    self.tWorldAPIs = api.world.GetWorldAPIs()
end

ModuleExample.Shutdown = function(self)
    api.debug.WriteLine(1, "ModuleExample:Shutdown()")
    self.tWorldAPIs = nil
end

ModuleExample.Run = function(self)
	-- Will run continuously until it returns
    api.debug.WriteLine(1, "ModuleExample:Run()")

    self:RunSub1()

    api.debug.WriteLine(1, "ModuleExample:Run() finished")
end

ModuleExample.RunSub1 = function(self)
    api.debug.WriteLine(1, "RunSub1 start")
    api.time.Sleep(1)
    api.debug.WriteLine(1, "Slept 1 sec")
    api.time.Sleep(1)
    api.debug.WriteLine(1, "Slept 2 secs")
    api.time.Sleep(1)
    api.debug.WriteLine(1, "Slept 3 secs")
    api.time.Sleep(2)
    api.debug.WriteLine(1, "RunSub1 end after 5 seconds")
end

-- We need to return the script
return ModuleExample
