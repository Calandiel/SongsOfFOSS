local de = {}

---Runs decisions for this realm
---@param realm Realm
function de.run(realm)
	-- 1. Loop through all realms (on the call site of this function!)
	-- 2. Loop through all decisions
	for _, decision in pairs(WORLD.decisions_by_name) do
		---@type Decision
		local d = decision
		-- 3. Check base probability (AI only) << base_probability >>
		if love.math.random() < d.base_probability then
			-- 4. Check pretrigger << pretrigger >>
			if d.pretrigger(realm) then
				local fails = 0
				while fails < d.ai_targetting_attempts do
					-- 5. Select target (AI only) << ai_target >>
					local target, success = d.ai_target(realm)
					if success then
						-- 6. Check visibility << visible >>
						if d.clickable(realm, target) then
							-- 7. Select secondary target (AI only) << ai_secondary_target >>
							local secondary_target, secondary_success = d.ai_secondary_target(realm, target)
							if secondary_success then
								-- 8. Check if the decision is "available"
								if d.available(realm, target, secondary_target) then
									-- 9. Check action probability (AI only) << ai_will_do >>
									if love.math.random() < d.ai_will_do(realm, target, secondary_target) then
										-- 10. Apply decisions << effect >>
										d.effect(realm, target, secondary_target)
										break
									end
								else
									goto CONTINUE
								end
							else
								-- try up to ai_targetting_attempts times!
								goto CONTINUE
							end
						else
							-- 6a. If visibility failed, go back to 5, up to << ai_targetting_attempts >> times (AI only)
							goto CONTINUE
						end
					else
						-- Try up to ai_targetting_attempts times
						goto CONTINUE
					end
					::CONTINUE::
					fails = fails + 1
				end
			end
		end
	end
end

return de
