local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local PlayerData = require(script.Parent.PlayerData)
local ProfileStore = require(script.Parent.ProfileStore)
local Persistence = {}
Persistence.__index = Persistence

function Persistence.new(config)
	local studio = RunService:IsStudio()
	local cloud = not studio or workspace:GetAttribute("MutantFarmStudioPersistence") == true
	local prefix, backend, mode
	if studio then
		local slot = workspace:GetAttribute("MutantFarmTestSlot") or "m4-test-01"
		assert(type(slot) == "string" and #slot >= 1 and #slot <= 20 and slot:match("^[%w_-]+$"), "Invalid MutantFarmTestSlot (1-20 letters/digits/_/-)")
		prefix = "test_" .. slot .. "_player_"
		if cloud then
			-- This hard-coded branch cannot select the live data store in Studio.
			backend = DataStoreService:GetDataStore("MutantFarm_StudioTests", "test_v1")
			mode = "Studio cloud • " .. slot
		else
			local memory = {}
			backend = { UpdateAsync = function(_, key, transform)
				local updated = transform(memory[key])
				if updated ~= nil then memory[key] = updated end
				return updated
			end }
			mode = "Studio session only"
		end
	else
		prefix = "player_"
		backend = DataStoreService:GetDataStore("MutantFarm_Players", "live_v1")
		mode = "Cloud save"
	end
	local store = ProfileStore.new(backend, PlayerData, config, {
		now = os.time, wait = task.wait, token = function() return HttpService:GenerateGUID(false) end,
		leaseSeconds = 180, attempts = 3,
	})
	return setmetatable({ store = store, config = config, prefix = prefix, cloud = cloud, mode = mode, autosaveSeconds = 60 }, Persistence)
end

function Persistence:load(player)
	player:SetAttribute("SaveMode", self.mode)
	player:SetAttribute("SaveStatus", "Loading...")
	local profile, problem = self.store:load(self.prefix .. tostring(player.UserId))
	if not profile then return nil, problem end
	player:SetAttribute("SaveStatus", self.cloud and "Loaded" or "Session only • not persistent")
	return profile
end

function Persistence:canPlay(profile)
	return profile and not profile.closed and not profile.lost and profile.expires - os.time() > 15
end

function Persistence:save(player, session, release)
	local profile = session.profile
	if release then
		local deadline = os.clock() + 20
		while profile.saving and os.clock() < deadline do task.wait(0.1) end
	end
	if profile.saving then return false, "Save in progress" end
	local ok, snapshot = pcall(PlayerData.capture, session.state, self.config)
	if not ok then warn("Mutant Farm snapshot rejected: " .. tostring(snapshot)); return false, "Invalid save data" end
	player:SetAttribute("SaveStatus", self.cloud and "Saving..." or "Session only • not persistent")
	local saved, problem = self.store:save(profile, snapshot, release)
	if saved then
		player:SetAttribute("SaveStatus", self.cloud and "Saved" or "Session only • not persistent")
	else
		player:SetAttribute("SaveStatus", "Save failed • retrying")
		warn("Mutant Farm save failed for " .. player.UserId .. ": " .. tostring(problem))
	end
	return saved, problem
end

return Persistence
