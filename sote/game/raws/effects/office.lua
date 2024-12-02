local message_effect = require "game.raws.effects.messages"
local politics_effects = require "game.raws.effects.politics"

local effect = {}



---commenting
---@param character Character
function effect.fire_tax_collector(character)
	local collector = DATA.get_tax_collector_from_collector(character)
	local realm = DATA.tax_collector_get_realm(collector)

	politics_effects.small_popularity_decrease(character, realm)
	message_effect.on_tax_collector_fired(character, realm)

	DATA.delete_tax_collector(collector)
end

return effect