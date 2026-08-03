-- Loads MiniFramework into a mocked client, the way a consuming addon does.
--
-- The framework has no .toc of its own - addons embed it and reference MiniFramework.xml from
-- theirs - so the harness is pointed at that xml directly and the framework is loaded under a
-- synthetic addon name. That name matters: the framework derives saved-variable names, slash
-- commands and global frame names from it.

local harness = require("AddonHarness")
local WowMock = require("WowMock")

local M = {}

M.AddonName = "MiniFrameworkTest"
M.XmlPath = "src/MiniFramework/MiniFramework.xml"

---Loads the framework into a fresh client.
---@return { Addon: table, Framework: table, Mock: table, Loaded: string[] }
function M.Load()
	local context = harness.LoadXml(M.AddonName, M.XmlPath)

	context.Framework = context.Addon.Framework

	return context
end

---Loads the framework and returns a panel to build widgets onto, as a config panel would be.
---@return table framework, table panel
function M.LoadWithPanel()
	local context = M.Load()
	local panel = _G.CreateFrame("Frame", nil, _G.UIParent)

	panel:SetSize(600, 600)

	return context.Framework, panel
end

---A getter/setter pair backed by a single value, for the widgets that require both.
---@param initial any
---@return fun(): any getValue, fun(value: any), table state
function M.Binding(initial)
	local state = { Value = initial }

	return function()
		return state.Value
	end, function(value)
		state.Value = value
	end, state
end

M.Mock = WowMock

return M
