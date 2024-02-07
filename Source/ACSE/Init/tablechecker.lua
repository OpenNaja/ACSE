-----------------------------------------------------------------------
--/  @file   TableChecker.lua
--/  @author Inaki
--/
--/  @brief  Handles ACSE loading and boostraps most of the ACSE core.
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global     = _G
local api        = global.api
local ipairs     = global.ipairs
local string     = global.string
local table      = global.table
local tryrequire = global.tryrequire

local TableChecker = module(...)

local tModules = {
    'acse.default',      -- Provided by this mod.
    'acsedebug.default', -- Provided by ACSEDebug (includes /Dev processing).
    'newtablechecker',   -- Back up in case we need it at some point.
}

-- Append any 'acse.{modname}.lua' to the init list from the list of loaded
-- content packs (e.g. acse.acse.lua)
local tLoadedPackNames = api.content.GetLoadedContentPackDebugNames()
for _, sName in ipairs(tLoadedPackNames) do
    table.insert(tModules, #tModules + 1, 'acse.'.. sName)
end

local tryInit = function(sModuleName)
    sModuleName = string.lower(sModuleName)
    local tModule = tryrequire(sModuleName)
    if  tModule ~= nil and
        global.type(tModule) == 'table' and
        tModule.OnInit ~= nil then
            tModule:OnInit()
    end
end

for _, sModuleName in ipairs(tModules) do
    tryInit(sModuleName)
end

return nil
