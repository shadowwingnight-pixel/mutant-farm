-- Storage-independent session ownership protocol; injectable for deterministic tests.
local ProfileStore = {}
ProfileStore.__index = ProfileStore

function ProfileStore.new(backend, schema, config, options)
	return setmetatable({ backend = backend, schema = schema, config = config,
		now = options.now, wait = options.wait, token = options.token,
		leaseSeconds = options.leaseSeconds or 180, attempts = options.attempts or 3 }, ProfileStore)
end

function ProfileStore:unpack(record)
	if record == nil then return self.schema.decode(nil, self.config) end
	if type(record) ~= "table" then return nil, "Invalid stored record" end
	if record.recordVersion == nil then
		if record.lock ~= nil then return nil, "Unrecognized legacy lock" end
		return self.schema.decode(record, self.config)
	end
	if record.recordVersion ~= 1 then return nil, "Unsupported record version" end
	if record.lock ~= nil and (type(record.lock) ~= "table" or type(record.lock.token) ~= "string"
		or type(record.lock.expires) ~= "number" or record.lock.expires ~= record.lock.expires
		or record.lock.expires == math.huge or record.lock.expires < 0) then return nil, "Invalid session lock" end
	if record.data == nil then return nil, "Missing profile data" end
	return self.schema.decode(record.data, self.config)
end

function ProfileStore:load(key)
	local token = self.token()
	local reason = "Data service unavailable"
	for attempt = 1, self.attempts do
		local ok, record = pcall(function()
			return self.backend:UpdateAsync(key, function(old)
				local data, problem = self:unpack(old)
				if not data then reason = problem; return nil end
				if old and old.lock and old.lock.token ~= token and old.lock.expires > self.now() then
					reason = "Profile is open in another server"; return nil
				end
				return { recordVersion = 1, data = data, lock = { token = token, expires = self.now() + self.leaseSeconds }, lastWrite = old and old.lastWrite }
			end)
		end)
		if ok and record and record.lock and record.lock.token == token then
			return { key = key, token = token, data = record.data, expires = record.lock.expires, sequence = 0 }
		end
		if not ok then reason = "Data service unavailable" end
		if attempt < self.attempts then self.wait(attempt * 2) end
	end
	return nil, reason -- No profile is returned; defaults can never become a save source.
end

function ProfileStore:save(profile, snapshot, release)
	if profile.closed or profile.lost then return false, "Session unavailable" end
	if profile.saving then return false, "Save in progress" end
	if type(snapshot) ~= "table" then return false, "Missing save snapshot" end
	local data, problem = self.schema.decode(snapshot, self.config)
	if not data then return false, problem end
	profile.saving = true
	profile.sequence += 1
	local writeId = profile.token .. ":" .. profile.sequence
	local reason = "Data service unavailable"
	for attempt = 1, self.attempts do
		local ok, record = pcall(function()
			return self.backend:UpdateAsync(profile.key, function(old)
				local valid = self:unpack(old)
				if not valid or not old or old.recordVersion ~= 1 then reason = "Stored profile changed"; return nil end
				-- Retrying an ambiguous successful write must never replay its snapshot.
				if old.lastWrite == writeId then return old end
				if not old.lock or old.lock.token ~= profile.token or old.lock.expires <= self.now() then
					reason = "Session ownership lost"; return nil
				end
				local lock = nil
				if not release then lock = { token = profile.token, expires = self.now() + self.leaseSeconds } end
				return { recordVersion = 1, data = data, lock = lock, lastWrite = writeId }
			end)
		end)
		if ok and record and record.lastWrite == writeId then
			profile.saving = false
			if release then profile.closed = true; return true end
			if record.lock and record.lock.token == profile.token then profile.expires = record.lock.expires; return true end
			reason = "Session ownership lost"
		end
		if reason == "Session ownership lost" or reason == "Stored profile changed" then profile.lost = true; break end
		if attempt < self.attempts then self.wait(attempt * 2) end
	end
	profile.saving = false
	return false, reason
end

return ProfileStore
