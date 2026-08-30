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

	fw.it("says the client has no secrets before Midnight", function()
		withGlobal("LE_EXPANSION_LEVEL_CURRENT", _G.LE_EXPANSION_MIDNIGHT - 1, function()
			fw.falsy(framework:HasSecrets(), "HasSecrets")
		end)
	end)

	fw.it("says the client has secrets from Midnight on", function()
		withGlobal("LE_EXPANSION_LEVEL_CURRENT", _G.LE_EXPANSION_MIDNIGHT, function()
			fw.truthy(framework:HasSecrets(), "at Midnight")
		end)

		withGlobal("LE_EXPANSION_LEVEL_CURRENT", _G.LE_EXPANSION_MIDNIGHT + 1, function()
			fw.truthy(framework:HasSecrets(), "past Midnight")
		end)
	end)

	fw.it("says no on a client that has never heard of Midnight", function()
		withGlobal("LE_EXPANSION_MIDNIGHT", nil, function()
			fw.falsy(framework:HasSecrets(), "HasSecrets")
		end)
	end)

	fw.it("says no on a client with no expansion constants at all", function()
		withGlobal("LE_EXPANSION_LEVEL_CURRENT", nil, function()
			withGlobal("LE_EXPANSION_MIDNIGHT", nil, function()
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
