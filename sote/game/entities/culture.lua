local cl = {}

---@class (exact) CultureGroup
---@field __index CultureGroup
---@field name string
---@field r number
---@field g number
---@field b number
---@field language Language
---@field view_on_treason number

---@class (exact) Culture
---@field __index Culture
---@field name string
---@field r number
---@field g number
---@field b number
---@field language Language
---@field culture_group CultureGroup
---@field traditional_units table<string, number> -- Defines "traditional" ratios for units recruited from this culture.
---@field traditional_militarization number A fraction of the society that cultures will try to put in military
---@field traditional_foraging_target table<string, number> a culture's prefered foraging targets
---@field traditional_foraging_return number a culture's cutoff value for foraging targets value

---@class CultureGroup
cl.CultureGroup = {}
cl.CultureGroup.__index = cl.CultureGroup
---@return CultureGroup
function cl.CultureGroup:new()
	---@type CultureGroup
	local o = {}

	o.r = love.math.random()
	o.g = love.math.random()
	o.b = love.math.random()
	o.language = require "game.entities.language".random()
	o.name = o.language:get_random_culture_name()

	o.view_on_treason = love.math.random(-20, 0)

	setmetatable(o, cl.CultureGroup)
	return o
end

---@class Culture
cl.Culture = {}
cl.Culture.__index = cl.Culture
---@param group CultureGroup
---@return Culture
function cl.Culture:new(group)
	---@type Culture
	local o = {}

	o.r = group.r
	o.g = group.g
	o.b = group.b
	o.culture_group = group
	o.language = group.language
	o.name = o.language:get_random_culture_name()
	o.traditional_units = {}
	o.traditional_militarization = 0.1
	o.traditional_foraging_return = 0

	setmetatable(o, cl.Culture)
	return o
end

---@param pop POP
---@return string tooltip
function cl.Culture:text_tooltip(pop)
	local ut = require "game.ui-utils"
	local tabb = require "engine.table"
	local eff = pop.race.male_efficiency
	local average_return_per_cost = self.traditional_foraging_return
	if pop.female then
		eff = pop.race.female_efficiency
	end
	return "\nTraditional Military: (" .. ut.to_fixed_point2(self.traditional_militarization * 100) .. "% of population)"
		.. tabb.accumulate(self.traditional_units, "", function (a, k, v)
			return a .. "\n · " .. ut.to_fixed_point2(v * 100) .. "% " .. k .. ", "
		end)
		.. "\nTraditional Foraging Targets: " .. " (" .. ut.to_fixed_point2(average_return_per_cost) .. "% minimum)"
		.. tabb.accumulate(self.traditional_foraging_target, "", function (a, k, v)
			if v > average_return_per_cost then
				return a .. "\n  ¤ " .. k .. ": " ..  ut.to_fixed_point2(v) .. "%"
			end
			return a
		end)
end

return cl
