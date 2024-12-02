local ut = require "game.ui-utils"

local warband_utils = require "game.entities.warband"

local political_values = require "game.raws.values.politics"
local economy_values = require "game.raws.values.economy"

local text = {}


---Character prepares to explore local province and chooses how he will proceed
---@param self table
---@param character Character
---@param associated_data Province
function text.exploration_preparation(self, character, associated_data)
	return "I plan to explore the province "
		.. PROVINCE_NAME(associated_data)
		.. ". We have following options:"
end


---Character explores local province and reports to himself of exploration progress
---@param self table
---@param character Character
---@param associated_data ExplorationData
function text.exploration_progress(self, character, associated_data)
	return "I am currently exploring the province "
		.. PROVINCE_NAME(associated_data.explored_province)
		.. "."
		.. " I estimate that exploration will take roughly "
		.. tostring(math.floor(associated_data._exploration_days_left / warband_utils.size(LEADER_OF_WARBAND(character))))
		.. " days."
		.. " We have enough supplies for "
		.. ut.to_fixed_point2(economy_values.days_of_travel(LEADER_OF_WARBAND(character)))
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
	return NAME(associated_data.explorer) .. " asked me about local area."
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

	return "Local person " .. NAME(conversation.partner) .. " provided me with directions."
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
	return "I was collecting taxes on behalf of " .. NAME(LEADER(REALM(character))) .. ". " ..
		"I have already collected a sizable amount but I can collect even more taxes and keep them myself." ..
		" My reputation among our people will suffer even more but as long I am on a good side of "
		.. NAME(LEADER(REALM(character))) .. " it's probably fine."
end


function text.request_tribute(self, character, associated_data)
	---@type Character
	associated_data = associated_data

	local name = NAME(associated_data)
	local temp = "him"
	if DATA.pop_get_female(associated_data) then
		temp = "her"
	end

	local my_warlords, my_power = political_values.military_strength(character)
	local their_warlords, their_power = political_values.military_strength(associated_data)

	local strength_estimation_string =
		"There are " .. my_warlords .. " warlords on my side with total strength of " .. my_power
		.. " warriors. And on their side there are " .. their_warlords .. " warlords with total strength of "
		.. their_power	.. " warriors."
	return name	.. " requested me to pay tribute to " .. temp .. ". "
		.. strength_estimation_string .. " What should I do?"
end

function text.request_tribute_refusal(self, character, associated_data)
	---@type Character
	associated_data = associated_data

	local name = NAME(associated_data)
	local my_warlords, my_power = political_values.military_strength(character)
	local their_warlords, their_power = political_values.military_strength(associated_data)

	local strength_estimation_string =
		"There are "
		.. my_warlords
		.. " warlords on my side with total strength of "
		.. my_power
		.. " warriors. And on their side there are "
		.. their_warlords
		.. " warlords with total strength of "
		.. their_power
		.. " warriors."

	return name
		.. " refused to pay tribute to me. "
		.. strength_estimation_string
		.. " What should I do?"
end

function text.not_a_leader()
	return "I'm not a leader of the tribe"
end

function text.negotiation_not_a_tributary()
	return "We are not the tributary of them"
end


---Produces a string which summarizes current negotiation
---@param negotiation NegotiationData
function text.negotiation_string(negotiation)

	local trade_string_initiator = ""
	if negotiation.negotiations_terms_characters then
		trade_string_initiator = NAME(negotiation.initiator) .. " will: \n"
		for good, amount in pairs(negotiation.negotiations_terms_characters.trade.goods_transfer_from_initiator_to_target) do
			if amount > 0 then
				trade_string_initiator = trade_string_initiator ..
					"- Transfer " .. tostring(amount) .. " of " .. DATA.trade_good_get_name(good) .. "\n"
			end
		end

		if negotiation.negotiations_terms_characters.trade.wealth_transfer_from_initiator_to_target > 0 then
			trade_string_initiator = trade_string_initiator ..
				"- Transfer "
				.. tostring(negotiation.negotiations_terms_characters.trade.wealth_transfer_from_initiator_to_target)
				.. " of wealth \n"
		end
	end

	local trade_string_target = ""
	if negotiation.negotiations_terms_characters then
		trade_string_target = NAME(negotiation.target) .. " will: \n"
		for good, amount in pairs(negotiation.negotiations_terms_characters.trade.goods_transfer_from_initiator_to_target) do
			if amount < 0 then
				trade_string_target = trade_string_target ..
					"- Transfer " .. tostring(-amount) .. " of " .. DATA.trade_good_get_name(good) .. "\n"
			end
		end

		if negotiation.negotiations_terms_characters.trade.wealth_transfer_from_initiator_to_target < 0 then
			trade_string_target = trade_string_target ..
				"- Transfer "
				.. tostring(-negotiation.negotiations_terms_characters.trade.wealth_transfer_from_initiator_to_target)
				.. " of wealth \n"
		end
	end

	local realm_string = ""

	-- diplomacy
	for _, item in ipairs(negotiation.negotiations_terms_realms) do

		if item.free then
			realm_string = realm_string ..
			"- ".. REALM_NAME(item.root) .. " will set " .. REALM_NAME(item.target) .. " free. \n"
		end

		if item.subjugate then
			realm_string = realm_string ..
			"- ".. REALM_NAME(item.target) .. " will recognise " .. REALM_NAME(item.root) .. " as an overlord. \n"
		end

		realm_string = realm_string .. "These realms will will negotiate a following trade agreement \n"
		local trade_realm_string_initiator = NAME(negotiation.initiator) .. " will: \n"
		for good, amount in pairs(item.trade.goods_transfer_from_initiator_to_target) do
			if amount > 0 then
				trade_realm_string_initiator = trade_realm_string_initiator ..
					"- Transfer " .. tostring(amount) .. " of " .. DATA.trade_good_get_name(good) .. "\n"
			end
		end
		if item.trade.wealth_transfer_from_initiator_to_target > 0 then
			trade_realm_string_initiator = trade_realm_string_initiator ..
				"- Transfer "
				.. tostring(item.trade.wealth_transfer_from_initiator_to_target)
				.. " of wealth \n"
		end
		local trade_realm_string_target = NAME(negotiation.target) .. " will: \n"
		for good, amount in pairs(item.trade.goods_transfer_from_initiator_to_target) do
			if amount < 0 then
				trade_realm_string_target = trade_realm_string_target ..
					"- Transfer " .. tostring(-amount) .. " of " .. DATA.trade_good_get_name(good) .. "\n"
			end
		end
		if item.trade.wealth_transfer_from_initiator_to_target < 0 then
			trade_realm_string_target = trade_realm_string_target ..
				"- Transfer "
				.. tostring(-item.trade.wealth_transfer_from_initiator_to_target)
				.. " of wealth \n"
		end

		realm_string = realm_string .. trade_realm_string_initiator .. trade_realm_string_target .. "\n"
	end

	local character_realm_string = "Also, \n"

	for _, item in ipairs(negotiation.negotiations_terms_character_to_realm) do
		if item.trade_permission then
			character_realm_string = character_realm_string
			.. NAME(negotiation.initiator)
			.. " will be allowed to trade in lands of "
			.. REALM_NAME(item.target)
			.. "\n"
		end

		if item.building_permission then
			character_realm_string = character_realm_string
			.. NAME(negotiation.initiator)
			.. " will be allowed to build in lands of "
			.. REALM_NAME(item.target)
			.. "\n"
		end
	end

	return trade_string_initiator .. trade_string_target .. realm_string .. character_realm_string



	-- maybe it could be reused later
	--[[
	if status.goods_transfer then
		current_status_string = current_status_string .. "Transfer a part of their stockpile to overlord. \n"
	end
	if status.wealth_transfer then
		current_status_string = current_status_string .. "Transfer a part of their wealth to overlord. \n"
	end
	if status.warriors_contribution then
		current_status_string = current_status_string .. "Provide overlord with warriors. \n"
	end

	if status.protection then
		current_status_string = current_status_string .. "Overlord is obliged to protect them. \n"
	end

	if status.local_ruler then
		current_status_string = current_status_string .. "Subject's ruler is decided locally. \n"
	else
		current_status_string = current_status_string .. "Subject's ruler is decided by overlord. \n"
	end
	]]--
end

function text.negotiate(self, character, associated_data)
	---@type Character
	character = character

	---@type NegotiationData
	associated_data = associated_data

	local intro = "INITIATOR: " .. NAME(associated_data.initiator) .. " NEGOTIATION PARTNER: " .. NAME(associated_data.target) .. ".\n"

	return intro .. "Current negotiation draft: \n" .. text.negotiation_string(associated_data)
end

function text.negotiate_adjustment(self, character, associated_data)
	---@type Character
	character = character

	---@type NegotiationData
	associated_data = associated_data

	local intro = "We got response from " .. NAME(associated_data.target) .. ".\n"


	return intro .. "He presented us with a following adjusted negotiation draft: \n" .. text.negotiation_string(associated_data)
end

function text.negotiation_status_quo()
	return "Or maybe we don't want any changes after all."
end

function text.negotiation_agree()
	return "We agree with the new terms"
end

function text.negotiation_disagree()
	return "We disagree with the new terms"
end

---@param self table
---@param character Character
---@param negotiation_data NegotiationData
---@return string
function text.target_accepts(self, character, negotiation_data)
	return NAME(character) .. " accepted our offer"
end

function text.negotiation_back_down(self, character, negotiation_data)
	return "I decided to back down"
end

---@param self table
---@param character Character
---@param negotiation_data NegotiationData
---@return string
function text.target_declines(self, character, negotiation_data)
	return NAME(character) .. " declined our offer"
end


function text.add_personal_term_option(self, character, negotiation_data)
	return "Add new personal term"
end

function text.add_personal_term_option_tooltip(self, character, negotiation_data)
	return "Personal goods or wealth exchange."
end

function text.add_realm_term_option(self, character, negotiation_data)
	return "Add new realm-related term"
end

function text.add_realm_term_option_tooltip(self, character, negotiation_data)
	return "Diplomacy"
end

function text.send_negotiation_terms_tooltip(self, character, negotiation_data)
	return "Send your terms to your target"
end

return text