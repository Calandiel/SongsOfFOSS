local ed = {}

---Initializes education on realms (so that we don't need to wait decades for research to happen...)
function ed.run()
	DATA.for_each_realm(function (item)
		-- Run education for one month...
		require "game.society.education".run(item)
		local required = DATA.realm_get_budget_target(item, BUDGET_CATEGORY.EDUCATION)
		DATA.realm_set_budget_budget(item, BUDGET_CATEGORY.EDUCATION, required)
	end)
end

return ed
