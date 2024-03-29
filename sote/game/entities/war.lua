---@class (exact) War
---@field __index War
---@field attackers table<Realm, Realm> A set of all attackers
---@field defenders table<Realm, Realm> A set of all defenders
---@field claims table<Province, Realm> A table mapping provinces to their claimants. When the war ends, the winning side will enforce their claims.

---@class War
local war = {
	attackers = {},
	defenders = {},
	claims = {}
}
war.__index = war

---@return War
function war:new()
	local o = {}
	for k, v in pairs(self) do
		if type(v) == "table" then
			o[k] = {}
		elseif type(v) == "function" then
			-- nothing to do, we're setting a metatable
		else
			o[k] = v
		end
	end
	setmetatable(o, war)
	return o
end

return war
