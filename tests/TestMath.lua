-- Covers Math.lua, the clamps every slider and edit box runs user input through.

local fw = require("TestFramework")
local env = require("Framework")

fw.describe("MiniFramework - clamping", function()
	local framework = env.Load().Framework

	fw.it("rounds to the nearest integer, half up", function()
		fw.eq(framework:ClampInt(2.4, 0, 10, -1), 2, "2.4")
		fw.eq(framework:ClampInt(2.5, 0, 10, -1), 3, "2.5")
		fw.eq(framework:ClampInt(2.6, 0, 10, -1), 3, "2.6")
	end)

	fw.it("rounds a negative half up rather than away from zero", function()
		fw.eq(framework:ClampInt(-2.5, -10, 10, -1), -2, "-2.5")
	end)

	fw.it("clamps an integer to both ends of the range", function()
		fw.eq(framework:ClampInt(-5, 0, 10, -1), 0, "below")
		fw.eq(framework:ClampInt(50, 0, 10, -1), 10, "above")
		fw.eq(framework:ClampInt(0, 0, 10, -1), 0, "at the minimum")
		fw.eq(framework:ClampInt(10, 0, 10, -1), 10, "at the maximum")
	end)

	fw.it("parses a numeric string before clamping it", function()
		fw.eq(framework:ClampInt("7", 0, 10, -1), 7, "in range")
		fw.eq(framework:ClampInt("70", 0, 10, -1), 10, "out of range")
	end)

	fw.it("returns the fallback for anything that is not a number", function()
		fw.eq(framework:ClampInt("abc", 0, 10, -1), -1, "a word")
		fw.eq(framework:ClampInt(nil, 0, 10, -1), -1, "nil")
		fw.eq(framework:ClampInt({}, 0, 10, -1), -1, "a table")
		fw.is_nil(framework:ClampInt("abc", 0, 10), "no fallback given")
	end)

	fw.it("clamps a float without rounding it", function()
		fw.eq(framework:ClampFloat(2.5, 0, 10, -1), 2.5, "in range")
		fw.eq(framework:ClampFloat(-0.5, 0, 10, -1), 0, "below")
		fw.eq(framework:ClampFloat(10.5, 0, 10, -1), 10, "above")
	end)

	fw.it("returns the fallback from ClampFloat for anything that is not a number", function()
		fw.eq(framework:ClampFloat("abc", 0, 10, -1), -1, "a word")
		fw.eq(framework:ClampFloat(nil, 0, 10, -1), -1, "nil")
		fw.eq(framework:ClampFloat("2.5", 0, 10, -1), 2.5, "a numeric string still parses")
	end)
end)
