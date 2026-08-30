-- Covers Notify.lua, reading back what the mock captured from print.

local fw = require("TestFramework")
local env = require("Framework")
local WowMock = require("WowMock")

local function lastPrint()
	return WowMock.State.Prints[#WowMock.State.Prints]
end

fw.describe("MiniFramework - chat output", function()
	local framework

	fw.before_each(function()
		framework = env.Load().Framework
	end)

	fw.it("prints a formatted message with no prefix", function()
		framework:Notify("loaded %d of %d", 3, 4)

		fw.eq(lastPrint(), "loaded 3 of 4", "message")
	end)

	fw.it("prints a formatted message behind the coloured addon name", function()
		framework:NotifyWithPrefix("loaded %d", 3)

		fw.eq(lastPrint(), "|cff" .. framework.NotifyColor .. "MiniFrameworkTest|r - loaded 3", "message")
	end)

	fw.it("brands the prefix with the default colour", function()
		fw.eq(framework.NotifyColor, "ffd100", "NotifyColor")
	end)

	fw.it("uses whatever colour the addon set on the framework", function()
		framework.NotifyColor = "00ff00"
		framework:NotifyWithPrefix("hello")

		fw.truthy(lastPrint():find("|cff00ff00", 1, true), "the message carries the new colour")
	end)

	fw.it("prints the combat lockdown message with the prefix", function()
		framework:NotifyCombatLockdown()

		fw.eq(lastPrint(), "|cffffd100MiniFrameworkTest|r - Can't do that during combat.", "message")
	end)
end)
