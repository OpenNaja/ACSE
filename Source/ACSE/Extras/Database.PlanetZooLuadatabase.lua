-----------------------------------------------------------------------
--/  @file   Database.PlanetZooLuaDatabase.lua
--/  @author Inaki
--/
--/  @brief  Creates the database prototypes for all ACSE information
--/          related to Planet Zoo game.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global          = _G
local api             = global.api
local pairs           = global.pairs
local require         = global.require

local PlanetZooLuaDatabase = module(...)

PlanetZooLuaDatabase.Init = function()
    api.debug.Trace("PlanetZooLuaDatabase.Init()")
end

-- @brief Add our custom Manager to the different environments
PlanetZooLuaDatabase.AddLuaManagers = function(_fnAdd)

    local tManagers = {
    --[[    
        ["Environments.StartScreenEnvironment"] = {
        },
    --]]
        ["Environments.DarwinEnvironment"] = {
            ['Managers.PlanetZoo.ExhibitResearchFix'] = {}
        }    
    }

    for sManagerName, tParams in pairs(tManagers) do
        _fnAdd(sManagerName, tParams)
    end
end



-- @brief Add our custom Components for this game
PlanetZooLuaDatabase.AddLuaComponents = function(_fnAdd)
    -- api name and name of the lua files with the component class
    local tComponents = {
        JuvenileScale  = 'Components.PlanetZoo.JuvenileScale',
        ExhibitScale   = 'Components.PlanetZoo.ExhibitScale',
        ExhibitVariant = 'Components.PlanetZoo.ExhibitVariant',
        ExhibitManis   = 'Components.PlanetZoo.ExhibitManis',
    }
    for sComponentName, tParams in global.pairs(tComponents) do
        _fnAdd(sComponentName, tParams)
    end
end