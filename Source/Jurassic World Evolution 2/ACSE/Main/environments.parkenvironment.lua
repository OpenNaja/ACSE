-----------------------------------------------------------------------
--/  @file   Environments.ParkEnvironment.lua
--/  @author My Self
--/
--/  @brief  Park Environments definition for Jurassic World Evolution 2
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

api.debug.Trace("Custom Park Environment loaded")

-- Default Park Environment defintion from JWE 1.8
Module.EnvironmentPrototype = {
	SearchPaths = {"Managers"},
	Managers = {
		["Managers.BreadcrumbTrailManager"] = {},
		["Managers.CameraShakeManager"] = {},
		["Managers.CareerProgressManager"] = {},
		["Managers.CinematicsManager"] = {},
		["Managers.CommsManager"] = {},
		["Managers.DigSiteManager"] = {},
		["Managers.DinosaurLoanManager"] = {},
		["Managers.DinosaurSpawnManager"] = {},
		["Managers.DinosaurTerrorLevelManager"] = {},
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
		["Managers.InGenDatabaseUIManager"] = {},
		["Managers.InjuryManager"] = {},
		["Managers.IslandIntroManager"] = {},
		["Managers.IslandProgressManager"] = {},
		["Managers.IslandSwitchManager"] = {},
		["Managers.LocalBuildingStatusManager"] = {},
		["Managers.PhotoRewardManager"] = {},
		["Managers.ManagementModeEnabledManager"] = {},
		["Managers.ManagementNewFlagManager"] = {},
		["Managers.MapOverlayManager"] = {},
		["Managers.MissionManager"] = {},
		["Managers.MissionUIManager"] = {},
		["Managers.MonthlyReportManager"] = {},
		["Managers.NarrativeEventsManager"] = {},
		["Managers.NotificationManager"] = {},
		["Managers.ObtainedSpeciesManager"] = {},
		["Managers.ParkSystemsDisableManager"] = {},
		["Managers.PlantListDatastoreManager"] = {},
		["Managers.RecordsManager"] = {},
		["Managers.RewardUnlockManager"] = {},
		["Managers.SabotageManager"] = {},
		["Managers.SandboxSettingsManager"] = {},
		["Managers.ScenarioManager"] = {},
		["Managers.SimulationSpeedManager"] = {},
		["Managers.StormManager"] = {},
		["Managers.TabPersistenceManager"] = {},
		["Managers.TechTreeManager"] = {},
		["Managers.TelemetryMessageManager"] = {},
		["Managers.TutorialUIManager"] = {},
		["Managers.DinosaurSimulationDataManager"] = {},
		["Managers.VehicleSkinUnlockManager"] = {},
		["Managers.VOManager"] = {},
		["Managers.WildPterosaurManager"] = {},
		["Managers.UILockManager"] = {},
		["Managers.UIModeManager"] = {
			Modes = {
				Empty = "Editors.Shared.EmptyUIMode",
				Select = "Editors.Select.SelectUIMode",
				Terrain = "Editors.Terrain.TerrainEditUIMode",
				Building = "Editors.Building.BuildingUIMode",
				Delete = "Editors.Delete.DeleteUIMode",
				Repair = "Editors.Repair.RepairUIMode",
				Management = "Editors.Management.ManagementUIMode",
				DinoTeleportTest = "Editors.Test.DinoTeleportTestUIMode",
				DinoTest = "Editors.Test.DinoTestUIMode",
				DriveVehicle = "Editors.Vehicle.DriveVehicleUIMode",
				DroneAITest = "Editors.Test.DroneAITestUIMode",
				VehicleGunner = "Editors.Vehicle.VehicleGunnerUIMode",
				VehiclePhoto = "Editors.Vehicle.VehiclePhotoUIMode",
				VehicleAITest = "Editors.Test.VehicleAITestUIMode",
				InspectDinosaur = "Editors.Dinosaur.InspectDinosaurUIMode",
				DinosaurBirth = "Editors.Dinosaur.DinosaurBirthUIMode",
				TransportSelectDinosaur = "Editors.Dinosaur.TransportSelectDinosaurUIMode",
				SelectDinosaurDestination = "Editors.Dinosaur.SelectDinosaurDestinationUIMode",
				SelectPinnedDinosaur = "Editors.Dinosaur.SelectPinnedDinosaurUIMode",
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
				IslandEntityPlace = "Editors.Test.IslandEntityPlaceUIMode",
				TerritoryTest = "Editors.Test.TerritoryTestUIMode",
				StaffManagement = "Editors.StaffManagement.StaffManagementUIMode",
				AssignStaffToTask = "Editors.Tasks.AssignStaffToTaskUIMode",
				BuildingWithCustomisableGameplay = "Editors.InspectBuilding.BuildingWithCustomisableGameplayUIMode",
				ResourcesResupply = "Editors.ResourcesResupply.ResourcesResupplyUIMode"},
			InitialMode = "Select"
		},
		["Managers.EditModeManager"] = {
			Modes = {
				Empty = "Editors.Shared.EmptyEditMode",
				Select = "Editors.Select.SelectMode",
				Terrain = "Editors.Terrain.TerrainEditMode",
				Building = "Editors.Building.BuildingMode",
				Delete = "Editors.Delete.DeleteMode",
				Repair = "Editors.Repair.RepairMode",
				DinoTeleportTest = "Editors.Test.DinoTeleportTestMode",
				DinoTest = "Editors.Test.DinoTestMode",
				DroneAITest = "Editors.Test.DroneAITestMode",
				VehicleAITest = "Editors.Test.VehicleAITestMode",
				InspectBuilding = "Editors.InspectBuilding.InspectBuildingMode",
				InspectCustomisableBuilding = "Editors.InspectBuilding.InspectCustomisableBuildingMode",
				TornadoTest = "Editors.Test.TornadoTestMode",
				Map = "Editors.Map.MapMode",
				AudioTest = "Editors.Test.AudioTestMode",
				Capture = "Editors.Capture.CaptureMode",
				IslandEntityPlace = "Editors.Test.IslandEntityPlaceMode",
				TerritoryTest = "Editors.Test.TerritoryTestMode",
				FixFoundationHeights = "Editors.Test.FixFoundationHeightsMode"},
			InitialMode = "Select"
		},
		["Managers.ViewModeManager"] = {
			Modes = {
				Shelter = "ViewModes.ShelterViewMode",
				Toilet = "ViewModes.ToiletViewMode",
				Transport = "ViewModes.TransportViewMode",
				GuestDistribution = "ViewModes.GuestDistributionViewMode",
				Amenity = "ViewModes.AmenityViewMode",
				Overcrowding = "ViewModes.OvercrowdingViewMode",
				Finances = "ViewModes.FinancesViewMode",
				Appeal = "ViewModes.AppealViewMode",
				Visibility = "ViewModes.VisibilityViewMode",
				RangerPatrol = "ViewModes.RangerPatrolViewMode",
				Power = "ViewModes.PowerViewMode",
				Weather = "ViewModes.WeatherViewMode",
				Empty = "ViewModes.EmptyViewMode"},
			InitialMode = "Empty"
		},
		["Managers.InputDispatchManager"] = {
			Events = {
				"Confirm",
				"AltConfirm",
				"Cancel",
				"Undo",
				"Redo",
				"DeleteMode",
				"ReplaceMode",
				"SnapToggle",
				"RandomRotationToggle",
				"RotationAxisToggle",
				"DeleteBrushMode",
				"DeleteBrushWidth",
				"DeleteTypeSelectable"
			},
			Handlers = {
				"EditMode",
				"UIMode",
				"MainHUD"
			}
		}
	}
}

-- Merge default Managers with ACSE collected protos
if GameDatabase.GetParkEnvironmentManagers then
	for _sName, _tParams in pairs( GameDatabase.GetParkEnvironmentManagers() ) do
		api.debug.Trace("acse Adding Manager: " .. _sName)
		Module.EnvironmentPrototype['Managers'][_sName] = _tParams
	end
end

-- confirm the environment comply its proto
(Mutators.VerifyEnvironmentPrototypeModule)(Module)

