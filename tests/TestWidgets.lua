-- Builds one of every widget the framework offers and drives the ones that own state.
--
-- Widgets are the framework's whole reason to exist and none of them are covered by loading
-- the files - a constructor only runs when an addon opens its options panel, which is exactly
-- where a broken one is least convenient to find.

local fw = require("TestFramework")
local env = require("Framework")
local WowMock = require("WowMock")

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

	fw.it("creates a redirect panel whose button runs its click handler", function()
		local clicks = 0

		local redirect = mini:RedirectPanel({
			Parent = panel,
			Version = "1.2.3",
			Message = "Type /thing to open the settings.",
			ButtonText = "Open Settings",
			OnClick = function()
				clicks = clicks + 1
			end,
		})

		fw.not_nil(redirect, "redirect panel")
		fw.not_nil(redirect.Content, "content frame")
		fw.eq(redirect.Title:GetText(), env.AddonName, "the wordmark falls back to the addon name")
		fw.eq(redirect.Version:GetText(), "1.2.3", "the version line")
		fw.eq(redirect.Message:GetText(), "Type /thing to open the settings.", "the message")
		fw.eq(redirect.Anchor, redirect.Button, "the button is what a caller anchors below")

		redirect.Button:Click()

		fw.eq(clicks, 1, "OnClick ran")
	end)

	fw.it("paints the redirect panel wordmark in the title colour", function()
		mini:SetPalette({ TitleText = { r = 0.1, g = 0.2, b = 0.3 } })

		local redirect = mini:RedirectPanel({ Parent = panel, Title = "Branded" })
		local r, g, b = redirect.Title:GetTextColor()

		fw.eq(redirect.Title:GetText(), "Branded", "an explicit title wins over the addon name")
		fw.eq(r, 0.1, "red comes from the palette")
		fw.eq(g, 0.2, "green comes from the palette")
		fw.eq(b, 0.3, "blue comes from the palette")
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

	fw.it("draws the dialog on a texture path the client can resolve", function()
		mini:ShowDialog({ Text = "Are you sure?" })

		local backdrop

		for _, frame in ipairs(WowMock.Frames) do
			local candidate = frame.GetBackdrop and frame:GetBackdrop()

			if candidate and candidate.bgFile then
				backdrop = candidate
			end
		end

		fw.not_nil(backdrop, "the dialog carries a backdrop")

		-- Lua 5.1 drops the backslash from an unknown escape, so a path written with single
		-- backslashes reaches the client as one unresolvable word and the art never loads.
		fw.eq(backdrop.bgFile, "Interface\\Tooltips\\UI-Tooltip-Background", "the background path keeps its separators")
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

fw.describe("MiniFramework - the styling flag", function()
	local mini, panel

	fw.before_each(function()
		mini, panel = env.LoadWithPanel()
	end)

	fw.it("holds one widget kind back while the rest stay styled", function()
		mini:SetCustomStyling(true, { Button = false })

		local button = mini:Button({ Parent = panel, Text = "Add" })

		fw.eq(button.__template, "UIPanelButtonTemplate", "the button kept stock art")
		fw.eq(mini.GUI.IsStyled(nil, "Checkbox"), true, "other kinds still follow the flag")
	end)

	fw.it("lets one widget opt back in over the override", function()
		mini:SetCustomStyling(true, { Button = false })

		local button = mini:Button({ Parent = panel, Text = "Add", CustomStyling = true })

		fw.neq(button.__template, "UIPanelButtonTemplate", "the per-widget option won")
	end)

	fw.it("rejects a widget kind it does not know", function()
		local ok, err = pcall(function()
			mini:SetCustomStyling(true, { Buttons = false })
		end)

		fw.eq(ok, false, "a typo raises rather than silently doing nothing")
		fw.truthy(tostring(err):find("Buttons"), "the message names the bad kind")
	end)

	-- The setter replaces the whole table, so a second bare call is how an addon would lose
	-- overrides it set earlier.
	fw.it("clears overrides left by an earlier call", function()
		mini:SetCustomStyling(true, { Button = false })
		mini:SetCustomStyling(true)

		fw.eq(mini.GUI.IsStyled(nil, "Button"), true, "the override is gone")
	end)
end)

fw.describe("MiniFramework - the panel header extras", function()
	local mini, panel

	fw.before_each(function()
		mini, panel = env.LoadWithPanel()
	end)

	fw.it("puts a section rule under the blurb and hands it back as the anchor", function()
		local header = mini:PanelHeader({
			Parent = panel,
			Description = "Does a thing.",
			Divider = true,
		})

		fw.not_nil(header.Divider, "the rule was built")
		fw.eq(header.Anchor, header.Divider, "controls anchor below the rule, not the blurb")
	end)

	fw.it("labels the rule when given a string", function()
		local header = mini:PanelHeader({ Parent = panel, Divider = "Appearance" })

		fw.eq(header.Divider.Label:GetText(), "APPEARANCE", "the caller's own label")
	end)

	-- A full-width rule has to start at the panel's left edge, which a centred title cannot give.
	fw.it("refuses a rule under a header that is not left aligned", function()
		local ok = pcall(function()
			mini:PanelHeader({ Parent = panel, Point = "TOP", Divider = true })
		end)

		fw.eq(ok, false, "a centred header raises rather than drawing a misplaced rule")
	end)

	fw.it("leaves the anchor on the blurb when no rule was asked for", function()
		local header = mini:PanelHeader({ Parent = panel, Description = "Does a thing." })

		fw.is_nil(header.Divider, "no rule")
		fw.eq(header.Anchor, header.Description, "the blurb is still the anchor")
	end)

	fw.it("builds the reset button in the panel's top right", function()
		local header = mini:PanelHeader({
			Parent = panel,
			Reset = { OnAccept = function() end },
		})

		local point, _, relative, _, y = header.Reset:GetPoint()

		fw.eq(header.Reset:GetText(), "Reset to Defaults", "the standard label")
		fw.eq(point, "TOPRIGHT", "anchored by its own top right corner")
		fw.eq(relative, "TOPRIGHT", "to the panel's top right corner")
		fw.eq(y, -mini.VerticalSpacing, "level with the title")
	end)
end)

---Keeps what ShowConfirm handed the client's prompt.
---@param body fun()
---@return table
local function Capture(body)
	local seen = {}
	local real = StaticPopup_Show

	StaticPopup_Show = function(which, text, _, data)
		seen.Which, seen.Text, seen.Data = which, text, data
	end

	local ok, err = pcall(body)

	StaticPopup_Show = real

	if not ok then
		error(err, 0)
	end

	seen.Popup = StaticPopupDialogs[seen.Which]

	return seen
end

fw.describe("MiniFramework - resetting to defaults", function()
	local mini, panel

	fw.before_each(function()
		mini, panel = env.LoadWithPanel()
	end)

	-- Resetting throws away everything the user configured, so the click must not apply it.
	fw.it("asks before it resets", function()
		local applied = false

		local button = mini:ResetButton({
			Parent = panel,
			OnAccept = function()
				applied = true
			end,
		})

		local seen = Capture(function()
			button:Click()
		end)

		fw.not_nil(seen.Popup, "the click opened the confirmation")
		fw.eq(seen.Popup.button1, "Reset", "labelled the way the sibling addons look for")
		fw.eq(applied, false, "and applied nothing yet")
	end)

	fw.it("asks through the client's own prompt", function()
		local seen = Capture(function()
			mini:ShowConfirm({
				Text = "Sure?",
				OnAccept = function() end,
			})
		end)

		fw.not_nil(seen.Popup, "the prompt was registered with the client")
		fw.eq(seen.Text, "Sure?", "the caller's wording went as an argument")
		fw.eq(seen.Popup.text, "%s", "so a per cent sign in it is not a format specifier")
		fw.eq(seen.Popup.button2, CANCEL or "Cancel", "a way out that is not accepting")
	end)

	-- The sibling addons find the accept button by the wording their reset passes in.
	fw.it("labels the accept button with the caller's wording", function()
		local seen = Capture(function()
			mini:ShowConfirm({
				Text = "Sure?",
				AcceptText = "Reset",
				OnAccept = function() end,
			})
		end)

		fw.eq(seen.Popup.button1, "Reset", "the caller's label")

		seen = Capture(function()
			mini:ShowConfirm({
				Text = "Sure?",
				OnAccept = function() end,
			})
		end)

		fw.eq(seen.Popup.button1, YES or "Yes", "the client's own word when the caller gave none")
	end)

	fw.it("applies the defaults once the confirmation is accepted", function()
		local applied = false

		local seen = Capture(function()
			mini:ShowConfirm({
				Text = "Sure?",
				OnAccept = function()
					applied = true
				end,
			})
		end)

		fw.eq(applied, false, "showing the prompt applied nothing")

		seen.Popup.OnAccept(nil, seen.Data)

		fw.eq(applied, true, "accepting ran the callback")
	end)

	-- The client reads the entry at click time, so a callback left on it would be whichever
	-- was asked for last rather than the one the player is looking at.
	fw.it("keeps each confirmation's callback to itself", function()
		local first, second = false, false

		local one = Capture(function()
			mini:ShowConfirm({
				Text = "First?",
				OnAccept = function()
					first = true
				end,
			})
		end)

		Capture(function()
			mini:ShowConfirm({
				Text = "Second?",
				OnAccept = function()
					second = true
				end,
			})
		end)

		one.Popup.OnAccept(nil, one.Data)

		fw.eq(first, true, "the first prompt ran its own callback")
		fw.eq(second, false, "and not the one asked for after it")
	end)

	fw.it("rejects a confirmation with nothing to accept", function()
		local ok = pcall(function()
			mini:ShowConfirm({ Text = "Sure?" })
		end)

		fw.eq(ok, false, "a dialog whose Yes does nothing is a bug, not a no-op")
	end)
end)

fw.describe("MiniFramework - list rows", function()
	local mini, panel

	fw.before_each(function()
		mini, panel = env.LoadWithPanel()
		mini:SetCustomStyling(true, { Button = false })
	end)

	---@return table[] rows in the order the list laid them out
	local function BuildRows(customStyling)
		local list = mini:List({
			Parent = panel,
			RowWidth = 200,
			RowHeight = 22,
			CustomStyling = customStyling,
			OnRemove = function() end,
		})

		list:SetItems({ "alpha", "beta" })

		return { list.Content:GetChildren() }
	end

	fw.it("backs a styled row with field art, inset from the row's own edges", function()
		local rows = BuildRows()
		local _, _, _, x = rows[1].Text:GetPoint()

		fw.not_nil(rows[1].Field, "the row was given field art")
		fw.eq(x, 10, "the label clears the rounded end")
	end)

	-- A stock gold button on the dark field art reads as two widgets stuck together, and every
	-- addon that uses a list also holds Button back to stock art for its settings panel.
	fw.it("keeps the remove button in step with the row it sits on", function()
		local rows = BuildRows()

		fw.neq(rows[1].Remove.__template, "UIPanelButtonTemplate", "the button follows the row")
	end)

	fw.it("leaves an unstyled row bare", function()
		local rows = BuildRows(false)
		local _, _, _, x = rows[1].Text:GetPoint()

		fw.is_nil(rows[1].Field, "no field art")
		fw.eq(x, 0, "no inset")
		fw.eq(rows[1].Remove.__template, "UIPanelButtonTemplate", "stock button")
	end)

	fw.it("parts styled rows so their field art does not touch", function()
		local rows = BuildRows()
		local _, _, _, _, first = rows[1]:GetPoint()
		local _, _, _, _, second = rows[2]:GetPoint()

		fw.eq(first - second, 24, "one row height plus the gap")
	end)
end)

fw.describe("MiniFramework - label colour", function()
	local mini, panel

	fw.before_each(function()
		mini, panel = env.LoadWithPanel()
	end)

	-- Blizzard's own checkbox label is gold. Every other control label in the framework is white,
	-- and a settings page that mixes the two looks like two addons.
	fw.it("gives a stock checkbox a white label", function()
		mini:SetCustomStyling(false)

		local checkbox = mini:Checkbox({
			Parent = panel,
			LabelText = "Show text",
			GetValue = function()
				return true
			end,
			SetValue = function() end,
		})

		local label = mini.GUI.GetCheckboxLabel(checkbox)

		fw.eq(label:GetFontObject(), "GameFontHighlight", "white, not Blizzard gold")
	end)
end)
