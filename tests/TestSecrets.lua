-- Covers Secrets.lua. These swap the global to reach the secret branch every guard in the
-- fleet has otherwise never taken.

local fw = require("TestFramework")
local env = require("Framework")
local harness = require("AddonHarness")
local withGlobal = require("Globals").withGlobal

fw.describe("MiniFramework - secret values", function()
	local framework

	fw.before_each(function()
		framework = env.Load().Framework
	end)

	fw.it("reports a secret value as secret and a plain one as not", function()
		-- Hand-rolls what WowMock.MakeSecret now provides; switch to it once build/ bumps.
		local secret = {}

		withGlobal("issecretvalue", function(value)
			return value == secret
		end, function()
			fw.truthy(framework:IsSecret(secret), "the secret value")
			fw.falsy(framework:IsSecret(5), "a number")
			fw.falsy(framework:IsSecret("text"), "a string")
			fw.falsy(framework:IsSecret(nil), "nil")
			fw.falsy(framework:IsSecret({}), "some other table")
		end)
	end)

	fw.it("reports nothing as secret on the harness client", function()
		fw.falsy(framework:IsSecret({}), "a table")
		fw.falsy(framework:IsSecret(5), "a number")
	end)

	fw.it("says the client has secrets when it has the predicate", function()
		withGlobal("issecretvalue", function() return false end, function()
			fw.truthy(framework:HasSecrets(), "HasSecrets")
			fw.falsy(framework:CanOpenOptionsDuringCombat(), "and locks the options in combat")
		end)
	end)

	fw.it("says no on a client without the predicate", function()
		withGlobal("issecretvalue", nil, function()
			fw.falsy(framework:HasSecrets(), "HasSecrets")
			fw.truthy(framework:CanOpenOptionsDuringCombat(), "and still opens the options in combat")
		end)
	end)

	fw.it("ignores the expansion level, since a Classic client can carry the 12.x interface", function()
		withGlobal("issecretvalue", function() return false end, function()
			withGlobal("LE_EXPANSION_LEVEL_CURRENT", _G.LE_EXPANSION_CLASSIC or 0, function()
				fw.truthy(framework:HasSecrets(), "HasSecrets")
			end)
		end)
	end)

	fw.it("says no on a Classic project that carries the predicate without the interface", function()
		withGlobal("issecretvalue", function() return false end, function()
			withGlobal("WOW_PROJECT_ID", _G.WOW_PROJECT_MISTS_CLASSIC, function()
				fw.falsy(framework:HasSecrets(), "HasSecrets")
			end)
		end)
	end)

	fw.it("answers false for everything on a client without the predicate", function()
		-- IsSecret is bound at load, so the fallback branch only exists in a framework that
		-- loaded against a client with no issecretvalue at all.
		env.Load()

		withGlobal("issecretvalue", nil, function()
			local context = harness.LoadXml(env.AddonName, env.XmlPath, { install = false })
			local older = context.Addon.Framework

			fw.eq(type(older.IsSecret), "function", "IsSecret")
			fw.falsy(older:IsSecret({}), "a table")
			fw.falsy(older:IsSecret(5), "a number")
		end)
	end)
end)
