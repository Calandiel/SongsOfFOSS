local ed = {}

---Initializes education on realms (so that we don't need to wait decades for research to happen...)
function ed.run()
	for _, realm in pairs(WORLD.realms) do
		-- Run education for one month...
		require "game.society.education".run(realm)
		realm.education_endowment = realm.education_endowment_needed
	end
end

return ed
