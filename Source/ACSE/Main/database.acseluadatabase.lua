-----------------------------------------------------------------------
--/  @file   Database.ACSELuaDatabase.lua
--/  @author Inaki
--/
--/  @brief  Creates the database prototypes for modules to hook into the
--/          game environment or alter the current ones. It also registers
--/          the basic shell commands for the functionality it provides.
--/          Registers ACSE as a Lua Game Database with an interface to 
--/          interact with it by other mods.
--/
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global          = _G
local api             = global.api
local tostring        = global.tostring
local pairs           = pairs
local type            = type
local ipairs          = ipairs
local next            = global.next
local string          = global.string
local require         = global.require
local table           = require("Common.tableplus")
local StringUtils     = require("Common.stringUtils")
local Main            = require("Database.Main")

local GameDatabase    = require("Database.GameDatabase")

local ACSELuaDatabase = module(...)

-- Insert ourselves in the Database loading process
ACSELuaDatabase.AddContentToCall = function(_tContentToCall)
    table.insert(_tContentToCall, ACSELuaDatabase)
end

-- List of lua Components to populate from other mods
api.acse.tLuaComponents = {}

-- List of lua Prefabs to populate from other mods
api.acse.tLuaPrefabs = {}
api.acse.tLuaPrefabNames= {}

api.acse.GetLuaPrefab = function(_sName)
    if api.acse.tLuaPrefabNames[_sName] == nil then
        return nil
    end
    return  api.acse.tLuaPrefabs[ api.acse.tLuaPrefabNames[_sName] ].PrefabData
end

-- List of hooks for runtime-patching
api.acse.tLuaHooks = {}

-- List of protos/managers to populate from other mods
api.acse.tEnvironmentProtos = {}


-- Definition of our own database methods
ACSELuaDatabase.tDatabaseMethods = {
    --/ version info
    GetACSEVersionNumer = function()
        return api.acse.versionNumber
    end,
    GetACSEVersionString = function()
        return api.acse.GetVersionString()
    end,
    AppendToGameVersionString = function(_sText, _sDelim)
        if _sDelim == nil then _sDelim = "\n" end
        table.insert(api.acse.tAppendToVersionString, {text = _sText, sep = _sDelim})
    end,    
    --/ Lua Components
    GetLuaComponents = function()
        return api.acse.tLuaComponents
    end,
    --/ Lua prefabs
    --/ Todo: save compiled prefab token as the value into the prefabNames table instead of a true
    GetLuaPrefabs = function()
        return api.acse.tLuaPrefabs
    end,
    GetLuaPrefabNames = function()
        return api.acse.tLuaPrefabNames
    end,
    --/ Lua prefabs
    GetLuaPrefab = function(_sName)
        if api.acse.tLuaPrefabNames[_sName] ~= nil then
            global.api.debug.Warning("ACSE trying to access a missing prefab: " .. global.tostring(_sName))
            return nil
        end
        return api.acse.tLuaPrefabs[ api.acse.tLuaPrefabNames[_sName] ].PrefabData
    end,
    --/ Lua prefabs
    BuildLuaPrefabs = function()
        --api.debug.Trace("Prefabs = " .. table.tostring(api.acse.tLuaPrefabs, nil, nil, nil, true))
        local nStartTime = global.api.time.GetPerformanceTimer()
        for _, tData in global.ipairs(api.acse.tLuaPrefabs) do
            -- api.debug.Trace("Compiling: " .. tData.PrefabName)
            local cPrefab = api.entity.CompilePrefab(tData.PrefabData, tData.PrefabName)
        end
        local nNewTime = global.api.time.GetPerformanceTimer()
        local nDiff = global.api.time.DiffPerformanceTimers(nNewTime, nStartTime)
        local nDiffMs = global.api.time.PerformanceTimeToMilliseconds(nDiff)
        global.api.debug.Trace(string.format("Compiling %d Lua prefabs took %.3f seconds.", table.count(api.acse.tLuaPrefabs), (nDiffMs / 1000)))
    end,
    BuildLuaPrefab = function(_sName)
        for _, tData in global.ipairs(api.acse.tLuaPrefabs) do
            if tData.PrefabName == _sName then
                local cPrefab = global.api.entity.CompilePrefab(tData.PrefabData, tData.PrefabName)
                return
            end
        end
        global.api.debug.Trace("ACSE trying to build a missing prefab: " .. _sName)
    end,
    AddLuaPrefab = function(_sName, _tParams)
        -- api.debug.Trace("Add Lua Prefab " .. global.tostring(_sName))
        if type(_sName) == "string" and type(_tParams) == "table" then
            --api.debug.Assert(api.acse.tLuaPrefabNames[_sName] == nil, "Duplicated Lua Prefab " .. _sName)
            if api.acse.tLuaPrefabNames[_sName] == nil then
                -- Add new prefab
                table.append(api.acse.tLuaPrefabs, {PrefabName = _sName, PrefabData = _tParams})
                api.acse.tLuaPrefabNames[_sName] = table.count(api.acse.tLuaPrefabs)
            else
                -- Override existing prefab
                local index = api.acse.tLuaPrefabNames[_sName]
                api.acse.tLuaPrefabs[index] = {PrefabName = _sName, PrefabData = _tParams}
            end
        end
    end,
    GetLatestPrefab = function(_sName)
        if _sName and api.acse.tLuaPrefabNames[_sName] then
            GameDatabase.BuildLuaPrefab(_sName)
        end
        return api.entity.FindPrefab(_sName)
    end,
    --/ Lua hooks
    GetLuaHooks = function()
        return api.acse.tLuaHooks
    end,
    --/ global environment hook
    GetEnvironmentProtos = function()
        return api.acse.tEnvironmentProtos
    end,
    --/ Allow late second mods to update prefabs before they are built
    RunPreBuildPrefabs = function()
        Main.CallOnContent(
            "PreBuildPrefabs",
            function(_sName, _tParams)
                -- api.debug.Trace("Add Lua Prefab " .. global.tostring(_sName))
                if type(_sName) == "string" and type(_tParams) == "table" then
                    --api.debug.Assert(api.acse.tLuaPrefabNames[_sName] == nil, "Duplicated Lua Prefab " .. _sName)
                    if api.acse.tLuaPrefabNames[_sName] == nil then
                        -- Add new prefab
                        table.append(api.acse.tLuaPrefabs, {PrefabName = _sName, PrefabData = _tParams})
                        api.acse.tLuaPrefabNames[_sName] = table.count(api.acse.tLuaPrefabs)
                    else
                        -- Override existing prefab
                        local index = api.acse.tLuaPrefabNames[_sName]
                        api.acse.tLuaPrefabs[index] = {PrefabName = _sName, PrefabData = _tParams}
                    end
                end
            end,
            api.acse.tLuaPrefabNames,
            api.acse.tLuaPrefabs
        )        
    end
}

-- @brief adds our custom database methods to the main game database
ACSELuaDatabase.AddDatabaseFunctions = function(_tDatabaseFunctions)
    for sName, fnFunction in pairs(ACSELuaDatabase.tDatabaseMethods) do
        _tDatabaseFunctions[sName] = fnFunction
    end
end

-- @brief Database init
ACSELuaDatabase.Init = function()
    api.debug.Trace("ACSELuaDatabase:Init()")
    api.debug.Trace("ACSE Bootstrap started")

    -- Register our own custom shell commands
    api.debug.Trace("registering custom commands")

    ACSELuaDatabase.tShellCommands = {
    }

    Main.CallOnContent(
        "AddLuaCommands",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                local oShellCommand = api.debug.RegisterShellCommand(_tParams[1], _sName, _tParams[2] )
                table.insert(ACSELuaDatabase.tShellCommands, oShellCommand)
            end
        end
    )

    --/ Request Lua Components from other mods
    api.debug.Trace("requesting additional components")
    Main.CallOnContent(
        "AddLuaComponents",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "string" then
                --api.debug.Trace("Adding component: " .. _sName)
                --api.debug.Assert(api.acse.tLuaComponents[_sName] == nil, "Ingoring duplicated Lua Component " .. _sName)
                api.acse.tLuaComponents[_sName] = _tParams
            end
        end
    )

    --/ Request Park Managers from other mods. The new format is using the
    --/ environment name to override and prototype table to merge
    api.debug.Trace("requesting function hooks")
    Main.CallOnContent(
        "AddLuaHooks",
        function(_sName, _tParams)
            if type(_sName) == "string" and (type(_tParams) == "table" or type(_tParams) == 'function') then
                table.insert(
                    api.acse.tLuaHooks, 
                    {   
                        sName = _sName,
                        tData = _tParams
                    }
                )
            end
        end
    )

    --/ Request Park Managers from other mods. The new format is using the
    --/ environment name to override and prototype table to merge, and we will
    --/ use a custom hook for each one them
    api.debug.Trace("requesting managers information")
    Main.CallOnContent(
        "AddManagers",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                api.debug.Warning("Managers: " .. table.tostring(_tParams) .. " are being added using AddManagers (obsolete API). Use AddLuaManagers instead.")
                table.insert(
                    api.acse.tEnvironmentProtos, 
                    {   
                        sName = _sName,
                        tData = _tParams
                    }
                )
            end
        end
    )
    Main.CallOnContent(
        "AddLuaManagers",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                table.insert(
                    api.acse.tEnvironmentProtos, 
                    {   
                        sName = _sName,
                        tData = _tParams
                    }
                )
            end
        end
    )

    --/ Request Starting Screen Managers from other mods
    Main.CallOnContent(
        "AddStartScreenManagers",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                api.debug.Warning("Manager: " .. _sName .. " is being added using AddStartScreenManagers (obsolete API). Use AddLuaManagers.")
                local tItem = {
                    sName = "Environments.StartScreenEnvironment",
                    tData = {
                        [_sName] = _tParams
                    },
                }
                table.insert(api.acse.tEnvironmentProtos, tItem)
            end
        end
    )

    --/ Request Park Managers from other mods
    Main.CallOnContent(
        "AddParkManagers",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                api.debug.Warning("Manager: " .. _sName .. " is being added using AddParkManagers (obsolete API). Use AddLuaManagers")

                -- Provide support for old method of adding Park managers
                local sParkEnvironment = "Environments.ParkEnvironment"
                if api.game.GetGameName() == "Planet Zoo" then
                    sParkEnvironment = "Environments.DarwinEnvironment"
                end

                local tItem = {
                    sName = sParkEnvironment,
                    tData = {
                        [_sName] = _tParams
                    },
                }
                table.insert(api.acse.tEnvironmentProtos, tItem)
            end
        end
    )
    --/ Create hooks to handle the Manager injection
    ACSELuaDatabase._CreateHooksForManagers()

    --/ Request Lua Prefabs from other mods
    local nStartTime = global.api.time.GetPerformanceTimer()
    api.debug.Trace("requesting additional prefabs")
    Main.CallOnContent(
        "AddLuaPrefabs",
        function(_sName, _tParams)
            -- api.debug.Trace("Add Lua Prefab " .. global.tostring(_sName))
            if type(_sName) == "string" and type(_tParams) == "table" then
                --api.debug.Assert(api.acse.tLuaPrefabNames[_sName] == nil, "Duplicated Lua Prefab " .. _sName)
                if api.acse.tLuaPrefabNames[_sName] == nil then
                    -- Add new prefab
                    table.append(api.acse.tLuaPrefabs, {PrefabName = _sName, PrefabData = _tParams})
                    api.acse.tLuaPrefabNames[_sName] = table.count(api.acse.tLuaPrefabs)
                else
                    -- Override existing prefab
                    local index = api.acse.tLuaPrefabNames[_sName]
                    api.acse.tLuaPrefabs[index] = {PrefabName = _sName, PrefabData = _tParams}
                end
            end
        end
    )
    local nNewTime = global.api.time.GetPerformanceTimer()
    local nDiff = global.api.time.DiffPerformanceTimers(nNewTime, nStartTime)
    local nDiffMs = global.api.time.PerformanceTimeToMilliseconds(nDiff)
    api.debug.Trace(string.format("Loaded %d Lua prefabs in %.3f seconds", table.count(api.acse.tLuaPrefabNames), (nDiffMs / 1000)))

    api.debug.Trace("Finished collecting other mods bootstrap")
end

ACSELuaDatabase.Setup = function()
    api.debug.Trace("ACSELuaDatabase.Setup()")
end


-- @brief Environment Shutdown
ACSELuaDatabase.Shutdown = function()
    global.api.debug.Trace("ACSELuaDatabase:Shutdown()")

    -- Remove custom commands
    for i, oCommand in ipairs(ACSELuaDatabase.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end
    ACSELuaDatabase.tShellCommands = nil

    -- Time call TableChecker Shutdown?
end

-- @brief Called when a Reinit is about to happen
ACSELuaDatabase.ShutdownForReInit = function()
end


-- @brief Hook the control options menu for JWE2
ACSELuaDatabase._Hook_ControlsOptionsMenu = function(tModule)
    tModule._ACSELuaDatabase_GetItems     = tModule.GetItems
    tModule._ACSELuaDatabase_HandleEvent  = tModule.HandleEvent
    tModule._ACSELuaDatabase_ApplyChanges = tModule.ApplyChanges
    tModule.GetItems = function(self, _tSettingsMenuItemsData)
        self:_ACSELuaDatabase_GetItems(_tSettingsMenuItemsData)
        for _, handler in global.ipairs(global.api.acse._tControlsSettingsRegistrations) do
            if handler.fGetItems then
                handler.fGetItems(_tSettingsMenuItemsData['items'])
            end
        end
    end
    tModule.HandleEvent = function(self, _sID, _arg)
            api.debug.Trace("KeyboardSettings:HandleEvent()")
            local bHandled, bNeedsRefresh = self:_ACSELuaDatabase_HandleEvent(_sID, _arg)

            local fRebind = function(sControlName) 
                if api.game.GetGameName() == "Planet Zoo" then
                    self:RebindButtonFlow(sControlName)
                    local tNewItems = {}
                    self:GetItems(tNewItems)
                    self.guiWrapper:SetSettingsMenuContentData(tNewItems)
                else -- JWE1/2
                    tData = {
                        ["type"] = 1,
                        ["control"] = sControlName,
                        ["label"] = "",
                        ["targets"] = {
                            [1] = 0
                        }
                    }
                    self:HandleRebind(tData)
                end
            end

            local fUnbind = function(sControlName)
                api.input.RemoveLogicalButtonRebind(sControlName)
                if api.game.GetGameName() == "Planet Zoo" then
                    -- Need to enforce a refresh
                    local tNewItems = {}
                    self:GetItems(tNewItems)
                    self.guiWrapper:SetSettingsMenuContentData(tNewItems)
                end
            end

            for _, handler in ipairs(global.api.acse._tControlsSettingsRegistrations) do
                if handler.fHandleEvent then
                    bHandled, bNeedsRefresh = handler.fHandleEvent(_sID, _arg, bHandled, bNeedsRefresh, fRebind, fUnbind)
                end
            end
            return bHandled, bNeedsRefresh
        end
    tModule.ApplyChanges = function(self)
        local ret = self:_ACSELuaDatabase_ApplyChanges()
        for _, handler in global.ipairs(global.api.acse._tControlsSettingsRegistrations) do
            if handler.fApplyChanges then
                ret = handler.fApplyChanges()
            end
        end
        return ret
    end
end

-- List of custom hooks on other Lua modules
ACSELuaDatabase.tDefaultHooks = {
    ['Windows.KeyboardOptionsMenu'] = ACSELuaDatabase._Hook_ControlsOptionsMenu, -- JWE2
    ['Windows.ControlsOptionsMenu'] = ACSELuaDatabase._Hook_ControlsOptionsMenu, -- PZ
}

-- @brief Add our custom hooks to different Lua files
ACSELuaDatabase.AddLuaHooks = function(_fnAdd)
    local tData = ACSELuaDatabase.tDefaultHooks
    for sModuleName, tParams in pairs(tData) do
        _fnAdd(sModuleName, tParams)
    end
end

-- Code to convert Manager injections into custom hooks
ACSELuaDatabase._merge = function(a, b, bModifyOnly)
    if global.type(a) == "table" and global.type(b) == "table" then
      for k, v in global.pairs(b) do
        if global.type(v) == "table" and global.type(a[k] or false) == "table" then
          ACSELuaDatabase._merge(a[k], v, bModifyOnly)
        else
          if not bModifyOnly or bModifyOnly == false or (bModifyOnly == true and a[k] ~= nil) then
            a[k] = v
          end
        end
      end
    end
    return a
end

-- @brief will create a hook for every Environment file that requires custom data injection.
ACSELuaDatabase._CreateHooksForManagers = function()
    for _, tParams in global.ipairs(api.acse.tEnvironmentProtos) do
      table.insert(
        api.acse.tLuaHooks, 
          {   
            sName = tParams.sName,
            tData = function(tModule)
              local sEnvironment = tParams.sName
              for _sName, _tParams in global.pairs(tParams.tData) do
                if not _tParams.__inheritance or _tParams.__inheritance == "Overwrite" then
                  api.debug.Trace("Adding Manager: " .. _sName .. " in " .. sEnvironment)
                  tModule.EnvironmentPrototype["Managers"][_sName] = _tParams
                end
                if _tParams.__inheritance == "Append" then
                  api.debug.Trace("Merging Manager: " .. _sName .. " in " .. sEnvironment)
                  tModule.EnvironmentPrototype["Managers"][_sName] = ACSELuaDatabase._merge(tModule.EnvironmentPrototype["Managers"][_sName], _tParams)
                end
                if _tParams.__inheritance == "Modify" then
                  api.debug.Trace("Modifying Manager: " .. _sName .. " in " .. sEnvironment)
                  tModule.EnvironmentPrototype["Managers"][_sName] = ACSELuaDatabase._merge(tModule.EnvironmentPrototype["Managers"][_sName], _tParams, true)
                end
              end
            end
          }
        )
    end
end

