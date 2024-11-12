local messages = require "game.raws.effects.messages"

InterpersonalEffects = {}

---Sets the loyalty of an actor to a target
---@param actor Character
---@param target Character
function InterpersonalEffects.set_loyalty(actor, target)
	--- avoid short (1/2 edges) loops, longer loops are fine

	local loyalty_of_target = DATA.get_loyalty_from_bottom(target)
	local target_loyal_to = DATA.loyalty_get_top(loyalty_of_target)
	if target_loyal_to == actor then
		InterpersonalEffects.remove_loyalty(target)
	end

	local loyalty = DATA.get_loyalty_from_bottom(actor)
	if loyalty == INVALID_ID then
		DATA.force_create_loyalty(actor, target)
		messages.on_loyalty_new(actor, target)
	else
		messages.on_loyalty_shift(actor, DATA.loyalty_get_top(loyalty), target)
		DATA.loyalty_set_top(loyalty, target)
	end
end

---@param actor Character
function InterpersonalEffects.remove_loyalty(actor)
	local loyalty = DATA.get_loyalty_from_bottom(actor)
	if loyalty == INVALID_ID then
		return
	end

	messages.on_loyalty_removal(actor, DATA.loyalty_get_top(loyalty))
	DATA.delete_loyalty(loyalty)
end

---unset loyalty to target of all actors loyal to them
---@param target Character
function InterpersonalEffects.remove_all_loyal(target)
	---@type loyalty_id[]
	local to_remove = {}

	DATA.for_each_loyalty_from_top(target, function (item)
		table.insert(to_remove, item)
	end)

	for _, item in pairs(to_remove) do
		InterpersonalEffects.remove_loyalty(DATA.loyalty_get_bottom(item))
	end
end


---comment
---@param character Character
---@param target Character
function InterpersonalEffects.set_successor(character, target)
	local succession = DATA.get_succession_from_successor_of(character)
	local successor = DATA.succession_get_successor(succession)

	if successor == INVALID_ID then
		DATA.force_create_succession(character, target)
	else
		DATA.succession_set_successor(succession, target)
	end

	messages.successor_set(character, target)
end

return InterpersonalEffects