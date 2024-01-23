-----------------------------------------------------------------------
--/  @file   Database.ACSE.lua
--/  @author Inaki
--/
--/  @brief  Creates a prototypes database for modules to hook into the
--           game environment or alter the current ones. It also registers
--           the basic shell commands missing in the release version.
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local global = _G
local api = global.api
local pairs = pairs
local type = type
local ipairs = ipairs
local next = global.next
local string = global.string
local table = require("Common.tableplus")
local StringUtils = require("Common.stringUtils")
local Main = require("Database.Main")
local GameDatabase = require("Database.GameDatabase")
local ACSE = module(...)

-- List of protos/managers to populate from other mods
ACSE.tEnvironmentProtos = {}

-- List of lua Prefabs to populate from other mods
ACSE.tLuaPrefabs = {}
ACSE.tLuaPrefabNames = {}

-- List of lua Components to populate from other mods
ACSE.tLuaComponents = {}

-- Definition of our own database methods
ACSE.tDatabaseMethods = {
    --/ global environment hook
    GetEnvironmentProtos = function()
        return ACSE.tEnvironmentProtos
    end,
    --/ sql databases
    GetNamedDatabases = function()
        return global.api.acsedatabase.tDatabases
    end,
    --/ Lua Components
    GetLuaComponents = function()
        return ACSE.tLuaComponents
    end,
    --/ Lua prefabs
    --/ Todo: save compiled prefab token as the value into the prefabNames table instead of a true
    GetLuaPrefabs = function()
        return ACSE.tLuaPrefabs
    end,
    GetLuaPrefabNames = function()
        return ACSE.tLuaPrefabNames
    end,
    --/ Lua prefabs
    GetLuaPrefab = function(_sName)
        global.api.debug.Assert(
            ACSE.tLuaPrefabNames[_sName] ~= nil,
            "ACSE trying to access a missing prefab: " .. _sName
        )
        for _, tData in global.ipairs(ACSE.tLuaPrefabs) do
            if tData.PrefabName == _sName then
                return tData.PrefabData
            end
        end
        return nil
    end,
    --/ Lua prefabs
    BuildLuaPrefabs = function()
        local nStartTime = global.api.time.GetPerformanceTimer()
        for _, tData in global.ipairs(ACSE.tLuaPrefabs) do
            local cPrefab = global.api.entity.CompilePrefab(tData.PrefabData, tData.PrefabName)
        end
        local nNewTime = global.api.time.GetPerformanceTimer()
        local nDiff = global.api.time.DiffPerformanceTimers(nNewTime, nStartTime)
        local nDiffMs = global.api.time.PerformanceTimeToMilliseconds(nDiff)
        global.api.debug.Trace(
            ("Compiling %d Lua prefabs took %.3f seconds."):format(table.count(ACSE.tLuaPrefabs), (nDiffMs / 1000))
        )
    end,
    BuildLuaPrefab = function(_sName)
        for _, tData in global.ipairs(ACSE.tLuaPrefabs) do
            if tData.PrefabName == _sName then
                local cPrefab = global.api.entity.CompilePrefab(tData.PrefabData, tData.PrefabName)
                return
            end
        end
        global.api.debug.Trace("ACSE trying to build a missing prefab: " .. _sName)
    end,
    --/ version info
    GetACSEVersionString = function()
        return api.acse.GetACSEVersionString()
    end,
    --/ dev path info
    GetACSEDevPath = function()
        return api.acse.GetACSEPath()
    end,
    --/ dev path info
    SetACSEDevPath = function(_sPath)
        return api.acse.SetACSEPath(_sPath)
    end,
    --/ have access to the tweakables
    GetAllTweakables = function()
        return api.acsedebug.GetTweakables()
    end,
    --/ get one tweakable
    GetTweakable = function(_sName)
        return api.acsedebug.GetDebugTweakable(_sName)
    end
}

api.debug.Trace("ACSE " .. api.acse.GetACSEVersionString() .. " Running on " .. global._VERSION)

-- @brief returns true if a string is any form of number, used in EPS command
function IsNumeric(data)
    if global.type(data) == "number" then
        return true
    elseif global.type(data) ~= "string" then
        return false
    end
    local x, y = global.string.find(data, "[%d+][%.?][%d*]")
    if x and x == 1 and y == global.string.len(data) then
        return true
    end
    return false
end

-- @brief Database init
ACSE.Init = function()
    ACSE._initLuaOverrides()

    global.api.debug.Trace("ACSE:Init() running in " .. global.tostring(global.api.game.GetGameName()))

    ACSE.tEnvironmentProtos = {}
    ACSE.tLuaPrefabs = {}
    ACSE.tLuaPrefabNames = {}

    -- Register our own custom shell commands
    ACSE.tShellCommands = {
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 2 then
                    return false, "SetTweakable requires two arguments"
                end

                local sTweakableNamePattern = string.lower(tArgs[1])
                local tLoadedTweakableNames = GameDatabase.GetAllTweakables()

                local tFilteredLoadedModuleNames = {}
                _pattern = string.gsub(sTweakableNamePattern, "%%", "")
                for k, v in global.pairs(tLoadedTweakableNames) do
                    if StringUtils.StrMatchI(k, _pattern) then
                        tFilteredLoadedModuleNames[#tFilteredLoadedModuleNames + 1] = k
                    end
                end

                local nFoundModulesCount = #tFilteredLoadedModuleNames
                if nFoundModulesCount < 1 then
                    return false, 'Couldn\'t find a Tweakable matching the pattern "' .. sTweakableNamePattern .. '".'
                end

                -- Locating named modules
                for i, sModuleName in ipairs(tFilteredLoadedModuleNames) do
                    if sTweakableNamePattern == string.lower(sModuleName) then
                        tFilteredLoadedModuleNames = {sModuleName}
                    end
                end
                nFoundModulesCount = #tFilteredLoadedModuleNames

                if nFoundModulesCount > 1 then
                    local allModulesList = table.concat(tFilteredLoadedModuleNames, "\n")
                    return false, "Found " ..
                        global.tostring(nFoundModulesCount) ..
                            ' existing Tweakables matching the pattern "' ..
                                sTweakableNamePattern ..
                                    '". You need to be more specific. \nPossible Tweakables:\n' .. allModulesList
                end

                local sTweakableName = tFilteredLoadedModuleNames[1]

                tweakable = api.acsedebug.GetDebugTweakable(sTweakableName)
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
                for k, v in global.pairs(api.acsedebug.tTweakables) do
                    if (tArgs[1] == nil or global.string.match(string.lower(k), string.lower(tArgs[1]))) then
                        api.debug.Trace(global.tostring(v.id) .. " = " .. global.tostring(v.value))
                    end
                end
            end,
            "&List&Tweakables [{string}]",
            "Prints a list of the current tweakables and its values. Specify a filter string to limit the list.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                api.debug.Trace("List of Commands:")
                for k, v in global.pairs(api.acsedebug.tShellCommands) do
                    if (tArgs[1] == nil or global.string.match(string.lower(k), string.lower(tArgs[1]))) then
                        api.debug.Trace(global.tostring(v._sCmd))
                    end
                end
            end,
            "&List&Commands [{string}]",
            "Prints a list of the current commands and its arguments. Specify a filter string to limit the list.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if global.type(tArgs) == "table" and #tArgs > 0 and global.type(tArgs[1]) == "string" then
                    cmdname = global.string.lower(tArgs[1])
                    oCmd = api.acsedebug.tShellCommands[cmdname]
                    if global.type(oCmd) == "table" then
                        global.api.debug.Trace(global.tostring(oCmd._sCmd) .. "\n" .. global.tostring(oCmd._sDesc))
                    else
                        return false, "Command " .. global.tostring(tArgs[1]) .. " not found."
                    end
                else
                    return false, "Help requires a command name as argument"
                end
            end,
            "&Help {string}",
            "Displays information about a command.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                global.api.debug.Trace("Rebuilding custom prefabs..")

                local nStartTime = global.api.time.GetPerformanceTimer()
                for _, tData in global.pairs(GameDatabase.GetLuaPrefabs()) do
                    if (tArgs[1] == nil or global.string.match(tData.PrefabName, tArgs[1])) then
                        global.api.entity.CompilePrefab(tData.PrefabData, tData.PrefabName)
                    end
                end
                local nNewTime = global.api.time.GetPerformanceTimer()
                local nDiff = global.api.time.DiffPerformanceTimers(nNewTime, nStartTime)
                local nDiffMs = global.api.time.PerformanceTimeToMilliseconds(nDiff)
                global.api.debug.Trace(("Completed in %.3f seconds."):format(nDiffMs / 1000))
                return true, nil
            end,
            "&Rebuild&Custom&Prefabs [{string}]",
            "Rebuild all custom prefabs containing the specified optional string from the ACSE prefabs table.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                global.api.debug.Trace("Custom Prefabs:")
                for _, tData in global.pairs(GameDatabase.GetLuaPrefabs()) do
                    if (tArgs[1] == nil or global.string.match(tData.PrefabName, tArgs[1])) then
                        global.api.debug.Trace(" - " .. global.tostring(tData.PrefabName))
                    end
                end
                return true, nil
            end,
            "&List&Custom&Prefabs [{string}]",
            "List all custom prefabs containing the specified optional string.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                global.api.debug.Trace("Game Prefabs:")
                local tPrefabs = global.api.entity.EnumerateRootPrefabs()
                for _, k in global.ipairs(tPrefabs) do
                    if (tArgs[1] == nil or global.string.match(k, tArgs[1])) then
                        global.api.debug.Trace(" - " .. global.tostring(k))
                    end
                end
                return true, nil
            end,
            "&List&Prefabs [{string}]",
            "List all existing prefabs containing the specified optional string.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs ~= 1 then
                    return false, "Loadfile requires one argument, the name of the lua file (without the .lua extension).\n"
                end

                local sModuleName = global.tostring(tArgs[1])
                global.api.debug.Trace("Loading file: " .. sModuleName)
                local pf, sMsg = global.loadfile(api.acse.devpath .. sModuleName .. ".lua")
                if pf == nil and string.find(sMsg, "No such file or directory") then
                    local sName = global.string.gsub(sModuleName, "%.", "/")
                    pf, sMsg = global.loadfile(api.acse.devpath .. sName .. ".lua")
                end
                if pf ~= nil and global.type(pf) == "function" then
                    local bOk, sMsg = global.pcall(pf, sModuleName)
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
                if #tArgs ~= 1 then
                    return false, "Lua requires one argument. If your Lua code includes spaces, use quotes to convert to a single string.\n"
                end

                local luastr = "local global = _G local api = global.api " .. tArgs[1]
                local pf, sMsg = global.loadstring(luastr)
                if pf ~= nil then
                    local bOk, sMsg = global.pcall(pf, sModuleName)
                    if bOk == false then
                        return false, global.tostring(sMsg) .. "\n"
                    end
                else
                    return false, "error: " .. global.tostring(sMsg) .. "\n"
                end
            end,
            "Lua {string}",
            "Loads and execute a Lua string within quotes.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                global.api.debug.Trace("Named Databases:")
                for k, v in global.pairs(GameDatabase.GetNamedDatabases()) do
                    if (tArgs[1] == nil or global.string.match(k, tArgs[1])) then
                        global.api.debug.Trace(" - " .. global.tostring(k))
                    end
                end

                return true, nil
            end,
            "&List&Databases [{string}]",
            "List all named databases containing the specified optional string.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs < 2 then
                    return false, "Execute SQL requires at least two arguments: Database and 'SQL query'."
                end

                -- Get access to the game database interface
                local database = global.api.database
                local dbname = tArgs[1]
                local query = tArgs[2]
                local readon = tArgs[3] or false

                if not database.NamedDatabaseExists(dbname) then
                    return false, "Database " .. dbname .. " does not exist"
                end
                local bOldReadonly = database.GetReadOnly(dbname)
                database.SetReadOnly(dbname, readon)

                -- We need to bind our new Prepared Statement collection to the Buildings database before
                -- we can use any of its statements.
                local cQuery = database.ExecuteSQL(dbname, query)
                if cQuery == nil then
                    return false, "SQL Error: malformed query."
                end

                local bRet = false
                local sRet = "SQL Error: problem executing SQL query"

                if database.Step(cQuery) == true then
                    local tResult = database.GetAllResults(cQuery, true)
                    if global.type(tResult) == "table" then
                        sRet = table.tostring(tResult, nil, nil, nil, true)
                        bRet = true
                    end
                end

                -- clean up and restore read only state
                database.Reset(cQuery, true)
                database.SetReadOnly(dbname, bReadonly)
                return bRet, sRet
            end,
            "Execute&S&Q&L {string} {string} [{bool}]",
            "Executes a SQL on the selected database, optionally enable write mode on the database.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs < 2 then
                    return false, "BindPreparedStatement requires at least two arguments: Database and prepared Statement Collection name."
                end

                -- Get access to the game database interface
                local database = global.api.database
                local dbname = tArgs[1]
                local pscol = tArgs[2]
                local readon = tArgs[3] or true

                database.SetReadOnly(dbname, readon)

                -- We need to bind our new Prepared Statement collection to the Buildings database before
                -- we can use any of its statements.
                local bSuccess = database.BindPreparedStatementCollection(dbname, pscol)
                global.api.debug.Assert(bSuccess == true, "Problem binding " .. pscol .. " to " .. dbname)
            end,
            "&Bind&P&S&Collection {string} {string} [{bool}]",
            "Binds a prepared statement collection to a database, optionally enable write mode on the database.\n"
        ),
        api.debug.RegisterShellCommand(
            function(tEnv, tArgs)
                if #tArgs < 2 then
                    return false, "ExecutePreparedSstatement requires at least two arguments: Database and prepared Statement name."
                end

                -- Get access to the game database interface
                local database = global.api.database
                local dbname = tArgs[1]
                local psname = tArgs[2]

                -- Connect the PS to the database
                local cPSInstance = database.GetPreparedStatementInstance(dbname, psname)
                if cPSInstance ~= nil then
                    for i = 3, #tArgs, 1 do
                        global.api.debug.Trace("Binding: " .. global.tostring(tArgs[i]))
                        local value = tArgs[i]
                        if IsNumeric(tArgs[i]) then
                            value = global.tonumber(value)
                        end
                        database.BindParameter(cPSInstance, global.tonumber(i - 2), value)
                    end
                    database.BindComplete(cPSInstance)
                    database.Step(cPSInstance)

                    -- @TODO: Convert this into a table we can print
                    -- @TODO: Convert result to a global value accessible later
                    local tRows = database.GetAllResults(cPSInstance, false)
                    local result = tRows or {}
                    if global.type(tResult) == "table" then
                        return true, table.tostring(tResult, nil, nil, nil, true)
                    end
                else
                    return false, "Unable to bind PreparedStatement, did you Bind the Prepared Statement collection first?"
                end
            end,
            "&Execute&Prepared&Statement {string} {string} [{value}] [{value}] [{value}] [{value}]",
            "Runs a Prepared Statement query against a database. You will need database name, PS name, and its arguments.\n"
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
                    if sModuleNamePattern == (string.lower)(sModuleName) then
                        tFilteredLoadedModuleNames = {sModuleName}
                    end
                end
                nFoundModulesCount = #tFilteredLoadedModuleNames

                if nFoundModulesCount > 1 then
                    local allModulesList = (table.concat)(tFilteredLoadedModuleNames, "\n")
                    return false, "Found " ..
                        global.tostring(nFoundModulesCount) ..
                            ' loaded modules matching the pattern "' .. sModuleNamePattern ..
                            '". You need to be more specific. \nPossible modules:\n' .. allModulesList
                end

                local sModuleName = tFilteredLoadedModuleNames[1]

                -- load the new file and replace the Lua package system
                local pf, sMsg = global.loadfile(api.acse.devpath .. sModuleName .. ".lua")
                if pf == nil and string.find(sMsg, "No such file or directory") then
                    local sName = global.string.gsub(sModuleName, "%.", "/")
                    pf, sMsg = global.loadfile(api.acse.devpath .. sName .. ".lua")
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
                global.api.debug.Trace("Module '" .. sModuleName .. "' reloaded successfully.")
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
                local pf, sMsg = global.loadfile(api.acse.devpath .. sModuleName .. ".lua")
                if pf == nil and string.find(sMsg, "No such file or directory") then
                    local sName = global.string.gsub(sModuleName, "%.", "/")
                    pf, sMsg = global.loadfile(api.acse.devpath .. sName .. ".lua")
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
                global.api.debug.Trace("Module '" .. sModuleName .. "' imported successfully.")
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
                global.api.debug.Trace("Module '" .. sModuleName .. "' removed successfully.\n")
            end,
            "&Remove&Module {string}",
            "Removes a Lua module to the Lua sandbox (do not specify .lua extension).\n"
        )
    }
    api.debug.Trace("Finished creating custom shell commands")

    --/ Request Starting Screen Managers from other mods
    Main.CallOnContent(
        "AddStartScreenManagers",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                api.debug.Warning("Manager: " .. _sName .. " is being added using AddStartScreenManagers (obsolete API).")
                local tItem = {
                    sName = "Environments.StartScreenEnvironment",
                    tData = {
                        [_sName] = _tParams
                    },
                }
                table.insert(ACSE.tEnvironmentProtos, tItem)
            end
        end
    )

    --/ Request Park Managers from other mods
    Main.CallOnContent(
        "AddParkManagers",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                api.debug.Warning("Manager: " .. _sName .. " is being added using AddParkManagers (obsolete API).")

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
                table.insert(ACSE.tEnvironmentProtos, tItem)
            end
        end
    )

    --/ Request Park Managers from other mods. The new format is using the
    --/ environment name to override and prototype table to merge
    Main.CallOnContent(
        "AddManagers",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                table.insert(
                    ACSE.tEnvironmentProtos, 
                    {   
                        sName = _sName,
                        tData = _tParams
                    }
                )
            end
        end
    )

    --/ Request Lua Prefabs from other mods
    local nStartTime = global.api.time.GetPerformanceTimer()
    Main.CallOnContent(
        "AddLuaPrefabs",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "table" then
                if global.api.debug.Assert(ACSE.tLuaPrefabNames[_sName] == nil, "Duplicated Lua Prefab " .. _sName) then
                    ACSE.tLuaPrefabNames[_sName] = true
                    table.append(ACSE.tLuaPrefabs, {PrefabName = _sName, PrefabData = _tParams})
                end
            end
        end
    )
    local nNewTime = global.api.time.GetPerformanceTimer()
    local nDiff = global.api.time.DiffPerformanceTimers(nNewTime, nStartTime)
    local nDiffMs = global.api.time.PerformanceTimeToMilliseconds(nDiff)
    global.api.debug.Trace(
        ("Loaded %d Lua prefabs in %.3f seconds"):format(table.count(ACSE.tLuaPrefabNames), (nDiffMs / 1000))
    )

    --/ Request Lua Components from other mods
    Main.CallOnContent(
        "AddLuaComponents",
        function(_sName, _tParams)
            if type(_sName) == "string" and type(_tParams) == "string" then
                global.api.debug.Trace("Adding component: " .. _sName)
                global.api.debug.Assert(ACSE.tLuaComponents[_sName] == nil, "Duplicated Lua Component " .. _sName)
                ACSE.tLuaComponents[_sName] = _tParams
            end
        end
    )
    api.debug.Trace("Finished collecting other mods bootstrap")

    --/
    --/ Modify the environment files, it'd need a better way to handle this, this is 
    --/ very inefficient.
    --/
    local addManagersToEnvironment = function(sEnvironment, tManagers)
        -- Perform environment overrides
        local modname = sEnvironment
        local tfMod = global.require(modname)

        --/ Required module will be in the package loaded table.
        local tMod = global.package.preload[modname] or global.package.loaded[modname]

        --/ if still not found use the loaded table from require
        tMod = tMod or tfMod
        global.api.debug.Assert(tMod ~= nil, "Can't find " .. modname .. "  resource")

        ACSE._merge = function(a, b, bModifyOnly)
            if global.type(a) == "table" and global.type(b) == "table" then
                for k, v in global.pairs(b) do
                    if global.type(v) == "table" and global.type(a[k] or false) == "table" then
                        ACSE._merge(a[k], v, bModifyOnly)
                    else
                        if not bModifyOnly or bModifyOnly == false or (bModifyOnly == true and a[k] ~= nil) then
                            a[k] = v
                        end
                    end
                end
            end
            return a
        end
        --api.debug.Trace("Proto: " .. table.tostring(tMod.EnvironmentPrototype, nil, nil, nil, true))
        for _sName, _tParams in global.pairs(tManagers) do
            if not _tParams.__inheritance or _tParams.__inheritance == "Overwrite" then
                api.debug.Trace("Adding Manager: " .. _sName .. " in " .. sEnvironment)
                tMod.EnvironmentPrototype["Managers"][_sName] = _tParams
            end
            if _tParams.__inheritance == "Append" then
                api.debug.Trace("Merging Manager: " .. _sName .. " in " .. sEnvironment)
                tMod.EnvironmentPrototype["Managers"][_sName] =
                    _merge(tMod.EnvironmentPrototype["Managers"][_sName], _tParams)
            end
            if _tParams.__inheritance == "Modify" then
                api.debug.Trace("Modifying Manager: " .. _sName .. " in " .. sEnvironment)
                tMod.EnvironmentPrototype["Managers"][_sName] =
                    _merge(tMod.EnvironmentPrototype["Managers"][_sName], _tParams, true)
            end
            -- Any other case will be ignored
        end

        --/ We move the resource to the preload table, so Lua wont need to load it again and
        --/ will return our changes
        global.package.preload[modname] = tMod
    end

    -- Merge all environment changes to the right modules
    for _, tParams in global.ipairs(ACSE.tEnvironmentProtos) do
        addManagersToEnvironment(tParams.sName, tParams.tData)
    end
    api.debug.Trace("Finished patching Environments")

    --/
    --/ Hook into the main game settings controller
    --/
    --/
    local modname = "windows.gameplayoptionsmenu"
    if api.game.GetGameName() == "Planet Zoo" then
        modname = "windows.gameoptionsmenu"
    end
    global.require(modname)

    --/ Required module will be in the package loaded table.
    local tMod = global.package.preload[modname] or global.package.loaded[modname]
    global.api.debug.Assert(tMod ~= nil, "Can't find " .. modname .. " resource")

    -- Handles building the menu list to mods
    if not tMod.ACSEGetItems then
        -- This code is used to send the game settings item list to mods
        tMod.ACSEGetItems = tMod.GetItems
        tMod.GetItems = function(self, _tSettingsMenuItemsData)
            self:ACSEGetItems(_tSettingsMenuItemsData)
            for _, handler in ipairs(global.api.acse._tGameSettingsRegistrations) do
                if handler.fGetItems then
                    handler.fGetItems(_tSettingsMenuItemsData['items'])
                end
            end
        end
    end

    -- Handles sending events to the mods
    if not tMod.ACSEHandleEvent then
        -- This code is used to send the game settings item list to mods
        tMod.ACSEHandleEvent = tMod.HandleEvent
        tMod.HandleEvent = function(self, _sID, _arg)
            --api.debug.Trace("GameSettings:HandleEvent()")
            local bHandled, bNeedsRefresh = self:ACSEHandleEvent(_sID, _arg)
            for _, handler in ipairs(global.api.acse._tGameSettingsRegistrations) do
                if handler.fHandleEvent then
                    bHandled, bNeedsRefresh = handler.fHandleEvent(_sID, _arg, bHandled, bNeedsRefresh )
                end
            end
            return bHandled, bNeedsRefresh
        end
    end

    -- Handles applying changes to the settings
    if not tMod.ACSEApplyChanges then
        tMod.ACSEApplyChanges = tMod.ApplyChanges
        tMod.ApplyChanges = function(self)
            local ret = self:ACSEApplyChanges()
            for _, handler in ipairs(global.api.acse._tGameSettingsRegistrations) do
                if handler.fApplyChanges then
                    ret = handler.fApplyChanges()
                end
            end
            return ret
        end
    end

    --/ We move the resource to the preload table, so Lua wont need to load it again and
    --/ will return our changes
    global.package.preload[modname] = tMod
    api.debug.Trace("Finished patching " .. modname)


    --/
    --/ Hook into the sandbox game settings controller
    --/
    --/
    local modname = "windows.sandboxoptionsmenu"
    if api.game.GetGameName() == "Planet Zoo" then
        modname = "windows.sandboxoptionsmenu"
    end
    global.require(modname)

    --/ Required module will be in the package loaded table.
    local tMod = global.package.preload[modname] or global.package.loaded[modname]
    global.api.debug.Assert(tMod ~= nil, "Can't find " .. modname .. " resource")

    -- Handles building the menu list to mods
    if not tMod.ACSEGetItems then
        -- This code is used to send the game settings item list to mods
        tMod.ACSEGetItems = tMod.GetItems
        tMod.GetItems = function(self, _tSettingsMenuItemsData)
            self:ACSEGetItems(_tSettingsMenuItemsData)
            for _, handler in ipairs(global.api.acse._tSandboxSettingsRegistrations) do
                if handler.fGetItems then
                    handler.fGetItems(_tSettingsMenuItemsData['items'])
                end
            end
        end
    end

    -- Handles sending events to the mods
    if not tMod.ACSEHandleEvent then
        -- This code is used to send the game settings item list to mods
        tMod.ACSEHandleEvent = tMod.HandleEvent
        tMod.HandleEvent = function(self, _sID, _arg)
            --api.debug.Trace("SandboxSettings:HandleEvent()")
            local bHandled, bNeedsRefresh = self:ACSEHandleEvent(_sID, _arg)
            for _, handler in ipairs(global.api.acse._tSandboxSettingsRegistrations) do
                if handler.fHandleEvent then
                    bHandled, bNeedsRefresh = handler.fHandleEvent(_sID, _arg, bHandled, bNeedsRefresh )
                end
            end
            return bHandled, bNeedsRefresh
        end
    end

    -- Handles applying changes to the settings
    if not tMod.ACSEApplyChanges then
        tMod.ACSEApplyChanges = tMod.ApplyChanges
        tMod.ApplyChanges = function(self)
            local ret = self:ACSEApplyChanges()
            for _, handler in ipairs(global.api.acse._tSandboxSettingsRegistrations) do
                if handler.fApplyChanges then
                    ret = handler.fApplyChanges()
                end
            end
            return ret
        end
    end

    --/ We move the resource to the preload table, so Lua wont need to load it again and
    --/ will return our changes
    global.package.preload[modname] = tMod
    api.debug.Trace("Finished patching " .. modname)


    --/
    --/ Hook into the keyboard controls settings controller
    --/
    --/
    local modname = "windows.keyboardoptionsmenu"
    if api.game.GetGameName() == "Planet Zoo" then
        modname = "windows.controlsoptionsmenu"
    end
    global.require(modname)

    --/ Required module will be in the package loaded table.
    local tMod = global.package.preload[modname] or global.package.loaded[modname]
    global.api.debug.Assert(tMod ~= nil, "Can't find " .. modname .. " resource")

    -- Handles building the menu list to mods
    if not tMod.ACSEGetItems then
        -- This code is used to send the game settings item list to mods
        tMod.ACSEGetItems = tMod.GetItems
        tMod.GetItems = function(self, _tSettingsMenuItemsData)
            self:ACSEGetItems(_tSettingsMenuItemsData)
            for _, handler in ipairs(global.api.acse._tControlsSettingsRegistrations) do
                if handler.fGetItems then
                    handler.fGetItems(_tSettingsMenuItemsData['items'])
                end
            end
        end
    end

    -- Handles sending events to the mods
    if not tMod.ACSEHandleEvent then
        -- This code is used to send the game settings item list to mods
        tMod.ACSEHandleEvent = tMod.HandleEvent
        tMod.HandleEvent = function(self, _sID, _arg)
            --api.debug.Trace("KeyboardSettings:HandleEvent()")
            local bHandled, bNeedsRefresh = self:ACSEHandleEvent(_sID, _arg)

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
    end

    -- Handles applying changes to the settings
    if not tMod.ACSEApplyChanges then
        tMod.ACSEApplyChanges = tMod.ApplyChanges
        tMod.ApplyChanges = function(self)
            local ret = self:ACSEApplyChanges()
            for _, handler in ipairs(global.api.acse._tControlsSettingsRegistrations) do
                if handler.fApplyChanges then
                    ret = handler.fApplyChanges()
                end
            end
            return ret
        end
    end

    --/ We move the resource to the preload table, so Lua wont need to load it again and
    --/ will return our changes
    global.package.preload[modname] = tMod
    api.debug.Trace("Finished patching " .. modname)

    --/
    --/ PZ Specific patch.. debug changes prevent career mode to populate saves list
    --/ There is no workaround, the problem comes from the game not liking the metatable
    --/ change.
    if api.game.GetGameName() == "Planet Zoo" then
        modname = "windows.settingsmenu"
        global.require(modname)

        --/ Required module will be in the package loaded table.
        local tMod = global.package.preload[modname] or global.package.loaded[modname]
        global.api.debug.Assert(tMod ~= nil, "Can't find " .. modname .. " resource")

        if not tMod.ACSEPopulateSaveMenu then
            tMod.ACSEPopulateSaveMenu = tMod.PopulateSaveMenu
            tMod.PopulateSaveMenu = function(self)
                -- Temporarily disable the debug handling
                api.debug = global.getmetatable(api.debug).__index
                self:ACSEPopulateSaveMenu()
                api.debug = global.setmetatable(api.acsedebug, {__index = global.api.debug})
            end
        end

        --/ We move the resource to the preload table, so Lua wont need to load it again and
        --/ will return our changes
        global.package.preload[modname] = tMod
        api.debug.Trace("Finished patching " .. modname)
    end




end

-- @brief Environment Shutdown
ACSE.Shutdown = function()
    global.api.debug.Trace("ACSE:Shutdown()")

    -- Remove custom commands
    for i, oCommand in ipairs(ACSE.tShellCommands) do
        api.debug.UnregisterShellCommand(oCommand)
    end
    ACSE.tShellCommands = nil

    -- Restore Lua environment
    ACSE._shutdownLuaOverrides()
end

-- @brief Called when a Reinit is about to happen
ACSE.ShutdownForReInit = function()
end

-- @brief adds our custom database methods to the main game database
ACSE.AddDatabaseFunctions = function(_tDatabaseFunctions)
    for sName, fnFunction in pairs(ACSE.tDatabaseMethods) do
        _tDatabaseFunctions[sName] = fnFunction
    end
end


--[[ Old way to add managers, still compatible
-- List of custom managers to force injection on the starting screen
ACSE.tStartScreenManagers = {
    ["Managers.ACSEStartScreenManager"] = {}
}

-- @brief Add our custom Manager to the starting screen
ACSE.AddStartScreenManagers = function(_fnAdd)
    local tData = ACSE.tStartScreenManagers
    for sManagerName, tParams in pairs(tData) do
        _fnAdd(sManagerName, tParams)
    end
end

-- List of custom managers to force injection on a park
ACSE.tParkManagers = {
    ["Managers.ACSEParkManager"] = {}
}

-- @brief Add our custom Manager to the starting screen
ACSE.AddParkManagers = function(_fnAdd)
    local tData = ACSE.tParkManagers
    for sManagerName, tParams in pairs(tData) do
        _fnAdd(sManagerName, tParams)
    end
end
]]

-- List of custom managers to force injection on a park, because ACSE source
-- works for both PZ and JWE we need to identify the current game to fill the 
-- right table
local sParkEnvironment = "Environments.ParkEnvironment"
if api.game.GetGameName() == "Planet Zoo" then
    sParkEnvironment = "Environments.DarwinEnvironment"
end
ACSE.tManagers = {
    ["Environments.StartScreenEnvironment"] = {
        ["Managers.ACSEStartScreenManager"] = {},
    },
    [sParkEnvironment] = {
        ["Managers.ACSEParkManager"] = {}
    }
}

-- @brief Add our custom Manager to the different environments
ACSE.AddManagers = function(_fnAdd)
    local tData = ACSE.tManagers
    for sManagerName, tParams in pairs(tData) do
        _fnAdd(sManagerName, tParams)
    end
end

-- @Brief Perform any custom Lua:global/api updates
ACSE._initLuaOverrides = function()
    global.api.debug.Trace("Initializing lua overrides")

    -- Perform Lua override
    local rdebug = global.api.debug
    local entity = global.api.entity
    local database = global.api.database
    local componentmanager = global.api.componentmanager

    api.debug = global.setmetatable(api.acsedebug, {__index = rdebug})
    api.componentmanager = global.setmetatable(api.acsecomponentmanager, {__index = componentmanager})
    api.entity = global.setmetatable(api.acseentity, {__index = entity})
    api.database = global.setmetatable(api.acsedatabase, {__index = database})

    -- other Inits
    api.entity.tLoadedEntities = {}
    api.database.tDatabases = {}
end

-- @Brief Undo all Lua changes so the game exists gracefully
ACSE._shutdownLuaOverrides = function()
    --  Perform clean ups
    api.database.tDatabases = {}
    api.entity.tLoadedEntities = {}

    api.database = global.getmetatable(api.database).__index
    api.entity = global.getmetatable(api.entity).__index
    api.componentmanager = global.getmetatable(api.componentmanager).__index
    api.debug = global.getmetatable(api.debug).__index
end
