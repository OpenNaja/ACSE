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
local tryrequire = global.tryrequire

local TableChecker = module(...)

local tModules = {
    'acse.default',      -- Provided by this mod.
    'acsedebug.default', -- Provided by ACSEDebug (includes /Dev processing).
    'newtablechecker',   -- Back up in case we need it at some point.
}

for _, sModuleName in ipairs(tModules) do
    sModuleName = string.lower(sModuleName)
    local tModule = tryrequire(sModuleName)
    if tModule ~= nil and global.type(tModule) == 'table' then
        if tModule.OnInit then
            tModule:OnInit()
        end
    end
end

return nil
