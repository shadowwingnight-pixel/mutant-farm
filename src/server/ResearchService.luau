-- Only identifiers and a single-use, short-lived confirmation ticket enter from clients.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Service = {}
function Service.install(config, world, town, sessions, allowed, publish, feedback)
	local bench = world.part(town.model,"ResearchBench",Vector3.new(3,1.6,2),Vector3.new(-113,5.8,-18),Color3.fromRGB(96,142,139),Enum.Material.Wood)
	world.label(bench,"RESEARCH • R / tap\nTwo harvests → Experimental Seed",2.5,220,46)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText, prompt.ObjectText, prompt.KeyboardKeyCode = "Research", "Dr. Lumen's workbench", Enum.KeyCode.R
	prompt.MaxActivationDistance, prompt.RequiresLineOfSight, prompt.Parent = 10,false,bench
	local remote = Instance.new("RemoteEvent")
	remote.Name, remote.Parent = "FarmResearch",ReplicatedStorage
	local function respond(player, session, message, open, success)
		session.researchToken, session.researchExpires = HttpService:GenerateGUID(false), os.clock()+60
		feedback:FireClient(player,{kind="ResearchState",token=session.researchToken,text=message,open=open,success=success})
	end
	prompt.Triggered:Connect(function(player)
		if not allowed(player,player,bench,12) then return end
		respond(player,sessions[player],"Choose two specimens. Nothing is consumed until you confirm.",true)
	end)
	remote.OnServerEvent:Connect(function(player, action, a, b, token)
		if action ~= "Cross" and action ~= "Select" then return end
		if type(a) ~= "string" or #a > 50 then return end
		local session = sessions[player]
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not session or not root or not allowed(player,player,action == "Cross" and bench or root,12) then return end
		if action == "Select" then
			local ok,message = session.state:selectExperiment(a)
			publish(player,session,message,ok and {kind="Select"} or nil)
			return
		end
		if type(b) ~= "string" or #b > 50 or type(token) ~= "string" or #token > 50 then return end
		if token ~= session.researchToken or os.clock() > session.researchExpires then
			respond(player,session,"Confirmation expired or already used. Review your selections before confirming again.",false)
			return
		end
		session.researchToken = nil -- Reject replays before touching state; no yield through acceptance.
		if session.lastResearch and os.clock()-session.lastResearch < config.Research.Cooldown then
			respond(player,session,"Please wait a moment before another experiment.",false); return
		end
		session.lastResearch = os.clock()
		local rng = Random.new()
		local ok,message,id,first = session.state:research(a,b,function(low,high) return rng:NextInteger(low,high) end)
		if ok then session.nextSave = math.min(session.nextSave,os.clock()+3) end
		publish(player,session)
		respond(player,session,message,false,ok)
		if ok then
			local cosmic = config.Research.Specimens[a].Mutation == "Cosmic" or config.Research.Specimens[b].Mutation == "Cosmic"
			feedback:FireClient(player,{kind="Research",text=message,discovery=first,position=bench.Position,mutation=cosmic and "Cosmic" or "Crystal",experiment=id})
		end
	end)
	-- Test grants affect only the current Studio profile (isolated test cloud slot if opted in).
	if not RunService:IsStudio() or not RunService:IsServer() then return end
	local command = Instance.new("BindableFunction")
	command.Name = "MutantFarmResearch"
	command.OnInvoke = function(action,crop,mutation,amount,userId)
		if not RunService:IsStudio() or not RunService:IsServer() then return "Studio server only." end
		local players = game:GetService("Players")
		if userId ~= nil and (type(userId) ~= "number" or userId%1 ~= 0) then return "Invalid UserId" end
		local player = userId and players:GetPlayerByUserId(userId) or players:GetPlayers()[1]
		local session = player and sessions[player]
		if not session or session.closing or session.profile.saving then return "Wait for a loaded, idle session." end
		local state = session.state
		if action == "Inspect" then
			return HttpService:JSONEncode({coins=state.coins,specimens=state.bag,seeds=state.experimentalSeeds,harvests=state.experimentalBag,discoveries=state.researchFound,count=state.researchCount,selected=state.selectedExperiment,traits=config.Research.Traits,catalog=config.Research.Catalog})
		elseif action == "Coins" then
			if type(amount) ~= "number" or amount%1 ~= 0 or amount < 0 or amount > 5000 then return "Amount must be 0–5000." end
			state.coins = amount
		elseif action == "Grant" then
			if type(crop) ~= "string" or type(mutation) ~= "string" or not config.Research.Specimens[crop .. "_" .. mutation] then return "Invalid specimen." end
			if type(amount) ~= "number" or amount%1 ~= 0 or amount < 1 or amount > 20 then return "Amount must be 1–20." end
			state.bag[crop][mutation] = math.min(1000000000,(state.bag[crop][mutation] or 0)+amount)
		else return "Use Grant, Coins or Inspect." end
		publish(player,session,"STUDIO research test inventory updated.")
		return "Applied to Studio profile only; grants can persist in your isolated test slot."
	end
	command.Parent = game:GetService("ServerStorage")
end
return Service
