local M = {}
local function subsequence(text, query)
	local i = 1
	for j = 1, #text do
		if text:sub(j, j):lower() == query:sub(i, i):lower() then
			i = i + 1
			if i > #query then
				return true
			end
		end
	end
	return false
end
function M.apply(items, query)
	if not query or query == "" then
		return vim.deepcopy(items)
	end
	local q, matches = query:lower(), {}
	for _, item in ipairs(items) do
		local lower, name = item:lower(), item:match("([^/]+)$") or item
		if lower:find(q, 1, true) then
			local rank = lower:sub(1, #q) == q and 1 or (name:lower():find(q, 1, true) and 2 or 3)
			matches[#matches + 1] = { item = item, rank = rank }
		elseif subsequence(item, q) then
			matches[#matches + 1] = { item = item, rank = 4 }
		end
	end
	table.sort(matches, function(a, b)
		if a.rank == b.rank then
			return a.item < b.item
		end
		return a.rank < b.rank
	end)
	local out = {}
	for _, entry in ipairs(matches) do
		out[#out + 1] = entry.item
	end
	return out
end
return M
