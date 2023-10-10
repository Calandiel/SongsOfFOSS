
---@class POP
---@field race Race
---@field faith Faith
---@field culture Culture
---@field female boolean
---@field age number
---@field name string
---@field savings number
---@field popularity number
---@field traits table<Trait, Trait>
---@field employer Building?
---@field loyalty POP?
---@field leading_warband Warband?
---@field job Job?
---@field new fun(self:POP, race:Race, faith:Faith, culture:Culture, female:boolean, age:number?):POP
---@field get_age_multiplier fun(self:POP):number
---@field drafted boolean "Drafted" state refers to whether or not a pop is currently drafted for military duty. For example, for raids or "real" warfare.
---@field province Province? Only for characters
---@field realm Realm? Only for characters. Represents the home realm of the character
---@field rank CHARACTER_RANK?

local rtab = {}

---@class POP
rtab.POP = {}
rtab.POP.__index = rtab.POP
---Creates a new POP
---@param race Race
---@param faith Faith
---@param culture Culture
---@param female boolean
---@param age number?
---@return POP
function rtab.POP:new(race, faith, culture, female, age)
	age = age or 0

	---@type POP
	local r = {}
	r.race = race
	r.faith = faith
	r.culture = culture
	r.female = female
	r.age = age

	r.name = culture.language:get_random_name()
	r.savings = 0
	r.popularity = 0
	r.loyalty = nil
	r.traits = {}

	setmetatable(r, rtab.POP)

	return r
end

function rtab.POP:get_age_multiplier()
	local age_multiplier = 1
	if self.age < self.race.child_age then
		age_multiplier = 0.1 -- baby
	elseif self.age < self.race.teen_age then
		age_multiplier = 0.5 -- child
	elseif self.age < self.race.adult_age then
		age_multiplier = 0.75 -- teen
	elseif self.age < self.race.middle_age then
		age_multiplier = 1 -- adult
	elseif self.age < self.race.elder_age then
		age_multiplier = 0.95 -- middle age
	elseif self.age < self.race.max_age then
		age_multiplier = 0.9 -- elder
	end
	return age_multiplier
end

return rtab
