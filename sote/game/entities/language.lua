local string = require "engine.string"

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
local SAMPLES_ranks = 5

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


lang.Language = {}
lang.Language.__index = lang.Language

---Returns a new language
---@return language_id
function lang.Language:new()
	local language = DATA.create_language()

	local o = DATA.fatten_language(language)
	o.syllables = {}
	o.consonants = {}
	o.vowels = {}
	o.ending_province = {}
	o.ending_realm = {}
	o.ending_adj = {}
	o.ranks = {}

	return language
end

---Returns a randomized language
---@return language_id
function lang.random()
	local language = lang.Language:new()

	local fat = DATA.fatten_language(language)

	for _, v in ipairs(VOWELS) do
		if _ <= MIN_V or love.math.random() < DROPOFF_V then
			table.insert(fat.vowels, v)
		else
			break
		end
	end

	for _, v in ipairs(CONSONANTS) do
		if _ <= MIN_C or love.math.random() < DROPOFF_C then
			table.insert(fat.consonants, v)
		else
			break
		end
	end

	for _, v in ipairs(SyllableType) do
		if _ <= MIN_S or love.math.random() < DROPOFF_S then
			table.insert(fat.syllables, v)
		else
			break
		end
	end

	-- generate several random province suffixes, and ditto for realms
	for _ = 1, SAMPLES_ending_province do
		table.insert(fat.ending_province, lang.Language.random_word(language, 1))
	end
	for _ = 1, SAMPLES_ending_realm do
		table.insert(fat.ending_realm, lang.Language.random_word(language, 1))
	end
	for _ = 1, SAMPLES_ending_adj do
		table.insert(fat.ending_adj, lang.Language.random_word(language, 1))
	end
	for _ = 1, SAMPLES_ending_adj do
		table.insert(fat.ending_adj, lang.Language.random_word(language, 1))
	end
	for _ = 1, SAMPLES_ranks do
		table.insert(fat.ranks, lang.Language.random_word(language, 3))
	end

	return language
end

---@param language language_id
---@return string
function lang.Language.random_vowel(language)
	local fat_language = DATA.fatten_language(language)
	return fat_language.vowels[love.math.random(#fat_language.vowels)]
end

---@param language language_id
---@return string
function lang.Language.random_consonant(language)
	local fat_language = DATA.fatten_language(language)
	return fat_language.consonants[love.math.random(#fat_language.consonants)]
end

---@param language language_id
---@return string
function lang.Language.random_syllable(language)
	local fat_language = DATA.fatten_language(language)
	return fat_language.syllables[love.math.random(#fat_language.syllables)]
end

---@param language language_id
---@param word_length number
---@return string
function lang.Language.random_word(language, word_length)
	local fat_language = DATA.fatten_language(language)
	local w = ""
	for _ = 1, word_length do
		local syl = lang.Language.random_syllable(language)
		if syl == 'V' then
			w = w .. lang.Language.random_vowel(language)
		elseif syl == 'CV' then
			w = w .. lang.Language.random_consonant(language) .. lang.Language.random_vowel(language)
		elseif syl == 'CrV' then
			w = w .. lang.Language.random_consonant(language) .. 'r' .. lang.Language.random_vowel(language)
		elseif syl == 'CVn' then
			w = w .. lang.Language.random_consonant(language) .. lang.Language.random_vowel(language) .. 'n'
		elseif syl == 'CnV' then
			w = w .. lang.Language.random_consonant(language) .. 'n' .. lang.Language.random_vowel(language)
		elseif syl == 'ClV' then
			w = w .. lang.Language.random_consonant(language) .. 'l' .. lang.Language.random_vowel(language)
		elseif syl == 'CVl' then
			w = w .. lang.Language.random_consonant(language) .. lang.Language.random_vowel(language) .. 'l'
		elseif syl == 'CVr' then
			w = w .. lang.Language.random_consonant(language) .. lang.Language.random_vowel(language) .. 'r'
		elseif syl == 'CVC' then
			w = w .. lang.Language.random_consonant(language) .. lang.Language.random_vowel(language) .. lang.Language.random_consonant(language)
		elseif syl == 'VC' then
			w = w .. lang.Language.random_vowel(language) .. lang.Language.random_consonant(language)
		end
	end
	return w
end
---@param language language_id
function lang.Language.get_random_culture_name(language)
	local fat_language = DATA.fatten_language(language)
	local ll = love.math.random(3)
	local n = lang.Language.random_word(language, ll)
	return string.title(n .. fat_language.ending_adj[love.math.random(#fat_language.ending_adj)])
end
---@param language language_id
function lang.Language.get_random_faith_name(language)
	local fat_language = DATA.fatten_language(language)
	local ll = love.math.random(3)
	local n = lang.Language.random_word(language, ll)
	return string.title(n .. fat_language.ending_adj[love.math.random(#fat_language.ending_adj)])
end
---@param language language_id
function lang.Language.get_random_realm_name(language)
	local fat_language = DATA.fatten_language(language)
	local ll = love.math.random(3)
	local n = lang.Language.random_word(language, ll)
	return string.title(n .. fat_language.ending_realm[love.math.random(#fat_language.ending_realm)])
end
---@param language language_id
function lang.Language.get_random_province_name(language)
	local fat_language = DATA.fatten_language(language)
	local ll = love.math.random(3)
	local n = lang.Language.random_word(language, ll)
	return string.title(n .. fat_language.ending_province[love.math.random(#fat_language.ending_province)])
end
---@param language language_id
function lang.Language.get_random_name(language)
	local fat_language = DATA.fatten_language(language)
	local ll = love.math.random(4)
	local n = lang.Language.random_word(language, ll)
	return string.title(n)
end

return lang
