local pg = {}

---Runs pop aging on all pops in a single province
---@param province Province
function pg.age(province)
	for _, pp in pairs(province.all_pops) do
		pp.age = pp.age + 1
		if pp.parent and pp.age >= pp.race.teen_age then
			pp.parent.children[pp] = nil
			pp.parent = nil
		end
	end
	for _, pp in pairs(province.outlaws) do
		pp.age = pp.age + 1
		if pp.age >= pp.race.teen_age then
			pp.parent.children[pp] = nil
			pp.parent = nil
		end
	end
	for _, char in pairs(province.characters) do
		char.age = char.age + 1
	end
end

return pg
