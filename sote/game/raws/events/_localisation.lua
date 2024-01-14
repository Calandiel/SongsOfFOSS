local ut = require "game.ui-utils"

local text = {}


---Character prepares to explore local province and chooses how he will proceed
---@param self table
---@param character Character
---@param associated_data Province
function text.exploration_preparation(self, character, associated_data)
	return "I plan to explore the province "
		.. associated_data.name
		.. ". We have following options:"
end


---Character explores local province and reports to himself of exploration progress
---@param self table
---@param character Character
---@param associated_data ExplorationData
function text.exploration_progress(self, character, associated_data)
	return "I am currently exploring the province "
		.. associated_data.explored_province.name
		.. "."
		.. " I estimate that exploration will take roughly "
		.. tostring(math.floor(associated_data._exploration_days_left / 30 / character.leading_warband:size()))
		.. " months."
		.. " We have enough supplies for "
		.. ut.to_fixed_point2(character.leading_warband:days_of_travel())
		.. " days of exploration"
end

---Character prepares to explore local province and chooses how he will proceed
---@param self table
---@param character Character
---@param associated_data ExplorationData
function text.exploration_result(self, character, associated_data)
	return "My party finished exploration of the local province"
end


---Character was asked by explorer about local lands
---@param self table
---@param character Character
---@param associated_data ExplorationData
function text.exploration_ask_locals_local(self, character, associated_data)
	return associated_data.explorer.name .. " asked me about local area."
end


---Character receives an answer from a local character and decides his further actions
---@param self table
---@param character Character
---@param associated_data ExplorationData
function text.exploration_ask_locals_explorer_payment(self, character, associated_data)
	local conversation = associated_data.last_conversation
	if conversation == nil then
		error("Conversation was not set")
	end

	local payment_string = tostring(ut.to_fixed_point2(conversation.payment)) .. MONEY_SYMBOL;

	return "Local person asked us for a payment: "
		.. payment_string
		.. " in exchange for information."
end


---Character receives help from a local character in his exploration
---@param self table
---@param character Character
---@param associated_data ExplorationData
function text.exploration_ask_locals_explorer_help_received(self, character, associated_data)
	local conversation = associated_data.last_conversation
	if conversation == nil then
		error("Conversation was not set")
	end

	return "Local person " .. conversation.partner.name .. " provided me with directions."
end



function text.option_okay(self, character, associated_data)
	return "Fine"
end
function text.tooltip_okay(self, character, associated_data)
	return "Get back to whatever I was doing"
end


---Character was paid for his help in exploration
---@param self table
---@param character Character
---@param associated_data ExplorationData
---@return function
function text.exploration_helper_payment_received(self, character, associated_data)
	return function()
		return "I got " .. ut.to_fixed_point2(associated_data.last_conversation.payment)
		.. MONEY_SYMBOL .. " of wealth."
	end
end

---Character was paid for his help in exploration
---@param self table
---@param character Character
---@param associated_data nil
---@return string
function text.tax_collection_1(self, character, associated_data)
	return "I was collecting taxes on behalf of " .. character.realm.leader.name .. ". " ..
		"I have already collected a sizable amount but I can collect even more taxes and keep them myself." ..
		" My reputation among our people will suffer even more but as long I am on a good side of "
		.. character.realm.leader.name .. " it's probably fine."
end


return text