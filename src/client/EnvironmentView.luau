-- Cosmetics only. The server snapshot owns conditions; no requests or economic state.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local View = {}
local function color(rgb) return Color3.fromRGB(table.unpack(rgb)) end
local function part(parent, name, size, tint)
	local item = Instance.new("Part")
	item.Name, item.Size, item.Color = name, size, tint
	item.Anchored, item.CanCollide, item.CanQuery, item.CanTouch, item.CastShadow = true, false, false, false, false
	item.Material, item.Parent = Enum.Material.Neon, parent
	return item
end

function View.start(gui, conditionLabel, config)
	local settings, visuals = config.Environment, config.Environment.Visuals
	local snapshot = ReplicatedStorage:WaitForChild("FarmEnvironment")
	local lightning = ReplicatedStorage:WaitForChild("FarmLightning")
	local folder = Instance.new("Folder")
	folder.Name, folder.Parent = "LocalFarmEnvironment", workspace
	local rainFolder, meteorFolder = Instance.new("Folder"), Instance.new("Folder")
	rainFolder.Name, rainFolder.Parent = "Rain", folder
	meteorFolder.Name, meteorFolder.Parent = "Meteors", folder
	local boltFolder = Instance.new("Folder")
	boltFolder.Name, boltFolder.Parent = "Lightning", folder
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local ownsAtmosphere = atmosphere == nil
	if not atmosphere then atmosphere = Instance.new("Atmosphere"); atmosphere.Parent = Lighting end
	local originalAtmosphere = { Color = atmosphere.Color, Density = atmosphere.Density, Haze = atmosphere.Haze }
	local originalLight = { ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness,
		Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient }
	local flash = Instance.new("ColorCorrectionEffect")
	flash.Name, flash.Parent = "FarmLightningFlash", Lighting
	local clock = Instance.new("NumberValue")
	clock.Value = Lighting.ClockTime
	local tweens, connections, drops = {}, {}, {}
	local random = Random.new()
	local current, stopped, bannerUntil = nil, false, 0
	local nextMeteor, elapsed = 0, 0
	local thunder
	if visuals.ThunderSoundId ~= "" then
		thunder = Instance.new("Sound")
		thunder.Name, thunder.SoundId, thunder.Volume = "FarmThunder", visuals.ThunderSoundId, 0.25
		thunder.Parent = SoundService
	end
	local banner = Instance.new("TextLabel")
	banner.Name = "EnvironmentAnnouncement"
	banner.AnchorPoint, banner.Position = Vector2.new(0.5, 0), UDim2.new(0.5, 0, 0, 265)
	banner.Size = UDim2.new(0.9, 0, 0, 56)
	banner.BackgroundColor3, banner.BackgroundTransparency = Color3.fromRGB(46, 32, 71), 0.1
	banner.TextColor3, banner.TextSize, banner.Font = Color3.fromRGB(211, 229, 255), 16, Enum.Font.GothamBold
	banner.TextWrapped, banner.Visible, banner.ZIndex, banner.Parent = true, false, 25, gui
	local corner = Instance.new("UICorner", banner)
	corner.CornerRadius = UDim.new(0, 12)
	local limit = Instance.new("UISizeConstraint", banner)
	limit.MaxSize = Vector2.new(520, 56)
	local function announce(text)
		banner.Text, banner.Visible, bannerUntil = text, true, os.clock() + 5
	end
	local function tween(object, goals, seconds)
		if tweens[object] then tweens[object]:Cancel(); tweens[object] = nil end
		if seconds == 0 then for property, value in pairs(goals) do object[property] = value end; return end
		local animation = TweenService:Create(object, TweenInfo.new(seconds, Enum.EasingStyle.Sine), goals)
		tweens[object] = animation
		animation:Play()
	end
	table.insert(connections, clock.Changed:Connect(function(value) Lighting.ClockTime = value % 24 end))
	local function receive()
		local ok, data = pcall(HttpService.JSONDecode, HttpService, snapshot.Value)
		if not ok or type(data) ~= "table" then return end
		local phase, weather
		for _, entry in ipairs(settings.Phases) do if entry.Id == data.phase then phase = entry end end
		for _, entry in ipairs(settings.Weather) do if entry.Id == data.weather then weather = entry end end
		if not phase or not weather then return end
		local meteor = data.meteorEndsAt > workspace:GetServerTimeNow()
		local previousMeteor = current and current.meteor
		if meteor and not previousMeteor then
			announce("☄ METEOR SHOWER!\nStrange energy is affecting the farm...")
		elseif previousMeteor and not meteor then
			announce("Meteor Shower ended • Normal conditions return")
			meteorFolder:ClearAllChildren()
		end
		local duration = current and settings.TransitionSeconds or 0
		local tint = meteor and Color3.fromRGB(123, 107, 182) or color(weather.Color)
		local ambient = meteor and Color3.fromRGB(105, 91, 145) or color(phase.Ambient)
		tween(Lighting, { Brightness = phase.Brightness * weather.Brightness,
			Ambient = ambient, OutdoorAmbient = ambient }, duration)
		tween(atmosphere, { Color = tint, Density = meteor and math.max(0.3, weather.Density) or weather.Density,
			Haze = weather.Id == "Clear" and 0.5 or 2 }, duration)
		-- Move forward through midnight; ClockTime itself is not replicated by Roblox.
		if not current or current.phase ~= data.phase then
			local delta = (phase.Clock - clock.Value % 24) % 24
			tween(clock, { Value = clock.Value + delta }, duration)
		end
		if not current or current.weather ~= data.weather then
			rainFolder:ClearAllChildren()
			drops = {}
			for _ = 1, weather.Rain do
				local drop = part(rainFolder, "RainDrop", Vector3.new(0.055, 2.4, 0.055), Color3.fromRGB(171, 207, 244))
				drop.Transparency = 1 -- Positioned before first visible frame.
				table.insert(drops, { part = drop, x = random:NextNumber(-visuals.RainRadius, visuals.RainRadius),
					z = random:NextNumber(-visuals.RainRadius, visuals.RainRadius), y = random:NextNumber(-8, visuals.RainHeight) })
			end
			if data.weather ~= "Thunderstorm" then
				tween(flash, { Brightness = 0 }, 0)
				boltFolder:ClearAllChildren()
				if thunder then thunder:Stop() end
			end
		end
		data.meteor = meteor
		current = data
	end
	table.insert(connections, snapshot.Changed:Connect(receive))
	table.insert(connections, lightning.OnClientEvent:Connect(function()
		if not current or current.weather ~= "Thunderstorm" then return end
		-- One soft pulse, no rapid strobe, camera shake or obstruction.
		local camera = workspace.CurrentCamera
		boltFolder:ClearAllChildren()
		if camera then
			local forward = camera.CFrame.LookVector
			local top = camera.CFrame.Position + Vector3.new(forward.X * 65, 38, forward.Z * 65)
			for index = 1, 3 do
				local bottom = top + Vector3.new(index % 2 == 0 and -6 or 6, -9, 0)
				local bolt = part(boltFolder, "LightningBolt", Vector3.new(0.2, 0.2, (bottom - top).Magnitude), Color3.fromRGB(213, 223, 255))
				bolt.CFrame = CFrame.lookAt((top + bottom) / 2, bottom)
				Debris:AddItem(bolt, 0.3)
				top = bottom
			end
		end
		tween(flash, { Brightness = 0.12 }, 0)
		tween(flash, { Brightness = 0 }, 0.65)
		if thunder then thunder:Play() end
	end))
	local function meteor(camera)
		if #meteorFolder:GetChildren() >= visuals.MaxMeteors then return end
		local direction = camera.CFrame.LookVector
		local center = camera.CFrame.Position + Vector3.new(direction.X, 0, direction.Z) * 48 + Vector3.new(0, 27, 0)
		local start = center + Vector3.new(random:NextNumber(-25, 25), 12, random:NextNumber(-12, 12))
		local finish = start + Vector3.new(26, -18, 7)
		local streak = part(meteorFolder, "Meteor", Vector3.new(0.3, 0.3, 9), Color3.fromRGB(175, 155, 255))
		streak.CFrame = CFrame.lookAt(start, finish)
		local glow = Instance.new("PointLight", streak)
		glow.Color, glow.Brightness, glow.Range, glow.Shadows = streak.Color, 0.7, 9, false
		TweenService:Create(streak, TweenInfo.new(visuals.MeteorLife, Enum.EasingStyle.Linear), {
			CFrame = CFrame.lookAt(finish, finish + (finish - start)), Transparency = 1,
		}):Play()
		Debris:AddItem(streak, visuals.MeteorLife)
	end
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < visuals.TickSeconds then return end
		local step = math.min(elapsed, 0.15)
		elapsed = 0
		if banner.Visible and os.clock() >= bannerUntil then banner.Visible = false end
		if not current then return end
		local seconds = math.max(0, math.ceil(current.meteorEndsAt - workspace:GetServerTimeNow()))
		conditionLabel.Text = string.upper(current.phase) .. "  •  " .. string.upper(current.weather)
			.. (current.meteor and ("  •  ☄ METEOR " .. seconds .. "s") or "")
		local camera = workspace.CurrentCamera
		if not camera then return end
		for _, drop in ipairs(drops) do
			drop.y -= visuals.RainSpeed * step
			if drop.y < -8 then drop.y = visuals.RainHeight end
			drop.part.Position = camera.CFrame.Position + Vector3.new(drop.x, drop.y, drop.z)
			drop.part.Transparency = current.weather == "Thunderstorm" and 0.3 or 0.48
		end
		if current.meteor and seconds > 0 and os.clock() >= nextMeteor then
			nextMeteor = os.clock() + visuals.MeteorInterval
			meteor(camera)
		end
	end))
	local function stop()
		if stopped then return end
		stopped = true
		for _, connection in ipairs(connections) do connection:Disconnect() end
		for _, animation in pairs(tweens) do animation:Cancel() end
		folder:Destroy(); flash:Destroy(); clock:Destroy(); banner:Destroy()
		if thunder then thunder:Destroy() end
		for property, value in pairs(originalLight) do Lighting[property] = value end
		if ownsAtmosphere then atmosphere:Destroy()
		else for property, value in pairs(originalAtmosphere) do atmosphere[property] = value end end
	end
	table.insert(connections, gui.Destroying:Connect(stop))
	receive()
	return stop
end

return View
