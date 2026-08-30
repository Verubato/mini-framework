-- Covers Combat.lua, which holds protected work until the lockdown lifts. Work that is
-- dropped or run twice here shows up as a setting that silently never applied.

local fw = require("TestFramework")
local env = require("Framework")
local WowMock = require("WowMock")

local function leaveCombat()
	WowMock.State.InCombat = false
	WowMock.FireEvent("PLAYER_REGEN_ENABLED")
end

fw.describe("MiniFramework - deferred combat work", function()
	local framework

	fw.before_each(function()
		framework = env.Load().Framework
		WowMock.State.InCombat = false
	end)

	fw.it("runs the callback straight away outside combat", function()
		local runs = 0

		framework:RunWhenCombatEnds(function()
			runs = runs + 1
		end)

		fw.eq(runs, 1, "runs")
		fw.falsy(framework:HasPendingCombatWork(), "nothing was left pending")
	end)

	fw.it("holds the callback until combat ends", function()
		local runs = 0

		WowMock.State.InCombat = true

		framework:RunWhenCombatEnds(function()
			runs = runs + 1
		end)

		fw.eq(runs, 0, "the callback did not run in combat")
		fw.truthy(framework:HasPendingCombatWork(), "work is pending")

		leaveCombat()

		fw.eq(runs, 1, "the callback ran on leaving combat")
		fw.falsy(framework:HasPendingCombatWork(), "the queue was drained")
	end)

	fw.it("runs every unkeyed callback once, in the order they were queued", function()
		local order = {}

		WowMock.State.InCombat = true

		framework:RunWhenCombatEnds(function()
			order[#order + 1] = "first"
		end)
		framework:RunWhenCombatEnds(function()
			order[#order + 1] = "second"
		end)

		leaveCombat()

		fw.eq(#order, 2, "count")
		fw.eq(order[1], "first", "order[1]")
		fw.eq(order[2], "second", "order[2]")
	end)

	fw.it("keeps only the newest callback for a key", function()
		local ran = {}

		WowMock.State.InCombat = true

		framework:RunWhenCombatEnds(function()
			ran[#ran + 1] = "stale"
		end, "Layout")
		framework:RunWhenCombatEnds(function()
			ran[#ran + 1] = "newest"
		end, "Layout")

		leaveCombat()

		fw.eq(#ran, 1, "one callback ran")
		fw.eq(ran[1], "newest", "which callback ran")
	end)

	fw.it("keeps callbacks under different keys apart", function()
		local runs = 0

		WowMock.State.InCombat = true

		framework:RunWhenCombatEnds(function()
			runs = runs + 1
		end, "Layout")
		framework:RunWhenCombatEnds(function()
			runs = runs + 1
		end, "Visibility")

		leaveCombat()

		fw.eq(runs, 2, "runs")
	end)

	fw.it("does not run the same work again on a second flush", function()
		local runs = 0

		WowMock.State.InCombat = true

		framework:RunWhenCombatEnds(function()
			runs = runs + 1
		end)
		framework:RunWhenCombatEnds(function()
			runs = runs + 1
		end, "Layout")

		leaveCombat()
		WowMock.FireEvent("PLAYER_REGEN_ENABLED")

		fw.eq(runs, 2, "runs")
	end)

	fw.it("holds work queued during a flush back for the next one", function()
		local runs = 0

		WowMock.State.InCombat = true

		framework:RunWhenCombatEnds(function()
			runs = runs + 1

			-- Still flagged as in combat, so this re-queues rather than running inline.
			framework:RunWhenCombatEnds(function()
				runs = runs + 1
			end)
		end)

		WowMock.FireEvent("PLAYER_REGEN_ENABLED")

		fw.eq(runs, 1, "only the original callback ran")
		fw.truthy(framework:HasPendingCombatWork(), "the re-queued work is pending")

		leaveCombat()

		fw.eq(runs, 2, "the re-queued work ran on the next flush")
	end)

	fw.it("errors on a nil callback rather than queueing nothing", function()
		-- In combat is where the guard earns its place. A nil appended to the queue is silently
		-- no work at all, where calling one outside combat raises on its own.
		WowMock.State.InCombat = true

		local ok, err = pcall(framework.RunWhenCombatEnds, framework, nil)

		fw.falsy(ok, "RunWhenCombatEnds(nil) raised")
		fw.truthy(tostring(err):find("RunWhenCombatEnds", 1, true), "the error names the caller")
		fw.falsy(framework:HasPendingCombatWork(), "nothing was queued")
	end)

	fw.it("reports no pending work on a client that never entered combat", function()
		fw.falsy(framework:HasPendingCombatWork(), "pending")
	end)
end)
