-----------------------------------------------------------------------
--/  @file   ParkEnvironment.lua
--/  @author My Self
--/
--/  @frief  Park Environments definition for Jurassic World Evolution
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local loadfile = global.loadfile
local require = global.require
local module = global.module
local type = global.type
local pairs = global.pairs
local GameDatabase = require("Database.GameDatabase")
local Mutators = require("Environment.ModuleMutators")
local Module = module(..., Mutators.EnvironmentPrototype)

global.api.debug.Trace("Custom Park Environment loaded")

-- Default Park Environment defintion from JWE 1.8
Module.EnvironmentPrototype = {
	SearchPaths = {"Managers"},
	Managers = {
		["Managers.CameraShakeManager"] = {},
		["Managers.CareerProgressManager"] = {},
		["Managers.CinematicsManager"] = {},
		["Managers.ColourGradingManager"] = {},
		["Managers.CommsManager"] = {},
		["Managers.DigSiteManager"] = {},
		["Managers.DinosaurLoanManager"] = {},
		["Managers.DinosaurThreatManager"] = {},
		["Managers.DisableBuildingManager"] = {},
		["Managers.DiseaseManager"] = {},
		["Managers.DiversityLimitManager"] = {},
		["Managers.DualShockLightingManager"] = {},
		["Managers.ExpeditionManager"] = {},
		["Managers.FossilExtractionManager"] = {},
		["Managers.FossilInventoryManager"] = {},
		["Managers.HelpManager"] = {},
		["Managers.GameUnlockManager"] = {},
		["Managers.GameWideProgressManager"] = {},
		["Managers.GeneLibraryManager"] = {},
		["Managers.GeneticEngineeringManager"] = {},
		["Managers.GenomeLibraryManager"] = {},
		["Managers.GlobalBuildingStatusManager"] = {},
		["Managers.InGenDatabaseManager"] = {},
		["Managers.IslandIntroManager"] = {},
		["Managers.IslandProgressManager"] = {},
		["Managers.IslandSwitchManager"] = {},
		["Managers.LocalBuildingStatusManager"] = {},
		["Managers.PhotoRewardManager"] = {},
		["Managers.ManagementNewFlagManager"] = {},
		["Managers.MapOverlayManager"] = {},
		["Managers.MissionManager"] = {},
		["Managers.MissionTestUI"] = {},
		["Managers.NotificationManager"] = {},
		["Managers.ParkSystemsDisableManager"] = {},
		["Managers.PlantListDatastoreManager"] = {},
		["Managers.RecordsManager"] = {},
		["Managers.ResearchManager"] = {},
		["Managers.RewardUnlockManager"] = {},
		["Managers.SabotageManager"] = {},
		["Managers.SandboxSettingsManager"] = {},
		["Managers.StormManager"] = {},
		["Managers.TabPersistenceManager"] = {},
		["Managers.TelemetryMessageManager"] = {},
		["Managers.TutorialUIManager"] = {},
		["Managers.DinosaurSimulationDataManager"] = {},
		["Managers.VehicleSkinUnlockManager"] = {},
		["Managers.VehicleSurvivalManager"] = {},
		["Managers.VOManager"] = {},
		["Managers.WildPterosaurManager"] = {},
		["Managers.UIModeManager"] = {
			Modes = {
				Empty  = "Editors.Shared.EmptyUIMode",
				Select  = "Editors.Select.SelectUIMode",
				Terrain = "Editors.Terrain.TerrainEditUIMode",
				Building = "Editors.Building.BuildingUIMode",
				EditBuildingUpgrades = "Editors.EditBuildingUpgrades.EditBuildingUpgradesUIMode",
				Delete = "Editors.Delete.DeleteUIMode",
				Repair = "Editors.Repair.RepairUIMode",
				Management = "Editors.Management.ManagementUIMode",
				DinoTest = "Editors.Test.DinoTestUIMode",
				DriveVehicle = "Editors.Vehicle.DriveVehicleUIMode",
				VehicleGunner = "Editors.Vehicle.VehicleGunnerUIMode",
				VehiclePhoto = "Editors.Vehicle.VehiclePhotoUIMode",
				VehicleAITest = "Editors.Test.VehicleAITestUIMode",
				InspectDinosaur = "Editors.Dinosaur.InspectDinosaurUIMode",
				DinosaurBirth = "Editors.Dinosaur.DinosaurBirthUIMode",
				TransportSelectDinosaur = "Editors.Dinosaur.TransportSelectDinosaurUIMode",
				SelectDinosaurDestination = "Editors.Dinosaur.SelectDinosaurDestinationUIMode",
				OrbitPteranodon = "Editors.Dinosaur.OrbitPteranodonUIMode",
				InspectBuilding = "Editors.InspectBuilding.InspectBuildingUIMode",
				InspectVehicle = "Editors.Vehicle.InspectVehicleUIMode",
				SelectVehicleDestination = "Editors.Vehicle.SelectVehicleDestinationUIMode",
				TornadoTest = "Editors.Test.TornadoTestUIMode",
				Map = "Editors.Map.MapUIMode",
				GeneSplicer = "Editors.GeneSplicer.GeneSplicerUIMode",
				SelectViewMode = "Editors.ViewModes.SelectViewModeUIMode",
				AudioTest = "Editors.Test.AudioTestUIMode",
				Cinematic = "Editors.Cinematic.CinematicUIMode",
				ViewFromBuilding = "Editors.InspectBuilding.ViewFromBuildingUIMode",
				Capture = "Editors.Capture.CaptureUIMode",
				IslandEntityPlace = "Editors.Test.IslandEntityPlaceUIMode"
			},
			InitialMode = "Select"},
		["Managers.EditModeManager"] = {
			Modes = {
				Empty = "Editors.Shared.EmptyEditMode",
				Select = "Editors.Select.SelectMode",
				Terrain = "Editors.Terrain.TerrainEditMode",
				Building = "Editors.Building.BuildingMode",
				EditBuildingUpgrades = "Editors.EditBuildingUpgrades.EditBuildingUpgradesMode",
				Delete = "Editors.Delete.DeleteMode",
				Repair = "Editors.Repair.RepairMode",
				DinoTest = "Editors.Test.DinoTestMode",
				VehicleAITest = "Editors.Test.VehicleAITestMode",
				InspectBuilding = "Editors.InspectBuilding.InspectBuildingMode",
				TornadoTest = "Editors.Test.TornadoTestMode",
				Map = "Editors.Map.MapMode",
				AudioTest = "Editors.Test.AudioTestMode",
				Capture = "Editors.Capture.CaptureMode",
				IslandEntityPlace = "Editors.Test.IslandEntityPlaceMode"
			},
			InitialMode = "Select"},
		["Managers.ViewModeManager"] = {
			Modes = {
				Empty = "ViewModes.EmptyViewMode",
				Power = "ViewModes.PowerViewMode",
				Food = "ViewModes.FoodViewMode",
				Drink = "ViewModes.DrinkViewMode",
				Fun = "ViewModes.FunViewMode",
				Shopping = "ViewModes.ShoppingViewMode",
				Toilet = "ViewModes.ToiletViewMode",
				Shelter = "ViewModes.ShelterViewMode",
				Weather = "ViewModes.WeatherViewMode",
				Visibility = "ViewModes.VisibilityViewMode",
				Transport = "ViewModes.TransportViewMode",
				Finances = "ViewModes.FinancesViewMode"
			},
			InitialMode = "Empty"
		},
		["Managers.InputDispatchManager"] = {
			Events = {"Confirm", "AltConfirm", "Cancel", "Undo", "Redo", "DeleteMode", "ReplaceMode", "SnapToggle", "RotateGate", "RandomRotationToggle"},
			Handlers = {"EditMode", "UIMode", "MainHUD"}
		}
	}
}

-- Merge default Managers with ACSE collected protos
if GameDatabase.GetParkEnvironmentManagers then
	for _sName, _tParams in pairs( GameDatabase.GetParkEnvironmentManagers() ) do
		global.api.debug.Trace("acse Adding Manager: " .. _sName)
		Module.EnvironmentPrototype['Managers'][_sName] = _tParams
	end
end

-- confirm the environment comply its proto
(Mutators.VerifyEnvironmentPrototypeModule)(Module)

