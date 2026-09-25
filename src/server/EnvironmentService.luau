local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local State = require(script.Parent.EnvironmentState)
local Service = {}
Service.__index = Service

function Service.new(config)
	local now = workspace:GetServerTimeNow()
	local snapshot = Instance.new("StringValue")
	snapshot.Name = "FarmEnvironment"
	local lightning = Instance.new("RemoteEvent")
	lightning.Name, lightning.Parent = "FarmLightning", ReplicatedStorage -- Outbound only.
	local self = setmetatable({ state = State.new(config, now), config = config, snapshot = snapshot,
		lightning = lightning, random = Random.new(), nextLightning = now + 10 }, Service)
	self:publish()
	snapshot.Parent = ReplicatedStorage
	self:installPreview()
	return self
end

function Service:publish()
	local data = self.state:snapshot()
	local key = data.phase .. ":" .. data.weather .. ":" .. data.meteorEndsAt .. ":" .. tostring(data.holdTime) .. ":" .. tostring(data.holdWeather)
	if key == self.lastKey then return end
	self.lastKey = key
	self.currentWeights = self.state:weights()
	self.snapshot.Value = HttpService:JSONEncode(data) -- One atomic, late-join-safe snapshot.
end

function Service:step()
	local now = workspace:GetServerTimeNow()
	self.state:advance(now, function() return self.random:NextNumber() end)
	self:publish()
	if now >= self.nextLightning then
		local interval = self.config.Environment.LightningSeconds
		self.nextLightning = now + self.random:NextNumber(interval[1], interval[2])
		if self.state.weather == "Thunderstorm" then self.lightning:FireAllClients() end
	end
end

function Service:installPreview()
	if not RunService:IsStudio() or not RunService:IsServer() then return end
	local command = Instance.new("BindableFunction")
	command.Name = "MutantFarmEnvironment"
	command.OnInvoke = function(action)
		if not RunService:IsStudio() or not RunService:IsServer() then return "Studio server only." end
		self:step()
		if type(action) ~= "string" or not self.state:preview(action, workspace:GetServerTimeNow()) then
			return "Use Day, Evening, Night, Clear, Rain, Thunderstorm, Meteor, EndMeteor, Inspect or Resume."
		end
		self:publish()
		local report = self.state:snapshot()
		report.weights, report.totalWeight = self.state:weights()
		report.appliesAt = "Maturity only; no rerolls. Factors multiply baseline weights, not percentages."
		return HttpService:JSONEncode(report)
	end
	command.Parent = ServerStorage
end

return Service
