local values = {}

---commenting
---@param pop POP
function values.calories_food_need(pop)
	for i = 1, MAX_NEED_SATISFACTION_POSITIONS_INDEX do
		local need = DATA.pop_get_need_satisfaction_need(pop, i)
		local use_case = DATA.pop_get_need_satisfaction_use_case(pop, i)

		if need == NEED.INVALID then
			return
		end

		if need == NEED.FOOD and use_case == CALORIES_USE_CASE then
			return DATA.pop_get_need_satisfaction_demanded(pop, i)
		end
	end

	return 0
end

return values