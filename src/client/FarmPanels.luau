-- Display snapshots only; actions send identifiers, never inventory or pricing.
local Panels = {}
local cream = Color3.fromRGB(255, 243, 214)
local function rounded(parent)
	local corner = Instance.new("UICorner")
	corner.CornerRadius, corner.Parent = UDim.new(0, 10), parent
end
local function text(parent, content, position, size, fontSize)
	local item = Instance.new("TextLabel")
	item.Text, item.Position, item.Size = content, position, size
	item.TextColor3, item.BackgroundTransparency = cream, 1
	item.Font, item.TextSize, item.TextWrapped = Enum.Font.GothamBold, fontSize or 14, true
	item.Parent = parent
	return item
end
local function button(parent, content, position, size, callback)
	local item = Instance.new("TextButton")
	item.Text, item.Position, item.Size = content, position, size
	item.TextColor3, item.BackgroundColor3 = cream, Color3.fromRGB(60, 106, 74)
	item.Font, item.TextSize, item.TextWrapped = Enum.Font.GothamBold, 14, true
	item.Parent = parent
	rounded(item)
	item.Activated:Connect(callback)
	return item
end

function Panels.create(gui, player, config, remote, research)
	local panel = Instance.new("Frame")
	panel.Name = "SeedsAndDiscoveries"
	panel.AnchorPoint, panel.Position = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.54)
	panel.Size, panel.BackgroundColor3 = UDim2.fromScale(0.94, 0.78), Color3.fromRGB(23, 42, 36)
	panel.Visible, panel.Active, panel.ZIndex, panel.Parent = false, true, 10, gui
	rounded(panel)
	local limit = Instance.new("UISizeConstraint", panel)
	limit.MaxSize = Vector2.new(560, 490)
	local title = text(panel, "SEEDS & PROGRESSION", UDim2.fromOffset(12, 10), UDim2.new(1, -65, 0, 27), 19)
	button(panel, "X", UDim2.new(1, -44, 0, 8), UDim2.fromOffset(34, 34), function() panel.Visible = false end)
	local subtitle = text(panel, "", UDim2.fromOffset(12, 42), UDim2.new(1, -24, 0, 38), 13)
	local mode = "Seeds"
	local panes = {}
	for _, name in ipairs({ "Seeds", "Book", "Land" }) do
		local pane = Instance.new("ScrollingFrame")
		pane.Name = name
		pane.Position, pane.Size = UDim2.fromOffset(10, 85), UDim2.new(1, -20, 1, -95)
		pane.BackgroundTransparency, pane.BorderSizePixel, pane.ScrollBarThickness = 1, 0, 5
		pane.AutomaticCanvasSize, pane.CanvasSize = Enum.AutomaticSize.Y, UDim2.new()
		pane.ScrollingDirection, pane.Parent = Enum.ScrollingDirection.Y, panel
		local layout = Instance.new("UIListLayout", pane)
		layout.Padding, layout.SortOrder = UDim.new(0, 9), Enum.SortOrder.LayoutOrder
		panes[name] = pane
	end
	local landCard = Instance.new("Frame")
	landCard.Size, landCard.BackgroundColor3, landCard.Parent = UDim2.new(1, -8, 0, 215), Color3.fromRGB(35, 61, 48), panes.Land
	rounded(landCard)
	local landStatus = text(landCard, "", UDim2.fromOffset(12, 10), UDim2.new(1, -24, 0, 130), 17)
	local expand = button(landCard, "", UDim2.fromOffset(12, 156), UDim2.new(1, -24, 0, 42), function() remote:FireServer("Expand") end)
	local shopRows, bookRows = {}, {}
	local experimental = button(panes.Seeds,"Experimental seeds & harvests",UDim2.new(),UDim2.new(1,-8,0,44),function() panel.Visible=false; research.openSeeds() end)
	experimental.LayoutOrder=0
	local researchBook = button(panes.Book,"Research / Hybrid discoveries",UDim2.new(),UDim2.new(1,-8,0,44),function() panel.Visible=false; research.openBook() end)
	researchBook.LayoutOrder=0
	for index, cropId in ipairs(config.CropOrder) do
		local crop = config.Crops[cropId]
		local card = Instance.new("Frame")
		card.Size, card.LayoutOrder = UDim2.new(1, -8, 0, 156), index
		card.BackgroundColor3, card.Parent = Color3.fromRGB(35, 61, 48), panes.Seeds
		rounded(card)
		text(card, cropId .. " • " .. crop.SeedPrice .. " Coins • " .. crop.GrowSeconds .. "s", UDim2.fromOffset(8, 5), UDim2.new(1, -16, 0, 26), 16)
		local status = text(card, "", UDim2.fromOffset(8, 34), UDim2.new(1, -16, 0, 70), 13)
		local buy = button(card, "Buy 1 seed", UDim2.fromOffset(8, 111), UDim2.new(0.5, -12, 0, 36), function()
			remote:FireServer("Buy", cropId)
		end)
		local select = button(card, "Plant this seed", UDim2.new(0.5, 4, 0, 111), UDim2.new(0.5, -12, 0, 36), function()
			remote:FireServer("Select", cropId)
		end)
		shopRows[cropId] = { status = status, buy = buy, select = select }
		local page = Instance.new("Frame")
		page.Size, page.LayoutOrder = UDim2.new(1, -8, 0, 176), index
		page.BackgroundColor3, page.Parent = Color3.fromRGB(35, 61, 48), panes.Book
		rounded(page)
		local heading = text(page, cropId, UDim2.fromOffset(8, 4), UDim2.new(1, -16, 0, 26), 17)
		local entries = {}
		for mutationIndex, mutation in ipairs(config.Mutations) do
			entries[mutation.Id] = text(page, "??? • Undiscovered", UDim2.fromOffset(10, 33 + (mutationIndex - 1) * 27), UDim2.new(1, -20, 0, 23), 14)
		end
		bookRows[cropId] = { heading = heading, entries = entries }
	end
	local function number(name) return player:GetAttribute(name) or 0 end
	local function refresh()
		if not panel.Visible then return end
		local farms = workspace:FindFirstChild("MutantFarms")
		local farm = farms and farms:FindFirstChild("Farm_" .. player.UserId)
		local shop = farm and farm:FindFirstChild("SeedShop")
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local nearShop = shop ~= nil and root ~= nil and (root.Position - shop.Position).Magnitude <= config.ShopDistance
		local town = workspace:FindFirstChild("MutantFarmTown")
		local townShop = town and town:FindFirstChild("SeedShop")
		nearShop = nearShop or (townShop ~= nil and root ~= nil and (root.Position - townShop.Position).Magnitude <= config.ShopDistance)
		title.Text = mode == "Seeds" and "SEEDS & PROGRESSION" or "MUTATION DISCOVERY BOOK"
		subtitle.Text = mode == "Seeds" and ("Buy at the town store or farm counter. Close X to plant " .. (player:GetAttribute("SelectedCrop") or "Tomato") .. ".\nSell crops to unlock seeds; unlocks do not spend Coins.")
			or (number("DiscoveryCount") .. "/" .. (#config.CropOrder * #config.Mutations) .. " discovered • Harvest to record a discovery\nUnknown mutations stay hidden")
		if mode == "Land" then
			title.Text, subtitle.Text = "GROW YOUR FARM", "Buy land at your blue expansion board.\nMore plots • More harvests • More discoveries"
			local tier = number("ExpansionTier")
			local current, nextTier = config.Expansions[tier], config.Expansions[tier + 1]
			local board = farm and farm:FindFirstChild("FarmUpgrade")
			local near = board and root and (root.Position - board.Position).Magnitude <= config.ShopDistance
			local affordable = nextTier and number("Coins") >= nextTier.Cost
			landStatus.Text = current and (current.Name .. " • " .. current.Plots .. " plots\n\n" .. (nextTier and (nextTier.Name .. " → " .. nextTier.Plots .. " plots\n" .. nextTier.Cost .. " Coins") or "MAX SIZE • Enjoy your full farm!")) or "Loading farm..."
			expand.Text = not nextTier and "MAX SIZE" or (not near and "Visit blue expansion board" or (affordable and "Buy expansion" or "LOCKED • Need more Coins"))
			expand.Interactable = nextTier ~= nil and near == true and affordable == true
		end
		for name, pane in pairs(panes) do pane.Visible = name == mode end
		for _, cropId in ipairs(config.CropOrder) do
			local crop = config.Crops[cropId]
			local unlocked = player:GetAttribute("Unlocked_" .. cropId) == true or (crop.Unlock.EarnedCoins == 0 and not crop.Unlock.PreviousCrop)
			local row = shopRows[cropId]
			local rule = crop.Unlock
			if unlocked then
				row.status.Text = "UNLOCKED • Seeds: " .. number("Seeds_" .. cropId) .. " • Normal sale: " .. crop.BaseValue .. " Coins\nTotal harvested: " .. number("Harvested_" .. cropId)
			else
				row.status.Text = "LOCKED • Both requirements:\nSale Coins: " .. math.min(number("EarnedCoins"), rule.EarnedCoins) .. "/" .. rule.EarnedCoins
					.. "  |  " .. rule.PreviousCrop .. " harvests: " .. math.min(number("Harvested_" .. rule.PreviousCrop), rule.Harvests) .. "/" .. rule.Harvests .. "\nSell a harvest to unlock."
			end
			local canBuy = unlocked and nearShop and number("Coins") >= crop.SeedPrice
			local canSelect = unlocked and number("Seeds_" .. cropId) > 0
			row.buy.Text = not unlocked and "LOCKED" or (not nearShop and "Visit Seed Shop" or (canBuy and ("Buy • " .. crop.SeedPrice .. " Coins") or "Not enough Coins"))
			row.select.Text = player:GetAttribute("SelectedCrop") == cropId and (player:GetAttribute("SelectedExperiment") or "") == "" and "Selected to plant" or "Plant this seed"
			row.buy.Interactable, row.select.Interactable = canBuy, canSelect
			row.buy.BackgroundColor3 = canBuy and Color3.fromRGB(60, 106, 74) or Color3.fromRGB(66, 69, 64)
			row.select.BackgroundColor3 = canSelect and Color3.fromRGB(60, 106, 74) or Color3.fromRGB(66, 69, 64)
			local foundCount = 0
			for _, mutation in ipairs(config.Mutations) do
				local found = player:GetAttribute("Found_" .. cropId .. "_" .. mutation.Id) == true
				local entry = bookRows[cropId].entries[mutation.Id]
				entry.Text = found and ("✓ " .. mutation.Id .. " " .. cropId .. "  •  In basket: " .. number("Bag_" .. cropId .. "_" .. mutation.Id)) or "??? • Undiscovered"
				entry.TextColor3 = found and Color3.fromRGB(table.unpack(mutation.Color)) or Color3.fromRGB(163, 178, 165)
				if found then foundCount += 1 end
			end
			bookRows[cropId].heading.Text = cropId .. " • " .. foundCount .. "/" .. #config.Mutations .. (unlocked and "" or " • Seed locked")
		end
	end
	local queued = false
	player.AttributeChanged:Connect(function()
		if queued or not panel.Visible then return end
		queued = true
		task.defer(function() queued = false; refresh() end)
	end)
	local api = {}
	function api.openSeeds() mode = "Seeds"; panel.Visible = true; refresh() end
	function api.openBook() mode = "Book"; panel.Visible = true; refresh() end
	function api.openLand() mode = "Land"; panel.Visible = true; refresh() end
	function api.close() panel.Visible = false end
	api.refresh = refresh
	return api
end

return Panels
