-- Covers CleanTable's rules, in particular the empty-template carve-out that keeps
-- user-authored tables whole.

local fw = require("TestFramework")
local env = require("Framework")

fw.describe("MiniFramework - tables", function()
	local framework = env.Load().Framework

	fw.it("drops keys the template does not describe", function()
		local target = { Known = 1, Unknown = 2 }

		framework:CleanTable(target, { Known = 0 }, true, true)

		fw.eq(target.Known, 1, "Known")
		fw.eq(target.Unknown, nil, "Unknown")
	end)

	fw.it("resets a value the template says is not a table", function()
		local target = { Size = { 1, 2 } }

		framework:CleanTable(target, { Size = 10 }, true, true)

		fw.eq(target.Size, 10, "Size")
	end)

	fw.it("cleans nested tables against their own template", function()
		local target = { Icons = { Size = 20, Retired = true } }

		framework:CleanTable(target, { Icons = { Size = 10 } }, true, true)

		fw.eq(target.Icons.Size, 20, "Icons.Size")
		fw.eq(target.Icons.Retired, nil, "Icons.Retired")
	end)

	fw.it("leaves a table whole when the template for it is empty", function()
		local target = { Spells = { [12345] = true }, Groups = { { Name = "Mine" } } }

		framework:CleanTable(target, { Spells = {}, Groups = {} }, true, true)

		fw.eq(target.Spells[12345], true, "Spells entry")
		fw.eq(target.Groups[1].Name, "Mine", "Groups entry")
	end)
end)
