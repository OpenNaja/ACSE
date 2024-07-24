-----------------------------------------------------------------------
--  @file   PrefabsExample.lua
--  @author Inaki
--
--  @brief  Adds/Changes prefab during runtime.
--
--  @note   Needs ACSEDebug to run as a script.
--
-- Execution example:
-- lf templates/prefabsexample
--
-- Result:
-- Compiled: Dev_Test_Prefab userdata:000xxxx
--
--  @setup  Copy this into a file at the [GameFolder]/Dev/Lua/Test.lua
--  @run    open the ACSEDebug console and type:  lf test
--
--  @note   The prefabs compiled here are not added to ACSE, they will not 
--          survive a change of level (restarting the level or loading a 
--          new one will destroy this version of the prefab)
--
--  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local require = global.require
local pairs = global.pairs
local Vector2 = require("Vector2")
local Vector3 = require("Vector3")

tPrefabs = {

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

for k, tInfo in global.ipairs(tPrefabs) do
    for sPrefabName, tParams in pairs(tInfo) do
        local res = global.api.entity.CompilePrefab(tParams, sPrefabName)
        global.api.debug.Trace("compiled: " .. sPrefabName .. " " .. global.type(res))
    end
end
