
local string = {}

---
---@param str string
---@param start string
---@return boolean
function string.starts_with(str, start)
	return str:sub(1, #start) == start
end

---
---@param str string
---@param ending string
---@return boolean
function string.ends_with(str, ending)
	return ending == "" or str:sub(-#ending) == ending
end

---
---@param str string
---@return string, number count
function string.patternescape(str)
	return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

---comment
---@param str string
---@param chars ?string
---@return string
function string.trim(str, chars)
	if not chars then return str:match("^[%s]*(.-)[%s]*$") end
	chars = string.patternescape(chars)
	return str:match("^[" .. chars .. "]*(.-)[" .. chars .. "]*$")
end

---
---@param str string
function string.title(str)
    return (str:gsub("^%l", str.upper))
end

return string