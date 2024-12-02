local de = {}

---Runs decisions for this realm
---@param realm Realm
function de.run(realm)
	-- 1. Loop through all realms (on the call site of this function!)
	-- 2. Loop through all decisions
	for _, decision in pairs(RAWS_MANAGER.decisions_by_name) do
		---@type DecisionRealm
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


---Runs decisions for this character
---@param character Character
function de.run_character(character)
	---#logging LOGS:write("decisions " .. tostring(character) .. "\n")
	---#logging LOGS:flush()
	-- 1. Loop through all characters (on the call site of this function!)
	-- 2. Loop through all decisions
	-- local offending_decisions = {"sell-something"}
	for _, decision in pairs(RAWS_MANAGER.decisions_characters_by_name) do
	-- for _, dec_name in pairs(offending_decisions) do

		---@type DecisionCharacter
		local d = decision

		-- local decision = RAWS_MANAGER.decisions_characters_by_name[dec_name]
		-- local d = decision


		-- 3. Check base probability (AI only) << base_probability >>
		if love.math.random() < d.base_probability then
			PROFILER:start_timer(d.name)
			-- if true then
			-- 4. Check pretrigger << pretrigger >>

			---#logging LOGS:write("check pretrigger " .. decision.name .. "\n")
			---#logging LOGS:flush()
			if d.pretrigger(character) then
				local fails = 0
				while fails < d.ai_targetting_attempts do
					-- 5. Select target (AI only) << ai_target >>
					---#logging LOGS:write("select target " .. decision.name .. "\n")
					---#logging LOGS:flush()
					local target, success = d.ai_target(character)
					if success then
						-- 6. Check visibility << visible >>
						---#logging LOGS:write("check clickability " .. decision.name  .. tostring(target) .. "\n")
						---#logging LOGS:flush()
						if d.clickable(character, target) then
							-- 7. Select secondary target (AI only) << ai_secondary_target >>
							local secondary_target, secondary_success = d.ai_secondary_target(character, target)
							if secondary_success then
								-- 8. Check if the decision is "available"
								---#logging LOGS:write("check availability ".. decision.name .. "\n")
								---#logging LOGS:flush()
								if d.available(character, target, secondary_target) then
									-- 9. Check action probability (AI only) << ai_will_do >>
									---#logging LOGS:write("check ai willingness ".. decision.name .. "\n")
									---#logging LOGS:flush()
									local will_do = d.ai_will_do(character, target, secondary_target)
									assert(will_do ~= nil, d.name .. " returned nil ai_will_do")
									if love.math.random() < will_do then
										-- 10. Apply decisions << effect >>
										---#logging LOGS:write("decision " .. d.name .. "\n")
										---#logging LOGS:flush()
										d.effect(character, target, secondary_target)
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
			PROFILER:end_timer(d.name)
		end
	end
end

return de
