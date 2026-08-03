-- Loads every framework file in MiniFramework.xml order and checks the namespace it publishes.

local fw = require("TestFramework")
local env = require("Framework")

fw.describe("MiniFramework - smoke test", function()
	local context

	fw.it("loads every file MiniFramework.xml lists", function()
		context = env.Load()

		fw.truthy(#context.Loaded > 0, "the xml loaded no files")
	end)

	fw.it("publishes the framework on the addon namespace", function()
		fw.not_nil(context, "load must succeed first")
		fw.not_nil(context.Framework, "addon.Framework")
		fw.eq(type(context.Framework.Version), "string", "Version")
	end)

	fw.it("exposes every public entry point", function()
		local framework = context.Framework

		-- The surface consuming addons are written against. A rename here breaks all of them
		-- at once, and only at the moment the user opens that addon's options.
		local expected = {
			"Notify",
			"NotifyCombatLockdown",
			"CopyTable",
			"CleanTable",
			"GetSavedVars",
			"GetCharacterSavedVars",
			"ResetSavedVars",
			"WaitForAddonLoad",
			"AddCategory",
			"AddSubCategory",
			"RegisterSlashCommand",
			"OpenSettings",
			"SettingsSize",
			"ColumnWidth",
			"Checkbox",
			"Slider",
			"Dropdown",
			"Button",
			"EditBox",
			"ColorSwatch",
			"List",
			"TextLine",
			"TextBlock",
			"Divider",
			"PanelHeader",
			"CreateTabs",
			"CreateStandaloneWindow",
			"ShowDialog",
			"HideDialog",
		}

		for _, name in ipairs(expected) do
			fw.eq(type(framework[name]), "function", "framework:" .. name)
		end
	end)

	fw.it("falls back to the English key for an untranslated string", function()
		-- The localisation shim resolves through addon.L, which a bare framework has none of.
		fw.eq(context.Framework.L["Some untranslated string"], "Some untranslated string", "L fallback")
	end)

	fw.it("loads a second time into a clean client", function()
		local second = env.Load()

		fw.eq(#second.Loaded, #context.Loaded, "second load file count")
		fw.not_nil(second.Framework, "addon.Framework on the second load")
	end)
end)
