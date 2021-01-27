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
local math = global.math
local table = require("Common.tableplus")
local Vector3 = require("Vector3")
local Quaternion = require("Quaternion")
local Object = require("Common.object")
local Mutators = require("Environment.ModuleMutators")

--/ Create module
local DinoTorporManager= module(..., (Mutators.Manager)())

global.api.debug.Trace("acse Manager.DinoTorporManager.lua loaded")

-- @Brief Init function for the DinoTorpor mod
DinoTorporManager.Init = function(self, _tProperties, _tEnvironment)
	global.api.debug.Trace("acse Manager.DinoTorporManager Init")

	self.worldAPIS  = api.world.GetWorldAPIs()
	self.dinosAPI   = self.worldAPIS.dinosaurs
	self.weaponsAPI = self.worldAPIS.weapons
	self.messageAPI = global.api.messaging
	self.tranqdDinos = {}

	self.tMessageRecievers = {
		--/ Used to register when a dinosaur is tranquillised
		[self.messageAPI.MsgType_DinosaurActionMessage] = function(_tMessages)
			self:_fnHandleDinosaurActionReceiver(_tMessages)
		end,
		--/ Used to register when a dinosaur is killed or dies
		[self.messageAPI.MsgType_DinosaurDeathMessage] = function(_tMessages)
			self:_fnDinosaurDeathReceiver(_tMessages)
		end,
		--/ Used to register when a dinosaur is shot (even when already tranquillised)
		[self.messageAPI.MsgType_ProjectileImpactMessage] = function(_tMessages)
			self:_fnProjectileImpactReceiver(_tMessages)
		end
	}
	--/ Register the manager receivers
	for nMessageType,fnReceiver in pairs(self.tMessageRecievers) do
		self.messageAPI.RegisterReceiver(nMessageType, fnReceiver)
	end
end


-- @Brief Manages tranqued dinos
-- @TODO remove tranqued dinos from the list if they are being transported
DinoTorporManager.Advance = function(self, _nDeltaTime)
	-- Check for recently tranqued dinos and add them to the list, looping all dinos on
	-- Advance is quite expensive, it was moved to a callback
    -- local parkDinos = self.dinosAPI:GetDinosaurs(false)
	-- for i = 1, #parkDinos do
	-- 		local dinosaurEntity = parkDinos[i]
	-- end

    -- wake up sleeping dinos after their wake-up period
    for dinosaurEntity,v in pairs(self.tranqdDinos) do
		self.tranqdDinos[dinosaurEntity] = v - _nDeltaTime
		if self.tranqdDinos[dinosaurEntity] < 0 and self:IsValidDinosaur(dinosaurEntity) then
			self:TryWakeUpEntity(dinosaurEntity)
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
	--/ clear all callback handlers
    for nMessageType,fnReceiver in pairs(self.tMessageRecievers) do
      self.messageAPI.UnregisterReceiver(nMessageType, fnReceiver)
    end
    self.tMessageRecievers = nil
end

--[[
Table of api.dinosaurs actions, not in order

DAT_FinishedHuntingLiveBait
DAT_CountermeasuresApplied
DAT_AttackedCar
DAT_AttackedFenceUnsuccessfully
DAT_AttackedFenceSuccessfully
DAT_StartedFighting
DAT_FinishedFighting
DAT_Tranquillised
DAT_TranquillisedCount
DAT_WokeUp
DAT_GotDisease"
DAT_NoLongerDiseased
DAT_KilledGuest
DAT_KilledDinosaur
DAT_WonFight
DAT_Terrorising
DAT_InjuredGuest
DAT_FinishedHunting
]]

-- @Brief Receives dinosaur actions
DinoTorporManager._fnHandleDinosaurActionReceiver = function(self, _tMessages)
	for _,tMessage in pairs(_tMessages) do
		--/ nAction
		--/ nEntity
		--/ nOtherEntity
		if tMessage.nAction == self.dinosAPI.DAT_Tranquillised then
			-- Add the dinosaur to the list of Tranqed dinos
			self:TryAddEntity(tMessage.nEntity)
		end
	end
end

-- @Brief Receives dinosaur deaths
DinoTorporManager._fnDinosaurDeathReceiver = function(self, _tMessages)
	for _,tMessage in pairs(_tMessages) do
		--/ nEntityID
		--/ sCauseOfDeath
		--/ sDiseaseType
		--/ Forced removal of dinosaur from the tranqued table
		self.tranqdDinos[tMessage.nEntityID] = nil
	end
end

-- @Brief Receives projectile impacts
DinoTorporManager._fnProjectileImpactReceiver = function(self, _tMessages)
	for _,tMessage in pairs(_tMessages) do
		--/ MsgType_ProjectileImpactMessage
		--/ Vector3 vPosition
		--/ number  nHitEntity
		--/ number  nGunEntity
		--/ number  nProjectileEntity
		if   self:IsValidDinosaur(tMessage.nHitEntity)
		and  self.weaponsAPI:GetProjectileType(tMessage.nProjectileEntity) == self.weaponsAPI.ProjectileType_Sedative then
			self:TryAddTorpor( tMessage.nHitEntity, math.random() * 5 + 25 )
		end
	end
end


-- @Brief Confirm a dinosaur is a valid target
DinoTorporManager.IsValidDinosaur = function(self, nEntityID)
	if  self.dinosAPI:IsDinosaur(nEntityID) and
	not self.dinosAPI:IsDead(nEntityID) and
	not self.dinosAPI:IsLiveBait(nEntityID) and
	not self.dinosAPI:IsPterosaur(nEntityID) and
	not self.dinosAPI:IsAirborne(nEntityID) then
		return true
	end

	return false
end

-- @Brief Adds torpor to the dino if shot while tranquillised
DinoTorporManager.TryAddTorpor = function(self, nEntityID, nValue)
	if self:IsValidDinosaur(nEntityID) and self.tranqdDinos[nEntityID] then
		self.tranqdDinos[nEntityID] = self.tranqdDinos[nEntityID] + nValue
	end

	-- Something to look up later
	-- local nAwakeness = self.dinosAPI:GetSatisfactionLevel(dinosaurEntity, self.dinosAPI.DNT_Drowsiness)
end

-- @Brief Adds an entry to the wake up list
DinoTorporManager.TryAddEntity = function(self, nEntityID)
	global.api.debug.Trace("acse _TryAddEntity" .. nEntityID)
	if self:IsValidDinosaur(nEntityID) then
		local Traits = self.dinosAPI:GetDinosaurTraits(nEntityID)
		self.tranqdDinos[nEntityID] = math.sqrt(Traits.sedativeResistance) * 15 + math.random() * math.sqrt(Traits.size)

	end
end

-- @Brief Tries to wake up an entity
DinoTorporManager.TryWakeUpEntity = function(self, nEntityID)
	global.api.debug.Trace("acse _TryWakeUpEntity" .. nEntityID)
	if self:IsValidDinosaur(nEntityID) then

		local dinoTransform = api.transform.CalculateWorldTransform(nEntityID)
		dinoTransform = dinoTransform:WithOr((Quaternion.FromUF)(Vector3.YAxis , (dinoTransform:GetOr()):GetF()))
		self.dinosAPI:DinosaurTeleportTo(nEntityID, dinoTransform)
		self.dinosAPI:MakeConscious(nEntityID)

		global.api.debug.Trace("acse _TryWakeUpEntity" .. nEntityID .. " set conscious")
	end

	self.tranqdDinos[nEntityID] = nil
end

-- Validate the class methods/interfaces
(Mutators.VerifyManagerModule)(DinoTorporManager)


