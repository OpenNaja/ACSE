-----------------------------------------------------------------------
--/  @file   Environments.StartScreenEnvironment.lua
--/  @author My Self
--/
--/  @brief  Starting Screen Environments definition for Jurassic World 2
--/			 Evolution
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global   = _G
local api      = global.api
local require  = global.require
local module   = global.module
local type     = global.type
local pairs    = global.pairs
local loadfile = global.loadfile
local Main     = require("Database.Main")
local GameDatabase = require("Database.GameDatabase")
local Mutators = require("Environment.ModuleMutators")
local Module   = module(..., Mutators.EnvironmentPrototype)

api.debug.Trace("Custom StartScreen Environment loaded")

-- Default Start Screen Environment defintion from JWE 1.8
Module.EnvironmentPrototype = {
	SearchPaths = {"Managers"}, 
	Managers = {
		["Managers.GameUnlockManager"] = {}, 
		["Managers.GameWideProgressManager"] = {}, 
		["Managers.RecordsManager"] = {}, 
		["Managers.InGenDatabaseManager"] = {}, 
		["Managers.InGenDatabaseUIManager"] = {}, 
		["Managers.ManagementNewFlagManager"] = {}, 
		["Managers.GeneLibraryManager"] = {}, 
		["Managers.DigSiteManager"] = {}
	}
}



-- Merge default protos with ACSE collected protos
if GameDatabase.GetStartEnvironmentManagers then

	Module._merge = function(a, b, bModifyOnly)
	    if global.type(a) == "table" and global.type(b) == "table" then
	        for k, v in global.pairs(b) do
	            if global.type(v) == "table" and global.type(a[k] or false) == "table" then
	                Module._merge(a[k], v, bModifyOnly)
	            else
	            	if not bModifyOnly or bModifyOnly == false or (bModifyOnly == true and a[k] ~= nil) then
	                	a[k] = v
	                end
	            end
	        end
	    end
	    return a
	end

  for _sName, _tParams in global.pairs( GameDatabase.GetStartEnvironmentManagers() ) do

		if not _tParams.__inheritance or _tParams.__inheritance == 'Overwrite' then
			api.debug.Trace("ACSE Adding Manager: " .. _sName)
			Module.EnvironmentPrototype['Managers'][_sName] = _tParams
		end
		if _tParams.__inheritance == 'Append' then
			api.debug.Trace("ACSE Merging Manager: " .. _sName)
			Module.EnvironmentPrototype['Managers'][_sName] = _merge(Module.EnvironmentPrototype['Managers'][_sName], _tParams)
		end
		if _tParams.__inheritance == 'Modify' then
			api.debug.Trace("ACSE Modifying Manager: " .. _sName)
			Module.EnvironmentPrototype['Managers'][_sName] = _merge(Module.EnvironmentPrototype['Managers'][_sName], _tParams, true)
		end
		-- Any other case will be ignored
  end
end

-- confirm the environment comply its proto
(Mutators.VerifyEnvironmentPrototypeModule)(Module)
