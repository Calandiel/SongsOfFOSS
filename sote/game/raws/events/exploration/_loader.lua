local Event = require "game.raws.events"
local E_ut = require "game.raws.events._utils"

---@class ExplorationConversationData
---@field payment number
---@field partner Character
---@field lied boolean

---@class ExplorationData
---@field explorer Character
---@field explored_province Province
---@field last_conversation ExplorationConversationData?
---@field _exploration_days_left number
---@field _exploration_speed number days/person

return function()
	require "game.raws.events.exploration.ask_locals"()
	require "game.raws.events.exploration.explore"()

end