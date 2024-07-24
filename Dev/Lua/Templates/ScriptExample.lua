-----------------------------------------------------------------------
--  @file   ScriptExample.lua
--  @author Inaki
--
--  @brief  Test Script
--
--  @note   Needs ACSEDebug to run as a script.
--
-- Execution example:
-- lf templates/scriptexample arg1 arg2 23 
--
-- Result:
-- Running Test
-- {
--   [1] = 'templates/scriptexample'    
--   [2] = 'arg1'
--   [3] = 'arg2'
--   [4] = '23'
-- }
-- Execution Complete!
--
--  @setup  Copy this into a file at the [GameFolder]/Dev/Lua/Test.lua
--  @run    open the ACSEDebug console and type:  lf test arg1 arg2 23
--
--  @note   The first argument is going to be the name of the script.
--  @note   Every other argument will be added to the vargarg list
--  @note   All arguments are strings, they will need to be converted
--
--  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local require = global.require
local table = require('common.tableplus')

-- Retrieve arguments as varargs
local args={...}

api.debug.WriteLine(1,"Running Test")
api.debug.WriteLine(1, table.tostring(args, nil, nil, nil, true))
api.debug.WriteLine(1,"Execution complete!")
