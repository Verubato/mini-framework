-- Shared helper for swapping a global out for the length of a test.

local M = {}

---Runs fn with a global replaced, putting the old value back even when fn raises.
function M.withGlobal(name, value, fn)
	local saved = _G[name]

	_G[name] = value

	local ok, err = pcall(fn)

	_G[name] = saved

	if not ok then
		error(err, 0)
	end
end

return M
