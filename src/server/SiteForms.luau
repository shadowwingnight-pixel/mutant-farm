-- Original static construction forms shared by the town and farm generators.
local Forms = {}
local V = Vector3.new
Forms.Cream = Color3.fromRGB(239, 222, 184)
Forms.Wood = Color3.fromRGB(110, 76, 53)
function Forms.group(parent, name)
	local model = Instance.new("Model")
	model.Name, model.Parent = name, parent
	return model
end
function Forms.part(parent, name, size, position, color, material, solid, shape)
	local item = Instance.new("Part")
	item.Name, item.Size, item.Position = name, size, position
	item.Color, item.Material = color, material or Enum.Material.SmoothPlastic
	item.Anchored, item.CanTouch = true, false
	item.CanCollide, item.CanQuery, item.CastShadow = solid == true, solid == true, solid == true
	item.TopSurface, item.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
	if shape then item.Shape = shape end
	item.Parent = parent
	return item
end
function Forms.beam(parent, name, a, b, width, color, solid)
	local item = Forms.part(parent, name, V(width, width, (b-a).Magnitude), (a+b)/2, color, Enum.Material.Wood, solid)
	item.CFrame = CFrame.lookAt((a+b)/2, b)
	return item
end
function Forms.roof(parent, center, width, depth, rise, color, material)
	-- Solid triangular roof volumes avoid hollow gables and disconnected floating slabs.
	for _, side in ipairs({ -1, 1 }) do
		local wedge = Instance.new("WedgePart")
		wedge.Name, wedge.Size = "GabledRoof", V(depth, rise, width/2)
		wedge.CFrame = CFrame.new(center + V(side*width/4, rise/2, 0)) * CFrame.Angles(0, -side*math.pi/2, 0)
		wedge.Color, wedge.Material = color, material or Enum.Material.Slate
		wedge.Anchored, wedge.CanCollide, wedge.CanTouch, wedge.CanQuery = true, false, false, false
		wedge.Parent = parent
		for _, z in ipairs({ -depth/2, depth/2 }) do
			Forms.beam(parent, "RoofRake", center + V(side*width/2, 0, z), center + V(0, rise, z), 0.25, Forms.Cream)
		end
	end
	Forms.part(parent, "RidgeCap", V(0.55, 0.35, depth+0.4), center+V(0,rise,0), color, Enum.Material.Slate)
end
function Forms.sign(parent, name, text, size, position, color)
	local board = Forms.part(parent, name, size, position, color, Enum.Material.Wood)
	local gui = Instance.new("SurfaceGui")
	gui.Face, gui.SizingMode, gui.PixelsPerStud, gui.Parent = Enum.NormalId.Back, Enum.SurfaceGuiSizingMode.PixelsPerStud, 40, board
	local label = Instance.new("TextLabel")
	label.Size, label.BackgroundTransparency, label.Text = UDim2.fromScale(1,1), 1, text
	label.TextColor3, label.Font, label.TextScaled, label.TextWrapped = Forms.Cream, Enum.Font.GothamBold, true, true
	label.Parent = gui
	return board
end
function Forms.lantern(town, parent, position, color)
	local bulb = Forms.part(parent, "ExteriorLantern", V(0.8,1.2,0.8), position, color)
	local light = Instance.new("PointLight")
	light.Color, light.Range, light.Brightness, light.Shadows, light.Enabled = color, 12, 0.75, false, false
	light.Parent = bulb
	table.insert(town.lamps, { bulb = bulb, light = light })
end
return Forms
