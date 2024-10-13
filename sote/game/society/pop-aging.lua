local pg = {}

---Runs pop aging on all pops
function pg.age()
	DATA.for_each_pop(function (item)
		DATA.pop_inc_age(item, 1)

		local race = DATA.pop_get_race(item)
		local teen_age = DATA.race_get_teen_age(race)

		if DATA.pop_get_age(item) >= teen_age then
			local parent = DATA.get_parent_child_relation_from_child(item)
			if parent ~= INVALID_ID then
				DATA.delete_parent_child_relation(parent)
			end
		end
	end)
end

return pg
