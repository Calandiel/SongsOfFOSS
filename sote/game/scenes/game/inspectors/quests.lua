local ui = require "engine.ui"
local ut = require "game.ui-utils"
local window = {}

local economic_effects = require "game.raws.effects.economy"

---@return Rect
function window.rect()
	local unit = ut.BASE_HEIGHT
	local fs = ui.fullscreen()
	return fs:subrect(unit * 2, unit * 2, unit * (16 + 4), unit * 34, "left", "up")
end

function window.mask()
	if ui.trigger(window.rect()) then
		return false
	else
		return true
	end
end

---@type TableState
local state = nil

local function init_state(base_unit)
	if state == nil then
		state = {
			header_height = base_unit,
			individual_height = base_unit,
			slider_level = 0,
			slider_width = base_unit,
			sorted_field = 1,
			sorting_order = true
		}
	else
		state.header_height = base_unit
		state.individual_height = base_unit
		state.slider_width = base_unit
	end
end

---@class (exact) QuestData
---@field quest_type "explore"|"raid"|"patrol"
---@field target Province
---@field reward number

local REWARD_AMOUNT = 1
local unit = ut.BASE_HEIGHT

---@type (TableColumn<QuestData>)[]
local columns = {
	{
		header = ".",
		render_closure = function(rect, k, v)
			if v.quest_type == "explore" then
				ut.render_icon(rect:copy():shrink(-1), "horizon-road.png", 1, 1, 1, 1)
				ut.render_icon(rect, "horizon-road.png", 0.5, 1, 0.5, 1)
			end
			if v.quest_type == "raid" then
				ut.render_icon(rect:copy():shrink(-1), "barbute.png", 1, 1, 1, 1)
				ut.render_icon(rect, "barbute.png", 1, 0.5, 0.5, 1)
			end
			if v.quest_type == "patrol" then
				ut.render_icon(rect:copy():shrink(-1), "round-shield.png", 1, 1, 1, 1)
				ut.render_icon(rect, "round-shield.png", 0.5, 0.5, 1, 1)
			end
		end,
		width = unit * 1,
		value = function(k, v)
			return v.quest_type
		end
	},
	{
		header = "Goal",
		render_closure = function(rect, k, v)
			ut.data_entry(v.quest_type, "", rect)
		end,
		width = unit * 4,
		value = function(k, v)
			return v.quest_type
		end
	},
	{
		header = "Target",
		render_closure = function(rect, k, v)
			ui.left_text(v.target.name, rect)
		end,
		width = unit * 6,
		value = function(k, v)
			return v.target.name
		end
	},
	{
		header = "Reward",
		render_closure = function(rect, k, v)
			ut.money_entry("", v.reward or 0, rect)
		end,
		width = unit * 4,
		value = function(k, v)
			return v.reward
		end
	},
	{
		header = "Add reward",
		render_closure = function(rect, k, v)
			local player_character = WORLD.player_character
			if player_character == INVALID_ID then
				return
			end

			---@type string
			local tooltip = "Add reward to this quest: " .. tostring(REWARD_AMOUNT) .. ". \n"

			local can_invest = player_character.savings > REWARD_AMOUNT

			if ut.money_button("", REWARD_AMOUNT, rect, tooltip, can_invest) then
				if v.quest_type == "explore" then
					player_character.realm.quests_explore[v.target] = player_character.realm.quests_explore[v.target] +
					REWARD_AMOUNT
				end
				if v.quest_type == "raid" then
					player_character.realm.quests_raid[v.target] = player_character.realm.quests_raid[v.target] +
					REWARD_AMOUNT
				end
				if v.quest_type == "patrol" then
					player_character.realm.quests_patrol[v.target] = player_character.realm.quests_patrol[v.target] +
					REWARD_AMOUNT
				end

				economic_effects.add_pop_savings(player_character, -REWARD_AMOUNT, ECONOMY_REASON.QUEST)
			end
		end,
		width = unit * 4,
		value = function(k, v)
			return v.reward
		end,
		active = true
	}
}

---Draw character stance window
---@param game GameScene
function window.draw(game)
	local ui_panel = window.rect()
	-- draw a panel
	ui.panel(ui_panel)

	if ut.icon_button(ASSETS.icons["cancel.png"], ui_panel:subrect(0, 0, ut.BASE_HEIGHT, ut.BASE_HEIGHT, "right", "up")) then
		game.inspector = nil
	end

	local width = ui_panel.width

	local vertical_layout = ui.layout_builder()
		:position(ui_panel.x, ui_panel.y)
		:vertical()
		:build()

	local rect_title = vertical_layout:next(width, unit * 2)
	ui.text("Quests", rect_title, "center", "up")

	local quests_table = vertical_layout:next(width, ui_panel.height - unit * 2)

	init_state(unit)

	---@type table<string, QuestData>
	local data_blob = {}

	local character = WORLD.player_character

	assert(character)

	if ui.is_key_held("lshift") or ui.is_key_held("rshift") then
		REWARD_AMOUNT = 5
	elseif ui.is_key_held("lctrl") or ui.is_key_held("rctrl") then
		REWARD_AMOUNT = 50
	else
		REWARD_AMOUNT = 1
	end

	local index = 0
	for target, reward in pairs(character.realm.quests_explore) do
		if reward > 0 then
			data_blob[tostring(index)] = {
				reward = reward,
				quest_type = "explore",
				target = target
			}
		end
		index = index + 1
	end
	for target, reward in pairs(character.realm.quests_raid) do
		if reward > 0 then
			data_blob[tostring(index)] = {
				reward = reward,
				quest_type = "raid",
				target = target
			}
		end
		index = index + 1
	end
	for target, reward in pairs(character.realm.quests_patrol) do
		if reward > 0 then
			data_blob[tostring(index)] = {
				reward = reward,
				quest_type = "patrol",
				target = target
			}
		end
		index = index + 1
	end

	ut.table(quests_table, data_blob, columns, state)
end

return window
