-- Builds one of every widget the framework offers and drives the ones that own state.
--
-- Widgets are the framework's whole reason to exist and none of them are covered by loading
-- the files - a constructor only runs when an addon opens its options panel, which is exactly
-- where a broken one is least convenient to find.

local fw = require("TestFramework")
local env = require("Framework")

fw.describe("MiniFramework - widgets", function()
	local mini, panel

	fw.before_each(function()
		mini, panel = env.LoadWithPanel()
	end)

	fw.it("creates a checkbox bound to its getter and setter", function()
		local get, set, state = env.Binding(true)

		local checkbox = mini:Checkbox({
			Parent = panel,
			LabelText = "Enabled",
			GetValue = get,
			SetValue = set,
		})

		fw.not_nil(checkbox, "checkbox")
		fw.eq(checkbox:GetChecked(), true, "initial state comes from GetValue")

		-- Click through the widget rather than calling the setter, so the OnClick wiring is
		-- what's under test.
		checkbox:SetChecked(false)
		checkbox:Click()

		fw.eq(state.Value, false, "clicking wrote through to SetValue")
	end)

	fw.it("creates a styled toggle bound to its getter and setter", function()
		local get, set, state = env.Binding(false)

		local toggle = mini:Checkbox({
			Parent = panel,
			LabelText = "Enabled",
			Tooltip = "Turns it on.",
			CustomStyling = true,
			GetValue = get,
			SetValue = set,
		})

		fw.not_nil(toggle, "toggle")
		fw.not_nil(toggle.Knob, "toggle knob")
		fw.not_nil(toggle.Fill, "toggle fill")
		fw.eq(toggle:GetChecked(), false, "initial state comes from GetValue")
		fw.eq(toggle.__progress, 0, "the slide starts at the off end")

		toggle:Click()

		fw.eq(state.Value, true, "clicking wrote through to SetValue")
		fw.eq(toggle:GetChecked(), true, "the button state followed")

		-- One tick longer than the slide, so the animation lands and unhooks itself.
		env.Mock.RunOnUpdate(0.2)

		fw.eq(toggle.__progress, 1, "the slide finished at the on end")
	end)

	fw.it("takes the accent out of a disabled toggle and restores it", function()
		local get, set = env.Binding(true)

		local toggle = mini:Checkbox({
			Parent = panel,
			LabelText = "Enabled",
			CustomStyling = true,
			GetValue = get,
			SetValue = set,
		})

		-- The mock's Disable does not fire OnDisable the way the client does, so drive the
		-- handlers directly.
		toggle:GetScript("OnDisable")(toggle)

		fw.eq(toggle:GetAlpha(), 0.3, "disabling dims the whole control")
		fw.neq(toggle.__fillColor, mini.GUI.Accent, "disabling swaps the fill off the accent")

		toggle:GetScript("OnEnable")(toggle)

		fw.eq(toggle:GetAlpha(), 1, "enabling restores the full alpha")
		fw.eq(toggle.__fillColor, mini.GUI.Accent, "enabling restores the accent fill")
	end)

	fw.it("snaps a styled toggle when its value changes from outside", function()
		local get, set, state = env.Binding(true)

		local toggle = mini:Checkbox({
			Parent = panel,
			LabelText = "Enabled",
			CustomStyling = true,
			GetValue = get,
			SetValue = set,
		})

		fw.eq(toggle.__progress, 1, "the slide starts at the on end")

		state.Value = false
		toggle.MiniRefresh()

		fw.eq(toggle:GetChecked(), false, "refresh re-read the source")
		fw.eq(toggle.__progress, 0, "the visuals snapped with it")
	end)

	fw.it("creates a slider inside its bounds", function()
		local get, set = env.Binding(5)

		-- Slider hands back the trio it builds: the slider itself, its numeric box and label.
		local built = mini:Slider({
			Parent = panel,
			LabelText = "Size",
			Min = 1,
			Max = 10,
			Step = 1,
			GetValue = get,
			SetValue = set,
		})

		fw.not_nil(built, "slider")
		fw.not_nil(built.Slider, "slider frame")
		fw.not_nil(built.EditBox, "slider edit box")
		fw.not_nil(built.Label, "slider label")

		local slider = built.Slider
		local min, max = slider:GetMinMaxValues()

		fw.eq(min, 1, "min")
		fw.eq(max, 10, "max")
		fw.eq(slider:GetValue(), 5, "initial value comes from GetValue")
	end)

	fw.it("creates a styled slider with the shared circle thumb", function()
		local get, set = env.Binding(5)

		local built = mini:Slider({
			Parent = panel,
			LabelText = "Size",
			Min = 1,
			Max = 10,
			Step = 1,
			CustomStyling = true,
			GetValue = get,
			SetValue = set,
		})

		fw.not_nil(built.Slider, "styled slider frame")
		fw.not_nil(built.Slider:GetThumbTexture(), "thumb texture")
		fw.eq(built.Slider:GetValue(), 5, "initial value comes from GetValue")
	end)

	fw.it("creates a styled dropdown with a soft-cornered face", function()
		local get, set = env.Binding("b")

		local dropdown = mini:Dropdown({
			Parent = panel,
			LabelText = "Mode",
			Items = { "a", "b", "c" },
			CustomStyling = true,
			GetValue = get,
			SetValue = set,
		})

		fw.not_nil(dropdown, "styled dropdown")
		fw.not_nil(dropdown.Field, "rounded face")
		fw.not_nil(dropdown.Field.Fill, "face fill")
		fw.not_nil(dropdown.Field.Border, "face border")
		fw.not_nil(dropdown.Chevron, "own chevron texture")
	end)

	fw.it("creates a dropdown over its items", function()
		local get, set = env.Binding("b")

		local dropdown = mini:Dropdown({
			Parent = panel,
			LabelText = "Mode",
			Items = { "a", "b", "c" },
			GetValue = get,
			SetValue = set,
		})

		fw.not_nil(dropdown, "dropdown")
	end)

	fw.it("creates an edit box bound to its getter and setter", function()
		local get, set = env.Binding("hello")

		local box = mini:EditBox({
			Parent = panel,
			LabelText = "Name",
			GetValue = get,
			SetValue = set,
		})

		fw.not_nil(box, "edit box")
	end)

	fw.it("creates a read-only edit box without a setter", function()
		local get = env.Binding("read me")

		local box = mini:EditBox({
			Parent = panel,
			LabelText = "Export",
			Readonly = true,
			GetValue = get,
		})

		fw.not_nil(box, "read-only edit box")
	end)

	fw.it("creates a colour swatch bound to its getter and setter", function()
		local get, set = env.Binding({ R = 1, G = 0, B = 0, A = 1 })

		local swatch = mini:ColorSwatch({
			Parent = panel,
			LabelText = "Colour",
			GetValue = get,
			SetValue = set,
		})

		fw.not_nil(swatch, "swatch")
	end)

	fw.it("creates a button that runs its click handler", function()
		local clicks = 0

		local button = mini:Button({
			Parent = panel,
			Text = "Reset",
			OnClick = function()
				clicks = clicks + 1
			end,
		})

		fw.not_nil(button, "button")

		button:Click()

		fw.eq(clicks, 1, "OnClick ran")
	end)

	fw.it("creates the static widgets", function()
		fw.not_nil(mini:TextLine({ Parent = panel, Text = "A line" }), "text line")
		fw.not_nil(mini:TextBlock({ Parent = panel, Lines = { "First line", "Second line" } }), "text block")
		fw.not_nil(mini:Divider({ Parent = panel }), "divider")
		fw.not_nil(mini:PanelHeader({ Parent = panel, Title = "Title" }), "panel header")
	end)

	fw.it("creates a scrolling list", function()
		local list = mini:List({
			Parent = panel,
			RowWidth = 200,
			RowHeight = 20,
		})

		fw.not_nil(list, "list")
	end)

	fw.it("creates a tab strip", function()
		local tabs = mini:CreateTabs({
			Parent = panel,
			Tabs = { { Key = "general", Text = "General" }, { Key = "advanced", Text = "Advanced" } },
		})

		fw.not_nil(tabs, "tabs")
	end)

	fw.it("creates a bare tab strip and reports the selection", function()
		local picked
		local strip = mini:TabStrip({
			Parent = panel,
			Tabs = { { Key = "trigger", Title = "Trigger" }, { Key = "look", Title = "Look" } },
			OnSelect = function(key)
				picked = key
			end,
		})

		fw.not_nil(strip, "strip")
		fw.eq(strip.GetSelected(), "trigger", "the first tab starts selected")
		fw.eq(#strip.Buttons, 2, "one button per tab")

		strip:Select("look")

		fw.eq(strip.GetSelected(), "look", "selecting moves it")
		fw.eq(picked, "look", "and reports the key")
	end)

	fw.it("honours an initial tab and ignores a key it does not have", function()
		local strip = mini:TabStrip({
			Parent = panel,
			Tabs = { { Key = "one" }, { Key = "two" } },
			InitialKey = "two",
		})

		fw.eq(strip.GetSelected(), "two", "starts where it was told to")

		strip:Select("nope")

		fw.eq(strip.GetSelected(), "two", "an unknown key changes nothing")
	end)

	fw.it("creates a standalone window", function()
		local window = mini:CreateStandaloneWindow({
			Parent = _G.UIParent,
			Title = "Profiles",
			Width = 400,
			Height = 300,
		})

		fw.not_nil(window, "window")
	end)

	fw.it("shows and hides a dialog", function()
		mini:ShowDialog({
			Text = "Are you sure?",
			OnAccept = function() end,
		})

		mini:HideDialog()
	end)
end)

fw.describe("MiniFramework - saved variables", function()
	local mini

	fw.before_each(function()
		-- Each case starts from a client that has never seen this addon before.
		_G[env.AddonName .. "DB"] = nil
		_G[env.AddonName .. "CharDB"] = nil

		mini = env.Load().Framework
	end)

	fw.it("creates the account-wide table and fills in defaults", function()
		local db = mini:GetSavedVars({ Enabled = true, Size = 10 })

		fw.eq(db.Enabled, true, "Enabled default")
		fw.eq(db.Size, 10, "Size default")
		fw.eq(_G[env.AddonName .. "DB"], db, "the global points at the same table")
	end)

	fw.it("keeps a stored value and only fills in what is missing", function()
		local first = mini:GetSavedVars({ Enabled = true, Size = 10 })

		first.Size = 42

		local second = mini:GetSavedVars({ Enabled = true, Size = 10, Colour = "red" })

		fw.eq(second.Size, 42, "the stored value survives")
		fw.eq(second.Colour, "red", "the new default is added")
	end)

	fw.it("creates a separate per-character table", function()
		local account = mini:GetSavedVars({ Scope = "account" })
		local character = mini:GetCharacterSavedVars({ Scope = "character" })

		fw.neq(account, character, "the two tables are distinct")
		fw.eq(character.Scope, "character", "per-character default")
	end)

	fw.it("resets in place so existing references stay valid", function()
		local db = mini:GetSavedVars({ Size = 10 })

		db.Size = 99

		local reset = mini:ResetSavedVars({ Size = 10 })

		fw.eq(reset, db, "the same table instance comes back")
		fw.eq(db.Size, 10, "the value went back to its default")
	end)
end)
