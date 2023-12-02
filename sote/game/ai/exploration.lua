local tabb = require "engine.table"
local EconomicEffects = require "game.raws.effects.economic"
local ex = {}

---@param realm Realm
function ex.run(realm)
	-- Only attempt exploration once a year by default
	-- if love.math.random() < 1.0 / 12.0 then
	-- 	local cc = tabb.size(realm.known_provinces)
	-- 	local prov = tabb.nth(realm.known_provinces, love.math.random(cc))

	-- 	if prov then
	-- 		local cost = realm:get_explore_cost(prov)
	-- 		if realm.budget.treasury > cost then
	-- 			-- if love.math.random() < cost / realm.treasury then
	-- 				EconomicEffects.change_treasury(realm, -cost, EconomicEffects.reasons.Exploration)
	-- 				realm:explore(prov)
	-- 			-- end
	-- 		end
	-- 	end
	-- end
end

return ex
