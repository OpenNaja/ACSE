-----------------------------------------------------------------------
--/  @file   Interfaces.IACSEDebugManager.lua
--/  @author My Self
--/
--/  @brief  Interface to access the Debug Window from other modules
--/  @see    https://github.com/OpenNaja/ACSE
-----------------------------------------------------------------------
local Mutators = require("Common.mutators")
local Interface = module(..., Mutators.Interface)

Interface.Methods = { "SetVisible" }

(Mutators.VerifyInterfaceModule)(Interface)
