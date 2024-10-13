local messages = {}


local function generic_losses_function(att_losses, def_losses)
	return "We lost "
			.. tostring(def_losses)
			.. " warriors and our enemies lost "
			.. tostring(att_losses)
			.. ". "
end

---comment
---@param raider Character
---@param raid_target Realm
---@param success boolean
---@param att_losses number
---@param def_losses number
function messages.tribute_raid(raider, raid_target, success, att_losses, def_losses)
	if not WORLD:does_player_see_realm_news(raid_target) then
		return
	end

	local introduction =
		"Our neighbor, "
		.. raider.name
		.. ", sent warriors to extort tribute from us. "
	local losses_string = generic_losses_function(att_losses, def_losses)

	if success then
		WORLD:emit_notification(
			introduction
			.. losses_string
			.. "We lost and have to pay the tribute.")
	else
		WORLD:emit_notification(
			introduction
			.. losses_string
			.. "We managed to fight off the aggresors.")
	end
end

---comment
---@param realm Realm
---@param tributary Realm
function messages.tribute_raid_success(realm, tributary)
	if not WORLD:does_player_see_realm_news(realm) then
		return
	end

	WORLD:emit_notification("We succeeded! " .. tributary.name .. " now pays tribute to us.")
end

---comment
---@param realm Realm
---@param tributary Realm
function messages.tribute_raid_fail(realm, tributary)
	if not WORLD:does_player_see_realm_news(realm) then
		return
	end

	WORLD:emit_notification("We failed! " .. DATA.realm_get_name(tributary) .. " will not pay tribute to us.")
end

function messages.successor_set(character, successor)
	if not WORLD:does_player_see_realm_news(successor) then
		return
	end

	WORLD:emit_notification(
		successor.name .. " was chosen as the successor of " .. character.name .. "."
	)
end

---commenting
---@param character Character
---@param realm Realm
function messages.on_tax_collector_fired(character, realm)
	if WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(DATA.pop_get_name(character) .. " is no longer a tribute collector.")
	end
	if WORLD.player_character == character then
		WORLD:emit_notification("I was fired from the position of tribute collector.")
	end
end

---commenting
---@param initiator Character
---@param fired_person Character
function messages.on_tax_collector_fired_initiator(initiator, fired_person)
	if WORLD.player_character == initiator then
		WORLD:emit_notification("I fired ".. NAME(fired_person) .. " from the position of tribute collector.")
	end
end

---commenting
---@param initiator Character
---@param target Character
function messages.on_overseer_hire_request(initiator, target)
	if WORLD.player_character == initiator then
		WORLD:emit_notification("I asked ".. NAME(target) .. " to assist me in administration.")
	end
	if WORLD.player_character == target then
		WORLD:emit_notification("I was asked to assist " .. NAME(initiator) .. " with administrative tasks.")
	end
end

---commenting
---@param character Character
---@param target Province
function messages.on_donation_to_province(character, target)
	if WORLD.player_character == character then
		WORLD:emit_notification("I donated money to local population. My popularity grows.")
	elseif WORLD:does_player_see_realm_news(PROVINCE_REALM(target)) then
		WORLD:emit_notification(
			NAME(character) .. " donates money to population of " .. DATA.province_get_name(target)
			.. "! His popularity grows..."
		)
	end
end

---commenting
---@param character Character
---@param target Realm
function messages.on_donation_to_realm(character, target)
	if WORLD.player_character == character then
		WORLD:emit_notification("I donated money to local tribe. My popularity grows.")
	elseif WORLD:does_player_see_realm_news(target) then
		WORLD:emit_notification(
			NAME(character) .. " donates money to the tribe of " .. DATA.realm_get_name(target) .. "!"
		)
	end
end

function messages.on_loyalty_removal(character, former_top)
	if WORLD.player_character == former_top then
		WORLD:emit_notification(NAME(character) .. " is no longer loyal to me.")
	end
	if WORLD.player_character == character then
		WORLD:emit_notification("I am no loger loyal to " .. NAME(former_top) .. ".")
	end
end

function messages.on_loyalty_shift(character, former_top, new_top)
	if WORLD.player_character == new_top then
		WORLD:emit_notification(
			NAME(character) .. " sweared loyalty to me. He was formerly loyal to " .. NAME(former_top) .. ".")
	end
	if WORLD.player_character == former_top then
		WORLD:emit_notification(NAME(character) .. " betrayed me. He is loyal to " .. NAME(new_top) .. " now.")
	end
	if WORLD.player_character == character then
		WORLD:emit_notification("I sweared loyalty to " .. NAME(new_top) .. ".")
	end
end

function messages.on_loyalty_new(character, new_top)
	if WORLD.player_character == new_top then
		WORLD:emit_notification(NAME(character) .. " sweared loyalty to me.")
	end
	if WORLD.player_character == character then
		WORLD:emit_notification("I sweared loyalty  to " .. NAME(new_top) .. ".")
	end
end

---commenting
---@param realm Realm
---@param former_overseer Character
---@param new_overser Character
function messages.on_overseer_change(realm, former_overseer, new_overser)
	if WORLD.player_character == former_overseer then
		WORLD:emit_notification("I was fired from overseer position in favor of " .. NAME(new_overser) ".")
	elseif WORLD.player_character == new_overser then
		WORLD:emit_notification(NAME(former_overseer) .. " was fired from overseer position in favor of me.")
	elseif WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(
			NAME(former_overseer) .. " was fired from overseer position in favor"  .. NAME(new_overser) "."
		)
	end
end

---commenting
---@param realm Realm
---@param new_overser Character
function messages.on_overseer_set(realm, new_overser)
	if WORLD.player_character == new_overser then
		WORLD:emit_notification(NAME(new_overser) .. " is now .")
	elseif WORLD:does_player_see_realm_news(realm) then
		WORLD:emit_notification(
			NAME(new_overser) .. " is a new overseer of "  .. DATA.realm_get_name(realm) "."
		)
	end
end

return messages