-- Inventory attributes are display snapshots. Cross requests contain only two IDs and a ticket.
local Panel = {}
function Panel.create(gui,player,config,remote,closeOthers)
	local frame = Instance.new("Frame")
	frame.Name,frame.AnchorPoint,frame.Position = "Research",Vector2.new(0.5,0.5),UDim2.fromScale(0.5,0.54)
	frame.Size,frame.BackgroundColor3 = UDim2.fromScale(0.94,0.8),Color3.fromRGB(30,43,51)
	frame.Visible,frame.Active,frame.ZIndex,frame.Parent = false,true,15,gui
	Instance.new("UICorner",frame).CornerRadius = UDim.new(0,12)
	local limit=Instance.new("UISizeConstraint",frame); limit.MaxSize=Vector2.new(580,550)
	local function label(parent,text,height)
		local item=Instance.new("TextLabel")
		item.Size,item.Text=UDim2.new(1,-8,0,height),text
		item.BackgroundTransparency,item.TextWrapped=1,true
		item.Font,item.TextSize,item.TextColor3=Enum.Font.Gotham,14,Color3.fromRGB(242,237,213)
		item.LayoutOrder=#parent:GetChildren(); item.Parent=parent
		return item
	end
	local function button(parent,text,height,callback)
		local item=Instance.new("TextButton")
		item.Size,item.Text=UDim2.new(1,-8,0,height),text
		item.BackgroundColor3,item.TextWrapped=Color3.fromRGB(63,91,94),true
		item.Font,item.TextSize,item.TextColor3=Enum.Font.GothamBold,14,Color3.fromRGB(255,243,214)
		item.LayoutOrder=#parent:GetChildren(); item.Parent=parent
		Instance.new("UICorner",item).CornerRadius=UDim.new(0,7)
		item.Activated:Connect(callback)
		return item
	end
	local title=label(frame,"RESEARCH",30); title.Position=UDim2.fromOffset(10,8); title.Size=UDim2.new(1,-62,0,30)
	local close=button(frame,"X",36,function() frame.Visible=false end)
	close.Position,close.Size=UDim2.new(1,-46,0,6),UDim2.fromOffset(38,36)
	local scroll=Instance.new("ScrollingFrame")
	scroll.Position,scroll.Size=UDim2.fromOffset(10,48),UDim2.new(1,-20,1,-58)
	scroll.BackgroundTransparency,scroll.BorderSizePixel,scroll.ScrollBarThickness=1,0,5
	scroll.AutomaticCanvasSize,scroll.CanvasSize=Enum.AutomaticSize.Y,UDim2.new()
	scroll.Parent=frame
	local layout=Instance.new("UIListLayout",scroll); layout.Padding=UDim.new(0,7); layout.SortOrder=Enum.SortOrder.LayoutOrder
	local mode,slot,a,b,token,pending = "Lab","A",nil,nil,nil,false
	local statusText="Choose a specimen for each slot."
	local redraw
	local function number(name) return player:GetAttribute(name) or 0 end
	local function specimenName(id) return id and config.Research.Specimens[id].Name or "Choose specimen" end
	local function open(which)
		closeOthers(); mode=which; frame.Visible=true; redraw()
	end
	redraw=function()
		if not frame.Visible then return end
		for _,child in ipairs(scroll:GetChildren()) do if child:IsA("GuiObject") then child:Destroy() end end
		title.Text=mode=="Lab" and "LUMEN'S RESEARCH" or (mode=="Seeds" and "EXPERIMENTAL SEEDS" or "RESEARCH DISCOVERIES")
		if mode=="Lab" then
			label(scroll,"Cost: " .. config.Research.Cost .. " Coins + 2 harvested crops\nSame crop or Tomato × Strawberry. Pumpkin pairs only with Pumpkin.",64)
			button(scroll,"SLOT A: " .. specimenName(a) .. (slot=="A" and "  ← choosing" or ""),44,function() slot="A"; redraw() end)
			button(scroll,"SLOT B: " .. specimenName(b) .. (slot=="B" and "  ← choosing" or ""),44,function() slot="B"; redraw() end)
			label(scroll,statusText,58)
			local valid=a and b and token and not pending
			local confirm=button(scroll,pending and "ANALYZING SPECIMENS..." or ("CONFIRM • Consume both + " .. config.Research.Cost .. " Coins"),48,function()
				if not a or not b or not token or pending then return end
				pending=true; statusText="Analyzing specimens..."
				local sentToken=token
				remote:FireServer("Cross",a,b,token)
				redraw()
				task.delay(6,function()
					if pending and token==sentToken then pending=false; token=nil; statusText="No confirmation received. Reopen Research at the lab to check your inventory."; redraw() end
				end)
			end)
			confirm.Interactable=valid == true
			button(scroll,"View experimental seeds",40,function() open("Seeds") end)
			label(scroll,"Choose a harvested specimen below. Selecting does not consume it. Identical parents need TWO crops. Sell all also sells unreserved specimens.",66)
			for _,id in ipairs(config.Research.SpecimenOrder) do
				local item=config.Research.Specimens[id]
				local count=number("Bag_" .. item.Crop .. "_" .. item.Mutation)
				if count > 0 then
					button(scroll,item.Name .. " ×" .. count,42,function()
						if pending then return end
						if slot=="A" then a=id; slot="B" else b=id end
						statusText="Confirmation consumes ONE " .. specimenName(a) .. " and ONE " .. specimenName(b) .. "."
						redraw()
					end)
				end
			end
		elseif mode=="Seeds" then
			label(scroll,"Select a seed, close this panel, then click empty farm soil.\nExperimental harvests retain traits; Sell all includes them. They cannot be research parents in V1.",72)
			local found=false
			for _,id in ipairs(config.Research.Order) do
				local item=config.Research.Catalog[id]
				local count=number("ExpSeed_" .. id)
				local harvests={}
				for _,m in ipairs(config.Mutations) do
					local n=number("ExpBag_" .. id .. "_" .. m.Id)
					if n>0 then table.insert(harvests,m.Id .. " ×" .. n) end
				end
				if count>0 or #harvests>0 then
					found=true
					label(scroll,item.Name .. " • " .. item.Crop .. " / " .. item.Trait .. "\n" .. config.Research.Traits[item.Trait].Description .. "\nSeeds: " .. count .. " • Harvests: " .. (#harvests>0 and table.concat(harvests,", ") or "none"),90)
					if count>0 then button(scroll,"Plant " .. item.Name,42,function() remote:FireServer("Select",id) end) end
				end
			end
			if not found then label(scroll,"No experiments yet. Bring two harvested crops to Dr. Lumen's workbench (R / tap).",70) end
		else
			label(scroll,number("ResearchCount")>0 and ("✓ First research • Experiments completed: " .. number("ResearchCount")) or "??? • Complete your first research",50)
			local keys={}; for key in pairs(config.Research.Combinations) do table.insert(keys,key) end; table.sort(keys)
			for _,key in ipairs(keys) do label(scroll,player:GetAttribute("Research_" .. key) and ("✓ " .. string.gsub(key,"_"," × ")) or "??? • Unstudied compatible pair",38) end
			for _,trait in ipairs(config.Research.TraitOrder) do
				local known=player:GetAttribute("Research_Trait_" .. trait)
				label(scroll,known and ("✓ " .. trait .. " • " .. config.Research.Traits[trait].Description .. "\n" .. (player:GetAttribute("Research_Grown_" .. trait) and "✓ Harvested" or "??? • Grow and harvest this trait")) or "??? • Undiscovered trait",70)
			end
		end
	end
	local queued=false
	player.AttributeChanged:Connect(function()
		if queued or not frame.Visible then return end
		queued=true; task.defer(function() queued=false; redraw() end)
	end)
	return {
		close=function() frame.Visible=false end,
		openSeeds=function() open("Seeds") end,
		openBook=function() open("Book") end,
		receive=function(payload)
			token,pending,statusText=payload.token,false,payload.text
			if payload.success then a,b,slot=nil,nil,"A" end
			if payload.open then open("Lab") else redraw() end
		end,
	}
end
return Panel
