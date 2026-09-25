local Dialogue = {}
function Dialogue.create(gui, closePanels)
	local frame = Instance.new("Frame")
	frame.Name = "TownDialogue"
	frame.AnchorPoint, frame.Position = Vector2.new(0.5,1), UDim2.new(0.5,0,1,-104)
	frame.Size, frame.BackgroundColor3 = UDim2.new(0.92,0,0,174), Color3.fromRGB(29,48,45)
	frame.Visible, frame.ZIndex, frame.Parent = false, 40, gui
	local limit = Instance.new("UISizeConstraint",frame)
	limit.MaxSize = Vector2.new(560,174)
	Instance.new("UICorner",frame).CornerRadius = UDim.new(0,12)
	local function text(kind, position, size, fontSize)
		local item = Instance.new(kind)
		item.Position, item.Size = position,size
		item.TextColor3, item.Font, item.TextSize = Color3.fromRGB(255,243,214), Enum.Font.Gotham, fontSize
		item.BackgroundTransparency, item.TextWrapped, item.ZIndex, item.Parent = 1,true,41,frame
		return item
	end
	local name = text("TextLabel",UDim2.fromOffset(12,8),UDim2.new(1,-24,0,24),17)
	name.Font = Enum.Font.GothamBold
	local body = text("TextLabel",UDim2.fromOffset(14,36),UDim2.new(1,-28,0,86),16)
	body.TextScaled = true
	local sizeLimit = Instance.new("UITextSizeConstraint",body)
	sizeLimit.MinTextSize, sizeLimit.MaxTextSize = 12,16
	local nextButton = text("TextButton",UDim2.new(0.5,4,1,-46),UDim2.new(0.5,-18,0,40),16)
	local close = text("TextButton",UDim2.new(0,14,1,-46),UDim2.new(0.5,-18,0,40),16)
	close.Text = "Close"
	local lines, index, generation = {},1,0
	local function render()
		body.Text = lines[index]
		nextButton.Text = index < #lines and "Continue →" or "Done"
	end
	local function hide() frame.Visible = false end
	nextButton.Activated:Connect(function()
		if index >= #lines then hide() else index += 1; render() end
	end)
	close.Activated:Connect(hide)
	return {
		close = hide,
		open = function(payload)
			closePanels()
			generation += 1
			local current = generation
			lines, index, name.Text = payload.lines,1,payload.name
			render(); frame.Visible = true
			task.delay(30,function() if current == generation then hide() end end)
		end,
	}
end
return Dialogue
