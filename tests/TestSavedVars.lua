-- Covers SavedVars.lua past the basics TestWidgets already pins: the merge and reset cases
-- where getting it wrong silently eats a user's settings on the next login.

local fw = require("TestFramework")
local env = require("Framework")

local DB = env.AddonName .. "DB"
local CHAR_DB = env.AddonName .. "CharDB"

fw.describe("MiniFramework - saved variable merging", function()
	local framework

	fw.before_each(function()
		-- Each case starts from a client that has never seen this addon before.
		_G[DB] = nil
		_G[CHAR_DB] = nil

		framework = env.Load().Framework
	end)

	fw.it("keeps a saved value that is false rather than treating it as missing", function()
		_G[DB] = { Enabled = false }

		fw.eq(framework:GetSavedVars({ Enabled = true }).Enabled, false, "Enabled")
	end)

	fw.it("hands back the same instance every call", function()
		local first = framework:GetSavedVars({ Size = 10 })
		local second = framework:GetSavedVars({ Size = 10 })

		fw.eq(first, second, "instance")
	end)

	fw.it("returns a bare table when there are no defaults", function()
		local vars = framework:GetSavedVars()

		fw.eq(type(vars), "table", "type")
		fw.is_nil(next(vars), "the table is empty")
		fw.eq(_G[DB], vars, "the global was still published")
	end)

	fw.it("clones nested defaults so the defaults table cannot be edited through them", function()
		local defaults = { Icons = { Size = 10 } }
		local vars = framework:GetSavedVars(defaults)

		vars.Icons.Size = 99

		fw.eq(defaults.Icons.Size, 10, "the defaults table stayed put")
	end)

	fw.it("adds a nested default a previously saved table has never seen", function()
		_G[DB] = { Icons = { Size = 99 } }

		local vars = framework:GetSavedVars({ Icons = { Size = 10, Border = 2 } })

		fw.eq(vars.Icons.Size, 99, "the saved nested value survived")
		fw.eq(vars.Icons.Border, 2, "the new nested default was filled in")
	end)

	fw.it("replaces a saved scalar where the default is a table", function()
		_G[DB] = { Icons = "nonsense" }

		local vars = framework:GetSavedVars({ Icons = { Size = 10 } })

		fw.eq(type(vars.Icons), "table", "Icons type")
		fw.eq(vars.Icons.Size, 10, "Icons.Size")
	end)

	fw.it("keeps a saved table where the default is a scalar", function()
		-- The opposite type mismatch is not repaired, so a default that changed from a table
		-- to a scalar leaves the old shape behind for the addon to read.
		_G[DB] = { Icons = { Size = 99 } }

		fw.eq(type(framework:GetSavedVars({ Icons = 10 }).Icons), "table", "Icons type")
	end)

	fw.it("merges defaults into the per-character table the same way", function()
		_G[CHAR_DB] = { Size = 99 }

		local vars = framework:GetCharacterSavedVars({ Size = 10, Enabled = true })

		fw.eq(vars.Size, 99, "the saved value survived")
		fw.eq(vars.Enabled, true, "the new default was filled in")
		fw.eq(_G[CHAR_DB], vars, "the per-character global is the same instance")
	end)

	fw.it("returns a bare per-character table when there are no defaults", function()
		local vars = framework:GetCharacterSavedVars()

		fw.eq(type(vars), "table", "type")
		fw.eq(_G[CHAR_DB], vars, "the global was published")
	end)

	fw.it("drops a key the defaults no longer describe on reset", function()
		local vars = framework:GetSavedVars({ Size = 10 })

		vars.Retired = true

		framework:ResetSavedVars({ Size = 10 })

		fw.is_nil(vars.Retired, "Retired")
	end)

	fw.it("empties a nested table on reset and refills it from the defaults", function()
		local vars = framework:GetSavedVars({ Icons = { Size = 10 } })

		vars.Icons.Size = 99
		vars.Icons.Retired = true

		framework:ResetSavedVars({ Icons = { Size = 10 } })

		fw.eq(vars.Icons.Size, 10, "Icons.Size")
		fw.is_nil(vars.Icons.Retired, "Icons.Retired")
	end)

	fw.it("keeps every entry of a user-authored list on reset, fields and all", function()
		local vars = framework:GetSavedVars({ Groups = {} })

		vars.Groups[1] = { Name = "Mine" }

		framework:ResetSavedVars({ Groups = {} })

		fw.eq(#vars.Groups, 1, "the entry is still there")
		fw.eq(vars.Groups[1].Name, "Mine", "Groups[1].Name")
	end)

	fw.it("drops a nested table the defaults no longer describe on reset", function()
		local vars = framework:GetSavedVars({ Icons = { Size = 10 } })

		vars.Retired = { Size = 99 }

		framework:ResetSavedVars({ Icons = { Size = 10 } })

		fw.is_nil(vars.Retired, "Retired")
	end)

	fw.it("keeps a nested table's identity across a reset", function()
		local vars = framework:GetSavedVars({ Icons = { Size = 10 } })
		local icons = vars.Icons

		vars.Icons.Size = 99

		framework:ResetSavedVars({ Icons = { Size = 10 } })

		fw.eq(vars.Icons, icons, "the same nested instance came back")
		fw.eq(icons.Size, 10, "Icons.Size")
	end)

	fw.it("puts a false default back over a value the user chose", function()
		-- A false default stands for "unset", so a reset has to reach the value behind it.
		local vars = framework:GetSavedVars({ Font = false })

		vars.Font = "Friz Quadrata"

		framework:ResetSavedVars({ Font = false })

		fw.eq(vars.Font, false, "Font")
	end)

	fw.it("publishes the global when a reset runs before anything was saved", function()
		local vars = framework:ResetSavedVars({ Size = 10 })

		fw.eq(vars.Size, 10, "the defaults were merged in")
		fw.eq(_G[DB], vars, "the global was published")
		fw.eq(framework:GetSavedVars({ Size = 10 }), vars, "a later get returns the same table")
	end)

	fw.it("clears everything when a reset is given no defaults", function()
		local vars = framework:GetSavedVars({ Size = 10, Enabled = true })

		framework:ResetSavedVars()

		fw.is_nil(next(vars), "the table is empty")
	end)
end)
