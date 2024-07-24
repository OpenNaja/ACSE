-----------------------------------------------------------------------
--/  @file   Database.ACSEDebugLuaDatabase.lua
--/  @author My Self
--/
--/  @brief  Handles ACSEDebug loading and database creation
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------

local global       = _G
local api          = global.api
local pairs        = global.pairs
local type         = global.type
local ipairs       = global.ipairs
local next         = global.next
local string       = global.string
local require      = global.require
local unpack       = global.unpack
local table        = require("Common.tableplus")
local StringUtils  = require("Common.stringUtils")
local GameDatabase = require("Database.GameDatabase")

local ACSEDebugLuaDatabase = module(...)

-- @brief ACSE dev file system used by loadfile, loadmodule, importmodule functions
api.acse.devpath = "Dev/Lua/"
api.acse.devmodule = global.loadfile("Dev/Lua/init.lua")

-- @brief add our custom databases
ACSEDebugLuaDatabase.AddContentToCall = function(_tContentToCall)
    -- Add ourself module to the game database list.

    -- Verify the game environment complies with the requirements before adding our gameplay items.
    if not api.acse or api.acse.versionNumber < 0.709 then
        local errormsg = [[
            local global  = _G local ACSEDebugErrorMessage = module(...) ACSEDebugErrorMessage.AddUpdateFanfareData = function(_fnAdd)
            local tUpdateData = {
                sFanfareName = "wrong_acse_version_" .. global.tostring( global.api.time.CurrentLocalDateAndTimeString() ),
                tSlideItems = {
                    {
                        sTitleText = "[STRING_LITERAL:Value='WRONG ACSE VERSION']",
                        sDescriptionText = "[STRING_LITERAL:Value='ACSEDEBUG REQUIRES ACSE 0.709 OR GREATER. THIS MOD WILL BE DISABLED']",
                        sImageName = "popupiconfearlarge", -- we can find a better string
                    },
                }
            }
            _fnAdd(tUpdateData) end return ACSEDebugErrorMessage
        ]]
        local pf, sMsg = global.loadstring(errormsg)
        local bRes, ErrorModule = global.pcall(pf, "ACSEDebugErrorMessage")        
        table.insert(_tContentToCall, ErrorModule)
        return
    end

    table.insert(_tContentToCall, ACSEDebugLuaDatabase)

    if api.acse.devmodule ~= nil then 
        global.package.preload['acsedev'] = api.acse.devmodule
        local devmod = require('acsedev')
        global.package.preload['acsedev'] = nil
        if devmod then table.insert(_tContentToCall, devmod ) end 
    end
end

-- @brief Database init
ACSEDebugLuaDatabase.Init = function()
    api.debug.Trace("ACSEDebugLuaDatabase:Init()")

    -- Register our own custom shell commands
    ACSEDebugLuaDatabase.tShellCommands = {
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if global.type(tArgs) == "table" and table.count(tArgs) > 0 and global.type(tArgs[1]) == "string" then
                    cmdname = global.string.lower(tArgs[1])
                    oCmd = api.acsedebug.shellcommands.tShellCommands[cmdname]
                    if global.type(oCmd) == "table" then
                        global.api.debug.WriteLine(tEnv.output, global.tostring(oCmd._sCmd) .. "\n" .. global.tostring(oCmd._sDesc))
                    else
                        return false, "Command " .. global.tostring(tArgs[1]) .. " not found."
                    end
                else
                    global.api.debug.WriteLine(tEnv.output, "List of Commands:")
                    for k, v in global.pairs(api.acsedebug.shellcommands.tShellCommands) do
                        if (tArgs[1] == nil or global.string.match(string.lower(k), string.lower(tArgs[1]))) then
                            api.debug.WriteLine(tEnv.output, global.tostring(v._sCmd))
                        end
                    end
                    return true, nil
                end
            end,
            "&Help [{string}]",
            "List all commands or displays information about a command.\n"
        ),        
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 2 then
                    return false, "SetTweakable requires two arguments"
                end

                local sTweakableNamePattern = string.lower(tArgs[1])
                local tLoadedTweakableNames = api.acse.tweakables.tTweakables

                local tFilteredLoadedModuleNames = {}
                _pattern = string.gsub(sTweakableNamePattern, "%%", "")
                for k, v in global.pairs(tLoadedTweakableNames) do
                    if StringUtils.StrMatchI(k, _pattern) then
                        tFilteredLoadedModuleNames[table.count(tFilteredLoadedModuleNames) + 1] = k
                    end
                end

                local nFoundModulesCount = table.count(tFilteredLoadedModuleNames)
                if nFoundModulesCount < 1 then
                    return false, 'Couldn\'t find a Tweakable matching the pattern "' .. sTweakableNamePattern .. '".'
                end

                -- Locating named modules
                for i, sModuleName in global.ipairs(tFilteredLoadedModuleNames) do
                    if sTweakableNamePattern == string.lower(sModuleName) then
                        tFilteredLoadedModuleNames = {sModuleName}
                    end
                end
                nFoundModulesCount = table.count(tFilteredLoadedModuleNames)

                if nFoundModulesCount > 1 then
                    local allModulesList = table.concat(tFilteredLoadedModuleNames, "\n")
                    return false, "Found " ..
                        global.tostring(nFoundModulesCount) ..
                            ' existing Tweakables matching the pattern "' ..
                                sTweakableNamePattern ..
                                    '". You need to be more specific. \nPossible Tweakables:\n' .. allModulesList
                end

                local sTweakableName = tFilteredLoadedModuleNames[1]

                tweakable = api.debug.GetDebugTweakable(sTweakableName)
                if tweakable.type == 22 then -- boolean
                    local stringtoboolean = {["true"] = true, ["false"] = false}
                    tArgs[2] = stringtoboolean[global.string.lower(tArgs[2])]
                else -- numbers
                    tArgs[2] = global.tonumber(tArgs[2])
                end
                tweakable:SetValue(tArgs[2])
                return true, "Tweakable " .. sTweakableName .. " set to: " .. global.tostring(tArgs[2]) .. ".\n"
            end,
            "&Set&Tweakable {string} {value}",
            "Changes the value of a tweakable.\n"
        ),

        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                api.debug.Trace("List of Tweakables:")
                for k, v in global.pairs(api.acse.tweakables.tTweakables) do
                    if (tArgs[1] == nil or global.string.match(string.lower(k), string.lower(tArgs[1]))) then
                        api.debug.WriteLine(tEnv.output, global.tostring(v.id) .. " = " .. global.tostring(v.value))
                    end
                end
            end,
            "&List&Tweakables [{string}]",
            "Prints a list of the current tweakables and its values. Specify a filter string to limit the list.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs < 1 then
                    return false, "Loadfile requires at least one argument, the name of the lua file (without the .lua extension). Other arguments will be passed to the script\n"
                end

                local sModuleName = global.tostring(tArgs[1])
                global.api.debug.WriteLine(tEnv.output, "Loading file: " .. sModuleName)
                local pf, sMsg = global.loadfile("Dev/Lua/" .. sModuleName .. ".lua")
                if pf == nil and string.find(sMsg, "No such file or directory") then
                    local sName = global.string.gsub(sModuleName, "%.", "/")
                    pf, sMsg = global.loadfile("Dev/Lua/" .. sName .. ".lua")
                end
                if pf ~= nil and global.type(pf) == "function" then
                    local bOk, sMsg = global.pcall(pf, unpack(tArgs))
                    if bOk == false then
                        return false, global.tostring(sMsg) .. "\n"
                    end
                else
                    return false, "Lua file not loaded: " .. global.tostring(sMsg) .. "\n"
                end
            end,
            "&Load&File {string}",
            "Loads and execute a Lua file from the game root folder, do not add path.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
              if tArgs and tArgs[2] then
                return false, "Unexpected number of arguments.\n"
              end

              -- List worlds if missing args
              if not tArgs or not tArgs[1] then
                local sResponse = "Available Worlds:"
                for _,sWorldName in global.ipairs( global.api.world.GetValidWorldNames("") ) do
                  sResponse = sResponse .. "\n" .. sWorldName
                end
                return false, sResponse
              end

              local sQuery = tArgs[1]
              local sQueryLower = sQuery:lower()
              local tMatchingNames = global.api.world.GetValidWorldNames(sQueryLower)
              if #tMatchingNames == 0 then
                return false, "\'" .. sQuery .. "\' is not a valid world name, and no match found.\n"
              end

              local sFoundName = nil
              if #tMatchingNames > 0 then
                local sResponse = "Multiple matches for query found:"
                for _,sWorldName in global.ipairs(tMatchingNames) do
                  if sQueryLower == sWorldName:lower() then
                    sFoundName = sWorldName
                    break
                  end
                  sResponse = sResponse .. "\n" .. sWorldName
                end

                if not sFoundName then
                    return false, sResponse .. "\n"
                end
                if not sFoundName then
                    sFoundName = tMatchingNames[1]
                end
                local sResponse = "Matched world name \'" .. sFoundName .. "\'."
                if sFoundName:lower() == sQueryLower then
                  sResponse = "Loading level " .. sFoundName .. "."
                end
                global.api.game.RequestTransition(sFoundName)
                return true, sResponse .. "\n"
              end
            end,
            "&Load&Level [{level}]", "Load the given level.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
              local sWorldName = api.world.GetCurrent()
              local sResponse = "Reloading level " .. sWorldName .. ".\n"
              global.api.game.RequestTransition(sWorldName)
              return true, sResponse
            end,
            "&Reload&Level", "Reload the current level.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
              global.api.game.RequestReturnToStart()
              return true, "Returning to front end.\n"
            end,
            "&Quit&Level", "Exit the current game world.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                global.api.game.Quit(tArgs[1] or false)
            end,
            "&Quit [{bool}]",
            "Quits the game. To force Quitting without prompting use true as argument.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                global.api.game.Quit(true)
            end,
            "QQ",
            "Force quits the game.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if tArgs == nil or #tArgs ~= 1 or global.type(tArgs[1]) ~= "string" then
                    return false, "Expected exactly one string argument, the module name (or a search string).\n"
                end

                local sModuleNamePattern = string.lower(tArgs[1])

                -- get module list from package.loaded that contain the pattern in the name
                local tLoadedModuleNames = global.api.debug.GetListOfLoadedModuleNames()

                local tFilteredLoadedModuleNames = {}
                _pattern = string.gsub(sModuleNamePattern, "%%", "")
                for k, v in global.pairs(tLoadedModuleNames) do
                    if StringUtils.StrMatchI(v, _pattern) then
                        tFilteredLoadedModuleNames[#tFilteredLoadedModuleNames + 1] = v
                    end
                end

                local nFoundModulesCount = #tFilteredLoadedModuleNames
                if nFoundModulesCount < 1 then
                    return false, 'Couldn\'t find a loaded module matching the pattern "' .. sModuleNamePattern .. '".'
                end

                -- Locating named modules
                for i, sModuleName in ipairs(tFilteredLoadedModuleNames) do
                    if sModuleNamePattern == string.lower(sModuleName) then
                        tFilteredLoadedModuleNames = {sModuleName}
                    end
                end
                nFoundModulesCount = #tFilteredLoadedModuleNames

                if nFoundModulesCount > 1 then
                    local allModulesList = table.concat(tFilteredLoadedModuleNames, "\n")
                    return false, "Found " ..
                        global.tostring(nFoundModulesCount) ..
                            ' loaded modules matching the pattern "' .. sModuleNamePattern ..
                            '". You need to be more specific. \nPossible modules:\n' .. allModulesList
                end

                local sModuleName = tFilteredLoadedModuleNames[1]

                -- load the new file and replace the Lua package system
                local pf, sMsg = global.loadfile("Dev/Lua/" .. sModuleName .. ".lua")
                if pf == nil and string.find(sMsg, "No such file or directory") then
                    local sName = global.string.gsub(sModuleName, "%.", "/")
                    pf, sMsg = global.loadfile("Dev/Lua/" .. sName .. ".lua")
                end
                if pf then
                    global.package.preload[sModuleName] = pf
                    local a = global.require(sModuleName)
                    global.package.loaded[sModuleName] = a

                    local fnMod, sErrorMessage = global.loadresource(sModuleName)
                    if not fnMod then
                        return false, "Resource not found: " .. sErrorMessage
                    end

                    local module = global.tryrequire(sModuleName)
                    if module ~= nil then
                        module.s_tInterfaces = nil
                    end

                    local bOk = nil
                    bOk, sMsg = global.pcall(fnMod, sModuleName)

                    if not bOk then
                        return false, "Error reloading module: " .. global.tostring(sMsg)
                    end
                else
                    return false, "File " .. sModuleName .. ".lua not found or wrong syntax.\n" .. global.tostring(sMsg)
                end
                global.api.debug.WriteLine(tEnv.output, "Module '" .. sModuleName .. "' reloaded successfully.")
            end,
            "&Load&Module {string}",
            "Reloads the Lua module specified from the file system.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if tArgs == nil or #tArgs ~= 1 or type(tArgs[1]) ~= "string" then
                    return false, "Expected exactly one string argument, the module name, without .lua extesion.\n"
                end
                local sModuleName = string.lower(tArgs[1])
                local pf, sMsg = global.loadfile("Dev/Lua/" .. sModuleName .. ".lua")
                if pf == nil and string.find(sMsg, "No such file or directory") then
                    local sName = global.string.gsub(sModuleName, "%.", "/")
                    pf, sMsg = global.loadfile("Dev/Lua/" .. sName .. ".lua")
                end
                if pf ~= nil then
                    --global.package.preload[ tArgs[1] ] = pf
                    global.package.preload[tArgs[1]] = pf
                    global.package.loaded[tArgs[1]] = nil
                    local a = global.require(tArgs[1])

                    local fnMod, sErrorMessage = global.loadresource(tArgs[1])
                    if not fnMod then
                        return false, "Resource not found: " .. sErrorMessage
                    end
                else
                    return false, "Module import failed: " .. sModuleName .. ".lua not found\n" .. global.tostring(sMgs)
                end
                global.api.debug.WriteLine(tEnv.output, "Module '" .. sModuleName .. "' imported successfully.")
            end,
            "&Import&Module {string}",
            "Imports a lua file to the lua sandbox (do not specify .lua extension).\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if tArgs == nil or #tArgs ~= 1 or type(tArgs[1]) ~= "string" then
                    return false, "Expected exactly one string argument, the module name, without .lua extesion.\n"
                end
                local sModuleName = string.lower(tArgs[1])

                if global.package.preload[sModuleName] == nil and global.package.loaded[sModuleName] == nil then
                    return false, "Module " .. sModuleName .. " not found.\n"
                end

                global.package.preload[sModuleName] = nil
                global.package.loaded[sModuleName] = nil
                global.api.debug.WriteLine(tEnv.output, "Module '" .. sModuleName .. "' removed successfully.\n")
            end,
            "&Remove&Module {string}",
            "Removes a Lua module to the Lua sandbox (do not specify .lua extension).\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                global.api.debug.Trace("Rebuilding custom prefabs..")

                local nStartTime = global.api.time.GetPerformanceTimer()
                for _, tData in global.pairs(GameDatabase.GetLuaPrefabs()) do
                    if (tArgs[1] == nil or global.string.match(tData.PrefabName, tArgs[1])) then
                        local ret = global.api.entity.CompilePrefab(tData.PrefabData, tData.PrefabName)
                        if ret == nil then
                            global.api.debug.WriteLine(tEnv.output, ("Error Compiling: %s "):format(tData.PrefabName))
                        end
                    end
                end
                local nNewTime = global.api.time.GetPerformanceTimer()
                local nDiff = global.api.time.DiffPerformanceTimers(nNewTime, nStartTime)
                local nDiffMs = global.api.time.PerformanceTimeToMilliseconds(nDiff)
                global.api.debug.WriteLine(tEnv.output, ("Completed %d prefabs in %.3f seconds."):format(table.count(GameDatabase.GetLuaPrefabs()), nDiffMs / 1000))
                return true, nil
            end,
            "&Rebuild&Custom&Prefabs [{string}]",
            "Rebuild all custom prefabs containing the specified optional string from the ACSE prefabs table.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                global.api.debug.WriteLine(tEnv.output, "Custom Prefabs:")
                for _, tData in global.pairs(GameDatabase.GetLuaPrefabs()) do
                    if (tArgs[1] == nil or global.string.match(tData.PrefabName, tArgs[1])) then
                        global.api.debug.WriteLine(tEnv.output, " - " .. global.tostring(tData.PrefabName))
                    end
                end
                return true, nil
            end,
            "&List&Custom&Prefabs [{string}]",
            "List all custom prefabs containing the specified optional string.\n"
        ),
    }
    api.debug.Trace("Registered debug shell commands")
end

-- @brief Environment Shutdown
ACSEDebugLuaDatabase.Shutdown = function()
    global.api.debug.Trace("ACSEDebugLuaDatabase:Shutdown()")

    -- Remove custom commands
    for i, oCommand in global.ipairs(ACSEDebugLuaDatabase.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end
    ACSEDebugLuaDatabase.tShellCommands = nil
end

-- List of custom components to force injection to a park
ACSEDebugLuaDatabase.tComponents = {
      ACSEDebugComponent = 'components.acsedebugcomponent',
}

-- @brief add custom components to the game
ACSEDebugLuaDatabase.AddLuaComponents = function(_fnAdd)
    local tData = ACSEDebugLuaDatabase.tComponents
    for sComponentName, tParams in pairs(tData) do
        _fnAdd(sComponentName, tParams)
    end
end

-- List of custom commands to be added to ACSE
ACSEDebugLuaDatabase.tCommands = {
    -- We add this command here so it is available for dev/init.lua
    ['&Import&Module {string}'] = {
        function(tEnv, tArgs)
            if tArgs == nil or #tArgs ~= 1 or type(tArgs[1]) ~= "string" then
                return false, "Expected exactly one string argument, the module name, without .lua extesion.\n"
            end
            local sModuleName = string.lower(tArgs[1])
            local pf, sMsg = global.loadfile("Dev/Lua/" .. sModuleName .. ".lua")
            if pf == nil and string.find(sMsg, "No such file or directory") then
                local sName = global.string.gsub(sModuleName, "%.", "/")
                pf, sMsg = global.loadfile("Dev/Lua/" .. sName .. ".lua")
            end
            if pf ~= nil then
                --global.package.preload[ tArgs[1] ] = pf
                global.package.preload[tArgs[1]] = pf
                global.package.loaded[tArgs[1]] = nil
                local a = global.require(tArgs[1])

                local fnMod, sErrorMessage = global.loadresource(tArgs[1])
                if not fnMod then
                    return false, "Resource not found: " .. sErrorMessage
                end
            else
                return false, "Module import failed: " .. sModuleName .. ".lua not found\n" .. global.tostring(sMgs)
            end
            global.api.debug.WriteLine(tEnv.output, "Module '" .. sModuleName .. "' imported successfully.")
        end,
        "Imports a lua file to the lua sandbox (do not specify .lua extension).\n"
    },
}

-- @brief add custom commands to the game
ACSEDebugLuaDatabase.AddLuaCommands = function(_fnAdd)
    local tData = ACSEDebugLuaDatabase.tCommands
    for sCommandName, tParams in pairs(tData) do
        _fnAdd(sCommandName, tParams)
    end
end