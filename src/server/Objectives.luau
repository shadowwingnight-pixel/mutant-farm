-- Called only after successful authoritative gameplay operations. No yields or remotes.
local Objectives = {}
function Objectives.advance(state, event)
	local completed = {}
	local function award()
		local rule = state.config.Objectives[state.objectiveStep + 1]
		state.objectiveStep += 1 -- Claim and reward are one atomic state change.
		state.coins += rule.Coins
		table.insert(completed, "✓ " .. rule.Text .. "  +" .. rule.Coins .. " Coins")
	end
	local rule = state.config.Objectives[state.objectiveStep + 1]
	if rule and rule.Event == event then award() end
	-- The first harvest usually discovers Normal before the selling step.
	-- Credit the durable Book entry, so a second random discovery is never required.
	rule = state.config.Objectives[state.objectiveStep + 1]
	if rule and rule.Event == "Discover" then
		for _, entries in pairs(state.discoveries) do
			for _, found in pairs(entries) do
				if found then award(); return completed end
			end
		end
	end
	return completed
end
return Objectives
