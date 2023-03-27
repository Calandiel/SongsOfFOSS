--- Just a file for testing sumneko's vscode plugin

---@param tab table
---@return table
---@diagnostic disable-next-line: lowercase-global
function class(tab)
	tab.__index = tab
	tab.new = function(self)
		local r = {}
		for k, v in pairs(tab) do
			if type(v) == "table" then
				r[k] = {}
			else
				r[k] = v
			end
		end
		setmetatable(r, tab)
		return r
	end
	return tab
end

---@class Classy
---@field new fun():Classy
local Classy =
{
	a = 1,
	b = 1,
	c = "owo",
	d = {}, ---@type table<integer, integer>
	e = 1,
}
---@return string
function Classy:debugy()
	return "OwO"
end

---@param i integer
---@return integer
function Classy:mul(i)
	return i * i
end

---@param input number
---@return number
function Classy:debug(input)
	return 12 + input
end

class(Classy)

local cl = Classy:new()
local o = 128
cl.d[1] = 1.78
print(cl:debug(o - cl:mul(o + cl.d[1])))

cl:debugy()

return Classy
