local pg = {}

---Runs pop aging on all pops in a single province
---@param province Province
function pg.age(province)
	for _, pp in pairs(province.all_pops) do
		pp.age = pp.age + 1
	end
	for _, pp in pairs(province.outlaws) do
		pp.age = pp.age + 1
	end
end

return pg
