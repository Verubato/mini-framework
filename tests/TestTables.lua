-- Covers Tables.lua: CleanTable's rules, in particular the empty-template carve-out that
-- keeps user-authored tables whole, and the copy helpers every addon's defaults ride on.

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

	fw.it("keeps unknown keys when cleanValues is off", function()
		local target = { Known = 1, Unknown = 2 }

		framework:CleanTable(target, { Known = 0 }, false, true)

		fw.eq(target.Unknown, 2, "Unknown")
	end)

	fw.it("leaves nested tables alone when recurse is off", function()
		local target = { Icons = { Size = 20, Retired = true } }

		framework:CleanTable(target, { Icons = { Size = 10 } }, true, false)

		fw.eq(target.Icons.Retired, true, "Icons.Retired")
	end)

	fw.it("leaves a wrongly typed scalar where it is", function()
		-- A boolean default can stand for "unset" with a string as the real value, so resetting
		-- by type would wipe a choice the player made.
		local target = { Size = "big" }

		framework:CleanTable(target, { Size = 10 }, true, true)

		fw.eq(target.Size, "big", "Size")
	end)

	fw.it("ignores a target or template that is not a table", function()
		fw.no_error(function()
			framework:CleanTable(nil, { Size = 10 }, true, true)
		end, "nil target")

		fw.no_error(function()
			framework:CleanTable({ Size = 1 }, nil, true, true)
		end, "nil template")

		fw.no_error(function()
			framework:CleanTable("text", 10, true, true)
		end, "scalar target and template")
	end)
end)

fw.describe("MiniFramework - table copying", function()
	local framework = env.Load().Framework

	fw.it("fills only the keys the destination is missing", function()
		local dst = { Size = 20 }

		framework:CopyTable({ Size = 10, Colour = "red" }, dst)

		fw.eq(dst.Size, 20, "the user's value survived")
		fw.eq(dst.Colour, "red", "the missing default was filled")
	end)

	fw.it("builds a destination when it is given nil", function()
		local dst = framework:CopyTable({ Size = 10 })

		fw.eq(type(dst), "table", "dst type")
		fw.eq(dst.Size, 10, "Size")
	end)

	fw.it("builds a destination when it is given a non-table", function()
		local dst = framework:CopyTable({ Size = 10 }, "not a table")

		fw.eq(type(dst), "table", "dst type")
		fw.eq(dst.Size, 10, "Size")
	end)

	fw.it("clones nested tables rather than sharing them", function()
		local defaults = { Icons = { Size = 10 } }
		local dst = framework:CopyTable(defaults, {})

		fw.neq(dst.Icons, defaults.Icons, "nested table identity")

		dst.Icons.Size = 99

		fw.eq(defaults.Icons.Size, 10, "the defaults table stayed put")
	end)

	fw.it("clones a nested table the destination already has, in place", function()
		local dst = { Icons = { Size = 20 } }
		local icons = dst.Icons

		framework:CopyTable({ Icons = { Size = 10, Border = 2 } }, dst)

		fw.eq(dst.Icons, icons, "the existing nested table instance was kept")
		fw.eq(dst.Icons.Size, 20, "the user's nested value survived")
		fw.eq(dst.Icons.Border, 2, "the missing nested default was filled")
	end)

	fw.it("replaces a scalar the source describes as a table", function()
		local dst = { Size = 5 }

		framework:CopyTable({ Size = { 1, 2 } }, dst)

		fw.eq(type(dst.Size), "table", "Size type")
		fw.eq(dst.Size[1], 1, "Size[1]")
	end)

	fw.it("keeps a destination table the source describes as a scalar", function()
		local dst = { Size = { 7 } }

		framework:CopyTable({ Size = 5 }, dst)

		fw.eq(type(dst.Size), "table", "Size type")
		fw.eq(dst.Size[1], 7, "Size[1]")
	end)

	fw.it("merges arrays index by index instead of replacing them", function()
		local dst = { 10, 20, 30 }

		framework:CopyTable({ 1, 2 }, dst)

		fw.eq(dst[1], 10, "dst[1]")
		fw.eq(dst[2], 20, "dst[2]")
		fw.eq(dst[3], 30, "the longer destination kept its tail")
	end)

	fw.it("copies a table that mixes array and hash keys", function()
		local dst = framework:CopyTable({ "first", "second", Size = 10, Icons = { Border = 2 } }, {})

		fw.eq(dst[1], "first", "dst[1]")
		fw.eq(dst[2], "second", "dst[2]")
		fw.eq(dst.Size, 10, "Size")
		fw.eq(dst.Icons.Border, 2, "Icons.Border")
	end)

	fw.it("returns the destination it was handed", function()
		local dst = {}

		fw.eq(framework:CopyTable({ Size = 10 }, dst), dst, "returned instance")
	end)

	fw.it("returns a non-table verbatim from CopyValueOrTable", function()
		fw.eq(framework:CopyValueOrTable(10), 10, "number")
		fw.eq(framework:CopyValueOrTable("red"), "red", "string")
		fw.eq(framework:CopyValueOrTable(false), false, "boolean")
		fw.is_nil(framework:CopyValueOrTable(nil), "nil")
	end)

	fw.it("clones a table from CopyValueOrTable", function()
		local src = { Icons = { Size = 10 } }
		local copy = framework:CopyValueOrTable(src)

		fw.neq(copy, src, "top-level identity")
		fw.neq(copy.Icons, src.Icons, "nested identity")
		fw.eq(copy.Icons.Size, 10, "Icons.Size")
	end)

	fw.it("reverses an array in place and hands back the same table", function()
		local array = { 1, 2, 3, 4 }

		fw.eq(framework:Reverse(array), array, "returned instance")
		fw.eq(array[1], 4, "array[1]")
		fw.eq(array[2], 3, "array[2]")
		fw.eq(array[3], 2, "array[3]")
		fw.eq(array[4], 1, "array[4]")
	end)

	fw.it("leaves the middle element of an odd-length array where it is", function()
		local array = framework:Reverse({ "a", "b", "c" })

		fw.eq(array[1], "c", "array[1]")
		fw.eq(array[2], "b", "array[2]")
		fw.eq(array[3], "a", "array[3]")
	end)

	fw.it("reverses an empty or single-element array without complaint", function()
		fw.eq(#framework:Reverse({}), 0, "empty")
		fw.eq(framework:Reverse({ "only" })[1], "only", "single")
	end)

	fw.it("appends every element of the source onto the destination", function()
		local dst = { 1, 2 }

		framework:Append({ 3, 4 }, dst)

		fw.eq(#dst, 4, "length")
		fw.eq(dst[3], 3, "dst[3]")
		fw.eq(dst[4], 4, "dst[4]")
	end)

	fw.it("appends nothing from an empty source", function()
		local dst = { 1 }

		framework:Append({}, dst)

		fw.eq(#dst, 1, "length")
	end)

	fw.it("appends by reference, so the two arrays share their elements", function()
		local shared = { Name = "Mine" }
		local dst = {}

		framework:Append({ shared }, dst)

		fw.eq(dst[1], shared, "element identity")
	end)
end)
