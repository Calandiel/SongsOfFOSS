local tr = {}

---@param realm Realm
function tr.run(realm)

	local target_monthly_infrastructure_investment = 0
	local target_monthly_court_investment = 0
	local target_monthly_education_investment = 0

	local inc = realm.treasury_real_delta
	local waste = realm.wasted_treasury

	local disposable = inc + waste
	local total = disposable + realm.monthly_court_investment + realm.monthly_education_investment +
		realm.monthly_infrastructure_investment
	total = math.max(0, total)

	-- For now, we'll make the AI distribute income in a way that first priotizes getting 0.25 in infrastructure, 0.25 in court and then a weighted everage for education
	local base = math.max(0, math.min(0.25, total))
	total = total - base
	target_monthly_infrastructure_investment = base

	if total > 0 then
		local base = math.max(0, math.min(0.25, total))
		total = total - base
		target_monthly_court_investment = base

		if total > 0 then
			local p = 1 / 20
			target_monthly_court_investment = target_monthly_court_investment + total * p * 1
			target_monthly_education_investment = target_monthly_education_investment + total * p * 17
			target_monthly_infrastructure_investment = target_monthly_infrastructure_investment + total * p * 2
		end
	end

	-- A relaxation to prevent the AI from "flip flopping" between extremes
	local k = 0.8 -- Fraction "kept" from previous distribution
	local q = 1 - k -- Fraction "coming" from new distribution
	realm.monthly_court_investment = realm.monthly_court_investment * k + target_monthly_court_investment * q
	realm.monthly_education_investment = realm.monthly_education_investment * k +
		target_monthly_education_investment * q
	realm.monthly_infrastructure_investment = realm.monthly_infrastructure_investment * k +
		target_monthly_infrastructure_investment * q
end

return tr
