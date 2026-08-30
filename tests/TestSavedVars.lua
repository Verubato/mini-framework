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

	fw.xfail("drops every entry of a user-authored list on reset, not just its scalars", function()
		-- Desired: a reset should remove a list entry entirely, the way it drops any other
		-- key the defaults no longer describe, instead of leaving an empty stub behind.
		local vars = framework:GetSavedVars({ Groups = {} })

		vars.Groups[1] = { Name = "Mine" }

		framework:ResetSavedVars({ Groups = {} })

		fw.eq(#vars.Groups, 0, "the entry was removed")
	end)

	fw.xfail("publishes the global when a reset runs before anything was saved", function()
		-- Desired: a reset should publish _G like GetSavedVars does, so the table it hands
		-- back is the same one a later get returns instead of a second orphan.
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
