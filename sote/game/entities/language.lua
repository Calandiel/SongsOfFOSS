local lang = {}

-- dropoff coefficients control how fast the "cutoff" happens
-- for determining which phonemes make it into the language
-- https://www.desmos.com/calculator/hf7rx0ihhk
local DROPOFF_C = 0.96 -- EV = 17
local DROPOFF_V = 0.87 -- EV = 5
local DROPOFF_S = 0.80 -- EV = 3
-- at a minimum, the first N phonemes of this class will be included
local MIN_C = 6
local MIN_V = 3
local MIN_S = 2
-- how many suffixes to generate for each semantic category
local SAMPLES_ending_province = 10
local SAMPLES_ending_realm = 10
local SAMPLES_ending_adj = 5

-- sort phonemes by frequency; ie. common phonemes first, then rarer ones
local VOWELS = {
	'a', 'i', 'u', 'e', 'o', 'y', 'á', 'í', 'ú', 'é',
	'ó' }
local CONSONANTS = {
	'm', 'k', 'j', 'p', 'w', 'b', 'h', 'g', 'n', 's',
	't', 'f', 'l', 'r', 'd', 'z', 'c', 'v', 'ś', 'ż',
	'ź', 'ń', 'q', 'x' }
local SyllableType = {
	'V', 'CV', 'CVn', 'CVr', 'CVl', 'CVC', 'VC' } -- , 'CrV', 'CnV', 'ClV'

---@class (exact) Language
---@field __index Language
---@field syllables table<number, string>
---@field consonants table<number, string>
---@field vowels table<number, string>
---@field ending_province table<number, string>
---@field ending_realm table<number, string>
---@field ending_adj table<number, string>

---@class Language
lang.Language = {}
lang.Language.__index = lang.Language
---Returns a new language
---@return Language
function lang.Language:new()
	local o = {}

	o.syllables = {}
	o.consonants = {}
	o.vowels = {}
	o.ending_province = {}
	o.ending_realm = {}
	o.ending_adj = {}

	setmetatable(o, lang.Language)
	return o
end

---Returns a randomized language
---@return Language
function lang.random()
	local l = lang.Language:new()

	for _, v in ipairs(VOWELS) do
		if _ <= MIN_V or love.math.random() < DROPOFF_V then
			table.insert(l.vowels, v)
		else
			break
		end
	end

	for _, v in ipairs(CONSONANTS) do
		if _ <= MIN_C or love.math.random() < DROPOFF_C then
			table.insert(l.consonants, v)
		else
			break
		end
	end

	for _, v in ipairs(SyllableType) do
		if _ <= MIN_S or love.math.random() < DROPOFF_S then
			table.insert(l.syllables, v)
		else
			break
		end
	end

	-- generate several random province suffixes, and ditto for realms
	for _ = 1, SAMPLES_ending_province do
		table.insert(l.ending_province, l:random_word(1))
	end
	for _ = 1, SAMPLES_ending_realm do
		table.insert(l.ending_realm, l:random_word(1))
	end
	for _ = 1, SAMPLES_ending_adj do
		table.insert(l.ending_adj, l:random_word(1))
	end

	return l
end

---@return string
function lang.Language:random_vowel()
	return self.vowels[love.math.random(#self.vowels)]
end

---@return string
function lang.Language:random_consonant()
	return self.consonants[love.math.random(#self.consonants)]
end

---@return string
function lang.Language:random_syllable()
	return self.syllables[love.math.random(#self.syllables)]
end

---@param word_length number
---@return string
function lang.Language:random_word(word_length)
	local w = ""
	for _ = 1, word_length do
		local syl = self:random_syllable()
		if syl == 'V' then
			w = w .. self:random_vowel()
		elseif syl == 'CV' then
			w = w .. self:random_consonant() .. self:random_vowel()
		elseif syl == 'CrV' then
			w = w .. self:random_consonant() .. 'r' .. self:random_vowel()
		elseif syl == 'CVn' then
			w = w .. self:random_consonant() .. self:random_vowel() .. 'n'
		elseif syl == 'CnV' then
			w = w .. self:random_consonant() .. 'n' .. self:random_vowel()
		elseif syl == 'ClV' then
			w = w .. self:random_consonant() .. 'l' .. self:random_vowel()
		elseif syl == 'CVl' then
			w = w .. self:random_consonant() .. self:random_vowel() .. 'l'
		elseif syl == 'CVr' then
			w = w .. self:random_consonant() .. self:random_vowel() .. 'r'
		elseif syl == 'CVC' then
			w = w .. self:random_consonant() .. self:random_vowel() .. self:random_consonant()
		elseif syl == 'VC' then
			w = w .. self:random_vowel() .. self:random_consonant()
		end
	end
	return w
end

function lang.Language:get_random_culture_name()
	local ll = love.math.random(3)
	local n = self:random_word(ll)
	return n .. self.ending_adj[love.math.random(#self.ending_adj)]
end

function lang.Language:get_random_faith_name()
	local ll = love.math.random(3)
	local n = self:random_word(ll)
	return n .. self.ending_adj[love.math.random(#self.ending_adj)]
end

function lang.Language:get_random_realm_name()
	local ll = love.math.random(3)
	local n = self:random_word(ll)
	return n .. self.ending_realm[love.math.random(#self.ending_realm)]
end

function lang.Language:get_random_province_name()
	local ll = love.math.random(3)
	local n = self:random_word(ll)
	return n .. self.ending_province[love.math.random(#self.ending_province)]
end

function lang.Language:get_random_name()
	local ll = love.math.random(4)
	local n = self:random_word(ll)
	return n
end

return lang
