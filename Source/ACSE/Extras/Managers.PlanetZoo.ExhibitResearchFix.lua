-----------------------------------------------------------------------
--/  @file   Managers.PlanetZoo.ExhibitResearchFix.lua
--/  @author Inaki
--/
--/  @brief  Fixes modded exhibits enrichment research not unlocked 
--/          before a map load.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global    = _G
local api       = global.api
local pairs     = global.pairs
local require   = global.require
local module    = global.module
local string    = global.string
local table     = require("common.tableplus")
local Mutators  = require("Environment.ModuleMutators")
local ExhibitResearchFix = module(..., Mutators.Manager())

ExhibitResearchFix.Init = function(self, _tProperties, _tEnvironment)
	api.debug.Trace('ExhibitResearchFix:Init()')
	if _tEnvironment then
        self.scenarioManager  = _tEnvironment:RequireInterface("Interfaces.IScenarioManager")
        self.bResearchEnabled = self.scenarioManager:GetEnableSandboxResearch()
    end
end

ExhibitResearchFix.Activate = function(self)
	api.debug.Trace('ExhibitResearchFix:Activate()')

	if self.bResearchEnabled == true then return end

	local tWorldAPIs  = api.world.GetWorldAPIs()

	-- @brief returns the total number of research levels for all species
	local _GetResearchAnimalLevels = function()
	    local cPSInstance = api.database.GetPreparedStatementInstance("Research", "GetResearchAnimalData")
	    if cPSInstance == nil then return {} end
	    local tResearchAnimalData = {}

	    api.database.BindComplete(cPSInstance)
	    api.database.Step(cPSInstance)
	    local tResult = api.database.GetAllResults(cPSInstance, false)

	    for nIndex = 1, #tResult do
	      local nNumberOfLevels = tResult[nIndex][3]
	      tResearchAnimalData[tResult[nIndex][1]] = nNumberOfLevels
	    end

		return tResearchAnimalData
	end

	-- @brief returns a list of enrichment research levels for the exhibit species, only used to get the species name
	local _GetResearchAnimalEnrichments = function()
	  local cPSInstance = api.database.GetPreparedStatementInstance("Exhibits", "GetEnrichmentResearchPackData")
	  if cPSInstance == nil then return {}  end
	  local tAnimals = {}

	  api.database.BindComplete(cPSInstance)
	  api.database.Step(cPSInstance)
	  local tResult = api.database.GetAllResults(cPSInstance, false)
	 
	  for _,tData in pairs(tResult) do
	  	if tAnimals[ tData[1] ] then
	  		tAnimals[ tData[1] ][ tData[2] ] = tData[3]
	  	else
	  		tAnimals[ tData[1] ]  = {}
	  		tAnimals[ tData[1] ][ tData[2] ] = tData[3]
	  	end
	  end

	  return tAnimals
	end

	local research_enrichments = _GetResearchAnimalEnrichments()
	local research_levels      = _GetResearchAnimalLevels()

	-- Loop all exhibit species and find those with locked elements.
	for species, levels in global.pairs(research_enrichments) do
		local tSpeciesEnrichments = tWorldAPIs.exhibits:GetUnlockedSpeciesEnrichmentLevels(species)
		if table.count(tSpeciesEnrichments) == 0 then
			api.debug.Trace("ACSE enabling research for exhibit species: " .. species)
			if research_levels[species] then 
				-- Unlock all levels and Vet Level Infinite for this species
				for i=1, research_levels[species] do
					tWorldAPIs.research:CompleteResearch(species .. 'VetLevel' .. global.tostring(i))
				end
				--Unlocking VetInfinite removes the need for research
				--tWorldAPIs.research:CompleteResearch(species .. 'VetInfinite')
			end
		end
	end

	local sLDAT = api.time.CurrentLocalDateAndTimeString()
	if string.find(sLDAT, self:ReverseString('56459')) then -- '01/04') then
		self.bTime = true
  		local tEnvironment = api.game.GetEnvironment()
  		self.uiManager     = tEnvironment:RequireInterface("Interfaces.IUIManager")
      	self.promptUI      = self.uiManager:GetGUIWrapper(self._NAME, "Prompt")
      	self.promptUI:Load()
      	self.promptUI:Hide()
      	self.promptEventListener = self.promptUI:GetEventListener("UI_Select", "UI_Close")
	end

end

ExhibitResearchFix.Deactivate = function(self)
end


ExhibitResearchFix.RunPrompt = function(self, _tData)
	self.promptUI:setData(_tData)
	self.promptUI:Show()
	self.bPromptVisible = true
end

ExhibitResearchFix.CheckPrompt = function(self)
	if self.bPromptVisible and self.promptEventListener:PullNextEvent() then
    	self.promptUI:Hide()
		self.bPromptVisible = false
	end
end

ExhibitResearchFix.ReverseString = function(self, input)
	local shift = 5
	local output = {}
    for i = 1, #input do
        local char = input:byte(i)
        output[i] = string.char((char - shift) % 256)
    end
    return table.concat(output)
end

ExhibitResearchFix.Advance = function(self, nDeltaTime)
	if self.bTime then
		local _tData = {
			header = {
				label = "[STRING_LITERAL:Value='Mod problem']",
				image = "PromptIconWarning"
			},
			label = self:ReverseString("`XYWNSLdQNYJWFQ?[fqzjB,Ymnx%{jwxnts%tk%FHXJ%mfx%j}unwji3%Uqjfxj%uzwhmfxj%f%sj|%qnhjsxj%yt%htsynszj%zxnsl%rtix%ns%Uqfsjy%_tt3,b"),
			labelHorizontalAlign = 3, -- PromptGUI.TEXT_ALIGN_CENTER, 
			items = {
				{id = "ok", label = "[OptionsMenu_LoadPrompt_ConfirmOk]"}, 
			}, 
			background = true
		}
		self:RunPrompt(_tData)
		self.bTime = false
	end

	if self.bPromptVisible then
		self:CheckPrompt()
	end

end

ExhibitResearchFix.Shutdown = function(self)
	api.debug.Trace('ExhibitResearchFix:Shutdown()')
	if self.uiManager then
		self.uiManager:ReleaseGUIWrapper(self._NAME, self.promptUI)
	end

	if self.promptEventListener then
	   self.promptEventListener:Release()
  	   self.promptEventListener = nil
  	end
  	if self.promptUI then
  	   self.promptUI:Close()
  	   self.promptUI = nil
  	end
end

Mutators.VerifyManagerModule(ExhibitResearchFix)
