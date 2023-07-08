local lang = {}

local VOWELS = { 'a', 'e', 'i', 'o', 'u' }
local CONSONANTS = { 'q', 'w', 'r', 't', 'y', 'p', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'z', 'x', 'c', 'v', 'b', 'n',
	'm' }
local SyllableType = { 'V', 'CV', 'CrV', 'CVn', 'CnV', 'ClV', 'CVC', 'VC' }

---@class Language
---@field syllables table<number, string>
---@field consonants table<number, string>
---@field vowels table<number, string>
---@field new fun(self:Language):Language
---@field random_vowel fun(self:Language):string
---@field random_consonant fun(self:Language):string
---@field random_syllable fun(self:Language):string
---@field random_word fun(self:Language, word_length:number):string
---@field get_random_culture_name fun(self:Language):string
---@field get_random_faith_name fun(self:Language):string
---@field get_random_realm_name fun(self:Language):string
---@field get_random_province_name fun(self:Language):string
---@field get_random_name fun(self:Language):string

---@type Language
lang.Language = {}
lang.Language.__index = lang.Language
---Returns a new language
---@return Language
function lang.Language:new()
	local o = {}

	o.syllables = {}
	o.consonants = {}
	o.vowels = {}

	setmetatable(o, lang.Language)
	return o
end

---Returns a randomized language
---@return Language
function lang.random()
	local l = lang.Language:new()

	for _, v in ipairs(VOWELS) do
		if love.math.random() > 0.5 then
			table.insert(l.vowels, v)
		end
	end
	if #l.vowels == 0 then
		table.insert(l.vowels, VOWELS[1])
	end

	for _, v in ipairs(CONSONANTS) do
		if love.math.random() > 0.5 then
			table.insert(l.consonants, v)
		end
	end
	if #l.consonants == 0 then
		table.insert(l.consonants, CONSONANTS[1])
	end

	for _, v in ipairs(SyllableType) do
		if love.math.random() > 0.5 then
			table.insert(l.syllables, v)
		end
	end
	if #l.syllables == 0 then
		table.insert(l.syllables, SyllableType[1])
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
	local endings = {
		'ean', 'an', 'ish', 'ese', 'ic', 'ench'
	}
	return n .. endings[love.math.random(#endings)]
end

function lang.Language:get_random_faith_name()
	local ll = love.math.random(3)
	local n = self:random_word(ll)
	local endings = {
		'ism', 'ism', 'ism', 'ism',
		'ean', 'an', 'am', 'ic', 'y'
	}
	return n .. endings[love.math.random(#endings)]
end

function lang.Language:get_random_realm_name()
	local ll = love.math.random(3)
	local n = self:random_word(ll)
	local endings = {
		'', '', '', '', '', '', '', '',
		'land', 'land', 'land', 'land',
		'ance', 'ance', 'ance',
		'ia', 'ia', 'ia', 'ia',
		'gard', 'gard', 'stan'
	}
	return n .. endings[love.math.random(#endings)]
end

function lang.Language:get_random_province_name()
	local ll = love.math.random(3)
	local n = self:random_word(ll)
	local endings = {
		'', '', '', '', '', '', '', '',
		'pol', 'gard', 'holm', 'hold', 'is', 'on',
		'ow', 'ice', 'an'
	}
	return n .. endings[love.math.random(#endings)]
end

function lang.Language:get_random_name()
	local ll = love.math.random(4)
	local n = self:random_word(ll)
	return n
end

return lang
