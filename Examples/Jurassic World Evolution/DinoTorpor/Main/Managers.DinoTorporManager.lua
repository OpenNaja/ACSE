-----------------------------------------------------------------------
--/  @file   DinoTorporManager.lua
--/  @author My Self
--/
--/  @brief  Manager Script to make dinosaurs wake after being tranquilized
--           Example mod manager, bugs are expected
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local pairs = global.pairs
local require = global.require
local module = global.module
local table = require("Common.tableplus")
local Object = require("Common.object")
local Mutators = require("Environment.ModuleMutators")

--/ Create module
local DinoTorporManager= module(..., (Mutators.Manager)())

-- global.loadfile("Manager.DinoTorporManager.lua loaded")

-- @Brief Init function for the DinoTorpor mod
DinoTorporManager.Init = function(self, _tProperties, _tEnvironment)
	-- global.loadfile("Manager.DinoTorporManager:Init()")
	self.dinosAPI = api.world.GetWorldAPIs().dinosaurs
	self.tranqdDinos = {}
end


-- @Brief Manages tranqued dinos
-- @TODO remove tranqued dinos from the list if they are being transported
-- @TODO make wakeup time variable
DinoTorporManager.Advance = function(self, _nDeltaTime)
	-- Check for recently tranqued dinos and add them to the list
    local parkDinos = self.dinosAPI:GetDinosaurs(false)
    for i = 1, #parkDinos do
        local dinosaurEntity = parkDinos[i]
		if not self.dinosAPI:IsConscious(dinosaurEntity) and self.tranqdDinos[dinosaurEntity] == nil then
			self.tranqdDinos[dinosaurEntity] = 10
		end
	end

    -- wake up sleeping dinos after their wake-up period
    for k,v in pairs(self.tranqdDinos) do
		self.tranqdDinos[k] = v - _nDeltaTime
		if self.tranqdDinos[k] < 0 and not self.dinosAPI:IsDead(k) then
			self.dinosAPI:MakeConscious(k)
			self.tranqdDinos[k] = nil
		end
	end

end

-- @Brief Called when the manager is activated
DinoTorporManager.Activate = function(self)
   self.tranqdDinos = {}
end

-- @Brief Called when the manager is deactivated
DinoTorporManager.Deactivate = function(self)
   self.tranqdDinos = nil
end

-- @Brief Called when the manager needs to be finished
DinoTorporManager.Shutdown = function(self)
end

-- Validate the class methods/interfaces
(Mutators.VerifyManagerModule)(DinoTorporManager)

