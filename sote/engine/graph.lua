local gr = {}

---@class (exact) OneToOne A class which maps a 1:1 relationship
---@field __index OneToOne
---@field new fun(self: OneToOne):OneToOne
---@field set fun(self: OneToOne, a: any, b: any)
---@field get fun(self: OneToOne, a: any):any
---@field _a table<any, any>

---@class OneToOne
gr.OneToOne = {}
gr.OneToOne.__index = gr.OneToOne

function gr.OneToOne:new()
	local o = {}

	o._a = {}

	setmetatable(o, gr.OneToOne)
	return o
end

function gr.OneToOne:set(a, b)
	local old_a = self._a[a]
	if old_a ~= nil then
		self._a[old_a] = nil
	end
	local old_b = self._a[b]
	if old_b ~= nil then
		self._a[old_b] = nil
	end
	self._a[a] = b
	self._a[b] = a
end

function gr.OneToOne:get(a)
	return self._a[a]
end

---@class (exact) OneToMany A class which maps a 1:MANY relationship. For example, "mother" vs "children" or "tiles" to "provinces"
---@field __index OneToMany
---@field new fun(self: OneToOne):OneToMany
---@field set fun(self: OneToMany, one: any, many: any)
---@field get_many fun(self: OneToMany, one: any):(any|nil)
---@field get_ones fun(self: OneToMany, many: any):(table<any, any>|nil)
---@field _ones table<any, any>
---@field _manys table<any, table<any, any>>

---@class OneToMany
gr.OneToMany = {}
gr.OneToMany.__index = gr.OneToMany

function gr.OneToMany:new()
	local o = {}

	o._ones = {}
	o._manys = {}

	setmetatable(o, gr.OneToMany)
	return o
end

function gr.OneToMany:set(one, many)
	local old = self._ones[one]

	if old ~= nil then
		self._manys[old][one] = nil
	end
	if self._manys[many] == nil then
		self._manys[many] = {}
	end
	self._manys[many][one] = one
end

---Returns the "many" to which the "one" belongs (if any)
function gr.OneToMany:get_many(one)
	return self._ones[one]
end

---Returns a table of all elements of the "many" (if any)
function gr.OneToMany:get_ones(many)
	return self._manys[many]
end

return gr
