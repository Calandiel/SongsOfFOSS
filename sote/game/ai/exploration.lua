local tabb = require "engine.table"
local ex = {}

---@param realm Realm
function ex.run(realm)
	-- Only attempt exploration once a year by default
	if love.math.random() < 1.0 / 12.0 then
		local cc = tabb.size(realm.known_provinces)
		local prov = tabb.nth(realm.known_provinces, love.math.random(cc))

		if prov then
			local cost = realm:get_explore_cost(prov)
			if realm.treasury > 0 then
				if love.math.random() < cost / realm.treasury then
					realm.treasury = math.max(0, realm.treasury - cost)
					realm:explore(prov)
				end
			end
		end
	end
end

return ex
