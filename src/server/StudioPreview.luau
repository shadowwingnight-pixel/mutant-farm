-- Development-only, server Command Bar access. Never changes FarmState or odds.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local StudioPreview = {}

function StudioPreview.install(config, world, feedback, sessions)
	if not RunService:IsStudio() or not RunService:IsServer() then return end
	local command = Instance.new("BindableFunction")
	command.Name = "MutantFarmPreview"
	command.OnInvoke = function(mutationId, userId)
		if not RunService:IsStudio() or not RunService:IsServer() then return "Studio server only." end
		if userId ~= nil and (type(userId) ~= "number" or userId ~= userId or userId % 1 ~= 0) then return "UserId must be a player ID number." end
		local player
		if userId ~= nil then player = Players:GetPlayerByUserId(userId) else player = Players:GetPlayers()[1] end
		local session = player and sessions[player]
		if not session then return "Start Play and wait for your farm first." end
		if mutationId == "Clear" then
			if session.preview then session.preview:Destroy(); session.preview = nil end
			return "Preview cleared. Farm inventory and probabilities unchanged."
		end
		local valid = false
		for _, mutation in ipairs(config.Mutations) do
			if mutation.Id == mutationId then valid = true; break end
		end
		if not valid then return "Use Normal, Golden, Giant, Crystal, Cosmic or Clear." end
		if session.preview then session.preview:Destroy() end
		local model = Instance.new("Model")
		model.Name, model.Parent = "StudioMutationPreview", session.world.model
		session.preview = model
		local soil = world.part(model, "PreviewSoil", Vector3.new(8, 0.5, 7), session.world.origin + Vector3.new(0, 1.4, 13), Color3.fromRGB(83, 53, 40), Enum.Material.Ground)
		soil.CanCollide = false
		local crop = Instance.new("Model")
		crop.Name, crop.Parent = "PreviewCrop", model
		local view = { soil = soil, crop = crop, label = world.label(soil, "", 2) }
		world.render(view, { stage = 3, cropId = "Tomato", plantedAt = os.clock() - 10 }, config)
		view.label.Text = "STUDIO PREVIEW\nReveal in 3 seconds"
		feedback:FireClient(player, { kind = "Notice", text = mutationId .. " preview in 3 seconds • Look toward the garden" })
		task.delay(3, function()
			if sessions[player] ~= session or session.preview ~= model or not model.Parent then return end
			world.render(view, { stage = 4, cropId = "Tomato", mutation = mutationId }, config)
			view.label.Text = string.upper(mutationId) .. " • PREVIEW\nVisual only • No rewards"
			feedback:FireClient(player, { kind = "Ready", mutation = mutationId, position = soil.Position, text = string.upper(mutationId) .. " MUTATION!", preview = true })
		end)
		return mutationId .. " preview scheduled. Same reveal as gameplay; no rewards or probability changes."
	end
	command.Parent = ServerStorage
end

return StudioPreview
