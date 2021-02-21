-- Decompiled using luadec 2.2 rev:  for Lua 5.3 from https://github.com/viruscamp/luadec
-- Command line: C:\Users\J2D71~1.WAR\AppData\Local\Temp\databases.content4.lua.bin 

-- params : ...
-- function num : 0 , upvalues : _ENV
local global = _G
local api = global.api
local table = global.table
local require = require
local string = string
local DatabaseConfig = module(...)
local tConfig = {
tLoad = {
ACSEResearch = {sSymbol = "ACSEResearch"}
, 
}
, 
tCreateAndMerge = {
Research = {
tChildrenToMerge = {"ACSEResearch"}
}
,
}
}
DatabaseConfig.GetDatabaseConfig = function()
  -- function num : 0_0 , upvalues : tConfig
  return tConfig
end


