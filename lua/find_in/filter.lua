local M = {}

-- mini.pick-style query modifiers: `'` exact, `^` prefix, `$` suffix,
-- and `*` to force fuzzy matching. Plain queries are fuzzy by default.
local function prepare(query)
	local mode = "fuzzy"
	if query:sub(1, 1) == "'" then
		mode, query = "exact", query:sub(2)
	elseif query:sub(1, 1) == "^" then
		mode, query = "prefix", query:sub(2)
	elseif query:sub(1, 1) == "*" then
		query = query:sub(2)
	end
	if query:sub(-1) == "$" and mode ~= "exact" then
		mode = mode == "prefix" and "both" or "suffix"
		query = query:sub(1, -2)
	end
	return mode, query:lower()
end

local function fuzzy(text, query)
	local positions, cursor = {}, 1
	for i = 1, #query do
		local found = text:find(query:sub(i, i), cursor, true)
		if not found then return nil end
		positions[#positions + 1] = found
		cursor = found + 1
	end
	return positions
end

function M.match(text, query)
	local mode, needle = prepare(query or "")
	local value = text:lower()
	if needle == "" then return { score = 0, positions = {} } end
	if mode == "exact" then
		local at = value:find(needle, 1, true)
		if at then
			local positions = {}
			for i = at, at + #needle - 1 do positions[#positions + 1] = i end
			return { score = #needle, positions = positions }
		end
	elseif mode == "prefix" or mode == "both" then
		if value:sub(1, #needle) == needle then
			local positions = {}; for i = 1, #needle do positions[i] = i end
			if mode == "prefix" or value:sub(-#needle) == needle then return { score = #needle, positions = positions } end
		end
	elseif mode == "suffix" then
		local at = #value - #needle + 1
		if at > 0 and value:sub(at) == needle then
			local positions = {}; for i = at, #value do positions[#positions + 1] = i end
			return { score = #needle, positions = positions }
		end
	else
		local positions = fuzzy(value, needle)
		if positions then
			-- Prefer tighter matches, then matches that start earlier.
			return { score = positions[#positions] - positions[1] + 1, positions = positions }
		end
	end
	return nil
end

function M.apply(items, query)
	if not query or query == "" then return vim.deepcopy(items) end
	local matches = {}
	for _, item in ipairs(items) do
		local result = M.match(item, query)
		if result then matches[#matches + 1] = { item = item, score = result.score, start = result.positions[1] or 0 } end
	end
	table.sort(matches, function(a, b)
		if a.score == b.score then
			if a.start == b.start then return a.item < b.item end
			return a.start < b.start
		end
		return a.score < b.score
	end)
	local out = {}; for _, entry in ipairs(matches) do out[#out + 1] = entry.item end
	return out
end

return M
