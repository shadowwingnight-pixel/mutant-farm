-- Pure server state and derived odds. No player data, persistence or Roblox globals.
local Environment = {}
Environment.__index = Environment

function Environment.new(config, now)
	local settings = config.Environment
	return setmetatable({ config = config, phase = 1, weather = "Clear", meteorEndsAt = 0,
		nextPhase = now + settings.Phases[1].Seconds, nextWeather = now + settings.WeatherSeconds,
		nextMeteor = now + settings.Meteor.CheckSeconds, holdTime = false, holdWeather = false }, Environment)
end

function Environment:startMeteor(now)
	if self.meteorEndsAt > 0 then return false end -- Repeated previews do not extend the event.
	self.meteorEndsAt = now + self.config.Environment.Meteor.Duration
	return true
end

function Environment:endMeteor(now)
	self.meteorEndsAt = 0
	self.nextMeteor = now + self.config.Environment.Meteor.Cooldown
end

function Environment:advance(now, random)
	local settings = self.config.Environment
	if not self.holdTime then
		while now >= self.nextPhase do
			self.phase = self.phase % #settings.Phases + 1
			self.nextPhase += settings.Phases[self.phase].Seconds
		end
	end
	if not self.holdWeather and now >= self.nextWeather then
		local total = 0
		for _, weather in ipairs(settings.Weather) do total += weather.Weight end
		local roll = random() * total
		for _, weather in ipairs(settings.Weather) do
			roll -= weather.Weight
			if roll < 0 then self.weather = weather.Id; break end
		end
		self.nextWeather = now + settings.WeatherSeconds
	end
	if self.meteorEndsAt > 0 then
		if now >= self.meteorEndsAt then self:endMeteor(now) end
	elseif now >= self.nextMeteor then
		self.nextMeteor = now + settings.Meteor.CheckSeconds
		if random() < settings.Meteor.Chance then self:startMeteor(now) end
	end
end

function Environment:snapshot()
	return { phase = self.config.Environment.Phases[self.phase].Id, weather = self.weather,
		meteorEndsAt = self.meteorEndsAt, holdTime = self.holdTime, holdWeather = self.holdWeather }
end

function Environment:weights()
	local mods = self.config.Environment.Modifiers
	local phase = self.config.Environment.Phases[self.phase].Id
	local sources = { mods[self.weather] or {}, mods[phase] or {}, self.meteorEndsAt > 0 and mods.Meteor or {} }
	local weights, total = {}, 0
	for _, mutation in ipairs(self.config.Mutations) do
		local factor = 1
		for _, source in ipairs(sources) do factor *= source[mutation.Id] or 1 end
		local weight = math.max(1, math.floor(mutation.Weight * factor + 0.5))
		table.insert(weights, { Id = mutation.Id, Weight = weight, Factor = factor })
		total += weight
	end
	for _, entry in ipairs(weights) do entry.Percent = entry.Weight / total * 100 end
	return weights, total
end

-- Only the Studio/server adapter exposes this. Holds last until Resume or server stop.
function Environment:preview(command, now)
	local settings = self.config.Environment
	for index, phase in ipairs(settings.Phases) do
		if command == phase.Id then self.phase = index; self.holdTime = true; return true end
	end
	for _, weather in ipairs(settings.Weather) do
		if command == weather.Id then self.weather = weather.Id; self.holdWeather = true; return true end
	end
	if command == "Meteor" then self:startMeteor(now); return true end
	if command == "EndMeteor" then self:endMeteor(now); return true end
	if command == "Resume" then
		self.holdTime, self.holdWeather = false, false
		self.nextPhase = now + settings.Phases[self.phase].Seconds
		self.nextWeather = now + settings.WeatherSeconds
		return true
	end
	return command == "Inspect"
end

return Environment
