-- Covers GUI/Compat.lua, the shims that pick a code path from which apis the client has.
-- The mock is a modern client, so older branches run against stand-in textures instead.

local fw = require("TestFramework")
local env = require("Framework")
local harness = require("AddonHarness")
local withGlobal = require("Globals").withGlobal

---A stand-in texture or frame carrying only the named methods, each recording its call.
local function stub(...)
	local self = { Calls = {} }

	for i = 1, select("#", ...) do
		local name = (select(i, ...))

		self[name] = function(_, ...)
			self.Calls[#self.Calls + 1] = { Name = name, Args = { ... } }
		end
	end

	return self
end

local function lastCall(target, name)
	for i = #target.Calls, 1, -1 do
		if target.Calls[i].Name == name then
			return target.Calls[i]
		end
	end
end

local function countCalls(target, name)
	local count = 0

	for _, call in ipairs(target.Calls) do
		if call.Name == name then
			count = count + 1
		end
	end

	return count
end

fw.describe("MiniFramework - graphics compat", function()
	local GUI

	fw.before_each(function()
		GUI = env.Load().Framework.GUI
	end)

	fw.it("fills a modern texture through SetColorTexture", function()
		local texture = stub("SetColorTexture", "SetTexture")

		GUI.SetSolid(texture, 1, 0.5, 0, 0.25)

		local call = lastCall(texture, "SetColorTexture")

		fw.not_nil(call, "SetColorTexture")
		fw.is_nil(lastCall(texture, "SetTexture"), "SetTexture")
		fw.eq(call.Args[1], 1, "r")
		fw.eq(call.Args[2], 0.5, "g")
		fw.eq(call.Args[3], 0, "b")
		fw.eq(call.Args[4], 0.25, "a")
	end)

	fw.it("fills a pre-7.0 texture through SetTexture", function()
		local texture = stub("SetTexture")

		GUI.SetSolid(texture, 1, 0.5, 0, 0.25)

		local call = lastCall(texture, "SetTexture")

		fw.not_nil(call, "SetTexture")
		fw.eq(call.Args[1], 1, "r")
		fw.eq(call.Args[4], 0.25, "a")
	end)

	fw.it("turns pixel snapping off where the client has it", function()
		local texture = stub("SetSnapToPixelGrid", "SetTexelSnappingBias")

		GUI.Unsnap(texture)

		fw.eq(lastCall(texture, "SetSnapToPixelGrid").Args[1], false, "snapping")
		fw.eq(lastCall(texture, "SetTexelSnappingBias").Args[1], 0, "bias")
	end)

	fw.it("leaves a texture alone where snapping cannot be turned off", function()
		local texture = stub("SetTexelSnappingBias")

		fw.no_error(function()
			GUI.Unsnap(texture)
		end, "Unsnap")

		fw.eq(#texture.Calls, 0, "call count")
	end)

	fw.it("shows and hides through SetShown where the client has it", function()
		local frame = stub("SetShown", "Show", "Hide")

		GUI.SetShown(frame, true)
		GUI.SetShown(frame, false)

		fw.eq(countCalls(frame, "SetShown"), 2, "SetShown calls")
		fw.eq(countCalls(frame, "Show"), 0, "Show calls")
		fw.eq(lastCall(frame, "SetShown").Args[1], false, "the last state")
	end)

	fw.it("falls back to Show and Hide on a pre-5.0 client", function()
		local frame = stub("Show", "Hide")

		GUI.SetShown(frame, true)

		fw.eq(countCalls(frame, "Show"), 1, "Show calls")
		fw.eq(countCalls(frame, "Hide"), 0, "Hide calls")

		GUI.SetShown(frame, false)

		fw.eq(countCalls(frame, "Hide"), 1, "Hide calls after hiding")
	end)

	fw.it("calls a method the client has and passes its arguments on", function()
		local frame = stub("SetIgnoreParentScale")

		fw.eq(GUI.TryCall(frame, "SetIgnoreParentScale", true, 7), true, "return")

		local call = lastCall(frame, "SetIgnoreParentScale")

		fw.eq(call.Args[1], true, "first argument")
		fw.eq(call.Args[2], 7, "second argument")
	end)

	fw.it("reports false for a method the client does not have", function()
		local frame = stub()

		fw.eq(GUI.TryCall(frame, "SetIgnoreParentScale", true), false, "return")
		fw.eq(#frame.Calls, 0, "call count")
	end)

	fw.it("reports false for a backdrop on a client without the mixin", function()
		local frame = stub("SetBackdropColor")

		fw.eq(GUI.ApplyBackdrop(frame, {}, 1, 1, 1, 1), false, "return")
		fw.eq(#frame.Calls, 0, "call count")
	end)

	fw.it("applies a backdrop with both its colours", function()
		local frame = stub("SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor")
		local backdrop = { bgFile = "test" }

		fw.eq(GUI.ApplyBackdrop(frame, backdrop, 1, 0, 0, 1, 0, 1, 0, 0.5), true, "return")
		fw.eq(lastCall(frame, "SetBackdrop").Args[1], backdrop, "the backdrop table")
		fw.eq(lastCall(frame, "SetBackdropColor").Args[1], 1, "fill r")
		fw.eq(lastCall(frame, "SetBackdropBorderColor").Args[4], 0.5, "border a")
	end)

	fw.it("skips whichever backdrop colour it was not given", function()
		local frame = stub("SetBackdrop", "SetBackdropColor", "SetBackdropBorderColor")

		GUI.ApplyBackdrop(frame, {}, 1, 0, 0, 1)

		fw.eq(countCalls(frame, "SetBackdropColor"), 1, "fill")
		fw.eq(countCalls(frame, "SetBackdropBorderColor"), 0, "border")

		GUI.ApplyBackdrop(frame, {}, nil, nil, nil, nil, 0, 1, 0, 1)

		fw.eq(countCalls(frame, "SetBackdropColor"), 1, "fill after the border-only call")
		fw.eq(countCalls(frame, "SetBackdropBorderColor"), 1, "border after the border-only call")
	end)

	fw.it("finds a retail checkbox label on .Text", function()
		local label = {}

		fw.eq(GUI.GetCheckboxLabel({ Text = label }), label, "label")
	end)

	fw.it("promotes an older checkbox's .text onto .Text", function()
		local label = {}
		local checkbox = { text = label }

		fw.eq(GUI.GetCheckboxLabel(checkbox), label, "label")
		fw.eq(checkbox.Text, label, "the label was cached on .Text")
	end)

	fw.it("falls back to the font string named after the checkbox", function()
		local label = {}
		local checkbox = {
			GetName = function()
				return "MiniFrameworkTestCheck"
			end,
		}

		withGlobal("MiniFrameworkTestCheckText", label, function()
			fw.eq(GUI.GetCheckboxLabel(checkbox), label, "label")
			fw.eq(checkbox.Text, label, "the label was cached on .Text")
		end)
	end)

	fw.it("returns nothing when a checkbox has no label at all", function()
		fw.is_nil(GUI.GetCheckboxLabel({}), "no name at all")
		fw.is_nil(GUI.GetCheckboxLabel({
			GetName = function()
				return "MiniFrameworkTestUnknownCheck"
			end,
		}), "a name with no font string behind it")
	end)
end)

fw.describe("MiniFramework - gradient tier", function()
	local GUI

	-- The tier is resolved once per load and cached, so every test here needs its own.
	fw.before_each(function()
		GUI = env.Load().Framework.GUI
	end)

	fw.it("uses SetGradient where it takes colour objects", function()
		local texture = stub("SetColorTexture", "SetGradient", "SetGradientAlpha", "SetVertexColor")

		GUI.SetGradientH(texture, 1, 0, 0, 1, 0, 0, 1, 0.5)

		local call = lastCall(texture, "SetGradient")

		fw.is_nil(lastCall(texture, "SetGradientAlpha"), "SetGradientAlpha")
		fw.eq(call.Args[1], "HORIZONTAL", "orientation")
		fw.eq(call.Args[2].r, 1, "first stop r")
		fw.eq(call.Args[3].b, 1, "second stop b")
		fw.eq(call.Args[3].a, 0.5, "second stop a")
	end)

	fw.it("passes VERTICAL for a vertical gradient", function()
		local texture = stub("SetColorTexture", "SetGradient")

		GUI.SetGradientV(texture, 1, 0, 0, 1, 0, 0, 1, 1)

		fw.eq(lastCall(texture, "SetGradient").Args[1], "VERTICAL", "orientation")
	end)

	fw.it("falls back to SetGradientAlpha where SetGradient still takes eight numbers", function()
		local texture = stub("SetColorTexture", "SetGradientAlpha", "SetVertexColor")

		-- A 9.x client has both CreateColor and SetGradient, but SetGradient rejects the
		-- colour objects, which is the whole reason the tier is probed rather than detected.
		texture.SetGradient = function()
			error("SetGradient: expected number, got table")
		end

		GUI.SetGradientH(texture, 1, 0, 0, 1, 0, 0, 1, 0.5)

		local call = lastCall(texture, "SetGradientAlpha")

		fw.not_nil(call, "SetGradientAlpha")
		fw.eq(call.Args[1], "HORIZONTAL", "orientation")
		fw.eq(call.Args[2], 1, "r1")
		fw.eq(call.Args[9], 0.5, "a2")
	end)

	fw.it("falls back to SetGradientAlpha on a client with only that", function()
		local texture = stub("SetColorTexture", "SetGradientAlpha", "SetVertexColor")

		GUI.SetGradientH(texture, 1, 0, 0, 1, 0, 0, 1, 1)

		fw.not_nil(lastCall(texture, "SetGradientAlpha"), "SetGradientAlpha")
		fw.is_nil(lastCall(texture, "SetVertexColor"), "SetVertexColor")
	end)

	fw.it("averages the two stops where the client has no gradient at all", function()
		local texture = stub("SetColorTexture", "SetVertexColor")

		GUI.SetGradientH(texture, 1, 0, 0, 1, 0, 0, 1, 0)

		local call = lastCall(texture, "SetVertexColor")

		fw.eq(call.Args[1], 0.5, "r")
		fw.eq(call.Args[2], 0, "g")
		fw.eq(call.Args[3], 0.5, "b")
		fw.eq(call.Args[4], 0.5, "a")
	end)

	fw.it("resolves the tier once and reuses it for every later texture", function()
		local first = stub("SetColorTexture", "SetGradientAlpha")
		local second = stub("SetColorTexture", "SetGradient", "SetGradientAlpha")

		GUI.SetGradientH(first, 1, 0, 0, 1, 0, 0, 1, 1)
		GUI.SetGradientH(second, 1, 0, 0, 1, 0, 0, 1, 1)

		fw.is_nil(lastCall(second, "SetGradient"), "the modern call was never probed again")
		fw.not_nil(lastCall(second, "SetGradientAlpha"), "SetGradientAlpha")
	end)

	fw.it("tints without repainting the texture's own image", function()
		local texture = stub("SetColorTexture", "SetGradientAlpha")

		GUI.TintGradientH(texture, 1, 0, 0, 1, 0, 0, 1, 1)

		fw.is_nil(lastCall(texture, "SetColorTexture"), "SetColorTexture")
		fw.not_nil(lastCall(texture, "SetGradientAlpha"), "SetGradientAlpha")
	end)
end)

fw.describe("MiniFramework - load-time compat shims", function()
	fw.it("uses the client's own PixelUtil and backdrop template where they exist", function()
		local GUI = env.Load().Framework.GUI

		fw.eq(GUI.Pixel, _G.PixelUtil, "Pixel")
		fw.eq(GUI.BackdropTemplate, "BackdropTemplate", "BackdropTemplate")
	end)

	fw.it("shims the pixel helpers and drops the template on an older client", function()
		env.Load()

		withGlobal("PixelUtil", nil, function()
			withGlobal("BackdropTemplateMixin", nil, function()
				local GUI = harness.LoadXml(env.AddonName, env.XmlPath, { install = false }).Addon.Framework.GUI
				local region = stub("SetWidth", "SetHeight", "SetSize", "SetPoint")

				fw.is_nil(GUI.BackdropTemplate, "BackdropTemplate")
				fw.not_nil(GUI.Pixel, "Pixel")

				GUI.Pixel.SetSize(region, 10, 20)
				GUI.Pixel.SetWidth(region, 30)
				GUI.Pixel.SetHeight(region, 40)
				GUI.Pixel.SetPoint(region, "CENTER", 1, 2)

				fw.eq(lastCall(region, "SetSize").Args[2], 20, "SetSize height")
				fw.eq(lastCall(region, "SetWidth").Args[1], 30, "SetWidth")
				fw.eq(lastCall(region, "SetHeight").Args[1], 40, "SetHeight")
				fw.eq(lastCall(region, "SetPoint").Args[1], "CENTER", "SetPoint")
			end)
		end)
	end)
end)
