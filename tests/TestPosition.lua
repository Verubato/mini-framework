-- Covers Position.lua. A saved anchor is written to a Lua file and read back a session later,
-- so the round trip and the fallbacks for anything missing from it are what matter.

local fw = require("TestFramework")
local env = require("Framework")

fw.describe("MiniFramework - frame position", function()
	local framework

	fw.before_each(function()
		framework = env.Load().Framework
	end)

	fw.it("round trips a saved anchor onto another frame", function()
		local anchor = _G.CreateFrame("Frame", "MiniFrameworkTestAnchor", _G.UIParent)
		local source = _G.CreateFrame("Frame", nil, _G.UIParent)
		local position = {}

		source:SetPoint("TOPLEFT", anchor, "BOTTOMRIGHT", 12, -34)
		framework:SavePosition(source, position)

		fw.eq(position.Point, "TOPLEFT", "Point")
		fw.eq(position.RelativeTo, "MiniFrameworkTestAnchor", "RelativeTo")
		fw.eq(position.RelativePoint, "BOTTOMRIGHT", "RelativePoint")
		fw.eq(position.X, 12, "X")
		fw.eq(position.Y, -34, "Y")

		local restored = _G.CreateFrame("Frame", nil, _G.UIParent)

		framework:ApplyPosition(restored, position)

		local point, relativeTo, relativePoint, x, y = restored:GetPoint(1)

		fw.eq(point, "TOPLEFT", "restored Point")
		fw.eq(relativeTo, anchor, "restored RelativeTo")
		fw.eq(relativePoint, "BOTTOMRIGHT", "restored RelativePoint")
		fw.eq(x, 12, "restored X")
		fw.eq(y, -34, "restored Y")
	end)

	fw.it("saves the frame name rather than the frame itself", function()
		local anchor = _G.CreateFrame("Frame", "MiniFrameworkTestNamedAnchor", _G.UIParent)
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)
		local position = {}

		frame:SetPoint("CENTER", anchor, "CENTER", 0, 0)
		framework:SavePosition(frame, position)

		fw.eq(type(position.RelativeTo), "string", "RelativeTo type")
	end)

	fw.it("names UIParent when the anchor has no relative frame", function()
		local frame = _G.CreateFrame("Frame")
		local position = {}

		frame:SetPoint("CENTER", 5, 10)
		framework:SavePosition(frame, position)

		fw.eq(position.RelativeTo, "UIParent", "RelativeTo")
	end)

	fw.it("clears the old anchors before applying a new one", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		frame:SetPoint("TOPLEFT", _G.UIParent, "TOPLEFT", 1, 1)
		framework:ApplyPosition(frame, { Point = "BOTTOM", RelativePoint = "BOTTOM", X = 0, Y = 0 })

		fw.eq(frame:GetNumPoints(), 1, "point count")
		fw.eq(frame:GetPoint(1), "BOTTOM", "Point")
	end)

	fw.it("falls back to UIParent when the saved frame is gone", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		framework:ApplyPosition(frame, {
			Point = "TOP",
			RelativeTo = "SomeFrameFromAnAddonThatIsNowDisabled",
			RelativePoint = "BOTTOM",
			X = 1,
			Y = 2,
		})

		local point, relativeTo, relativePoint = frame:GetPoint(1)

		fw.eq(point, "TOP", "Point")
		fw.eq(relativeTo, _G.UIParent, "RelativeTo")
		fw.eq(relativePoint, "BOTTOM", "RelativePoint")
	end)

	fw.it("centres on UIParent when nothing was saved", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		framework:ApplyPosition(frame, {})

		local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)

		fw.eq(point, "CENTER", "Point")
		fw.eq(relativeTo, _G.UIParent, "RelativeTo")
		fw.eq(relativePoint, "CENTER", "RelativePoint")
		fw.eq(x, 0, "X")
		fw.eq(y, 0, "Y")
	end)

	fw.it("fills each missing field from the defaults", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		framework:ApplyPosition(frame, {}, { Point = "TOPRIGHT", RelativePoint = "BOTTOMLEFT", X = 7, Y = 8 })

		local point, _, relativePoint, x, y = frame:GetPoint(1)

		fw.eq(point, "TOPRIGHT", "Point")
		fw.eq(relativePoint, "BOTTOMLEFT", "RelativePoint")
		fw.eq(x, 7, "X")
		fw.eq(y, 8, "Y")
	end)

	fw.it("prefers the saved value over the default", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		framework:ApplyPosition(frame, { Point = "LEFT", X = 1 }, { Point = "TOPRIGHT", X = 7, Y = 8 })

		local point, _, relativePoint, x, y = frame:GetPoint(1)

		fw.eq(point, "LEFT", "Point")
		fw.eq(relativePoint, "LEFT", "an absent relative point mirrors the point")
		fw.eq(x, 1, "X")
		fw.eq(y, 8, "Y")
	end)

	fw.it("reads offsets that were saved as strings", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		framework:ApplyPosition(frame, { Point = "CENTER", X = "12", Y = "-34" })

		local _, _, _, x, y = frame:GetPoint(1)

		fw.eq(x, 12, "X")
		fw.eq(y, -34, "Y")
	end)

	fw.it("errors when a frame or position is missing", function()
		local position = {}
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		fw.falsy(pcall(framework.SavePosition, framework, nil, position), "SavePosition without a frame")
		fw.falsy(pcall(framework.SavePosition, framework, frame, nil), "SavePosition without a position")
		fw.falsy(pcall(framework.ApplyPosition, framework, nil, position), "ApplyPosition without a frame")
		fw.falsy(pcall(framework.ApplyPosition, framework, frame, nil), "ApplyPosition without a position")
		fw.falsy(pcall(framework.SetPositionLocked, framework, nil, true), "SetPositionLocked without a frame")
		fw.falsy(pcall(framework.MakeMovable, framework, nil, position), "MakeMovable without a frame")
		fw.falsy(pcall(framework.MakeMovable, framework, frame, nil), "MakeMovable without a position")
	end)

	fw.it("takes movement and the mouse away from a locked frame, and gives them back", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		framework:SetPositionLocked(frame, true)

		fw.falsy(frame:IsMovable(), "movable while locked")
		fw.falsy(frame:IsMouseEnabled(), "mouse enabled while locked")

		framework:SetPositionLocked(frame, false)

		fw.truthy(frame:IsMovable(), "movable once unlocked")
		fw.truthy(frame:IsMouseEnabled(), "mouse enabled once unlocked")
	end)

	fw.it("makes a frame movable and mouse enabled", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)

		framework:MakeMovable(frame, {})

		fw.truthy(frame:IsMovable(), "movable")
		fw.truthy(frame:IsMouseEnabled(), "mouse enabled")
		fw.not_nil(frame:GetScript("OnDragStart"), "OnDragStart")
		fw.not_nil(frame:GetScript("OnDragStop"), "OnDragStop")
	end)

	fw.it("saves where the frame landed and reports the move", function()
		local anchor = _G.CreateFrame("Frame", "MiniFrameworkTestDropAnchor", _G.UIParent)
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)
		local position = {}
		local moved = 0

		framework:MakeMovable(frame, position, {
			OnMoved = function()
				moved = moved + 1
			end,
		})

		frame:SetPoint("BOTTOMRIGHT", anchor, "TOPLEFT", 3, 4)
		frame:GetScript("OnDragStop")(frame)

		fw.eq(position.Point, "BOTTOMRIGHT", "Point")
		fw.eq(position.RelativeTo, "MiniFrameworkTestDropAnchor", "RelativeTo")
		fw.eq(position.X, 3, "X")
		fw.eq(position.Y, 4, "Y")
		fw.eq(moved, 1, "OnMoved calls")
	end)

	fw.it("does not start a drag while the frame is locked", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)
		local started = false

		-- Shadow the mock's no-op so the drag start is observable.
		frame.StartMoving = function()
			started = true
		end

		framework:MakeMovable(frame, {}, {
			IsLocked = function()
				return true
			end,
		})

		frame:GetScript("OnDragStart")(frame)

		fw.falsy(started, "the drag started")
		fw.falsy(frame:IsMovable(), "the lock was applied up front")
	end)

	fw.it("starts a drag once the lock is off", function()
		local frame = _G.CreateFrame("Frame", nil, _G.UIParent)
		local started = false
		local locked = true

		frame.StartMoving = function()
			started = true
		end

		framework:MakeMovable(frame, {}, {
			IsLocked = function()
				return locked
			end,
		})

		locked = false
		frame:GetScript("OnDragStart")(frame)

		fw.truthy(started, "the drag started")
	end)
end)
