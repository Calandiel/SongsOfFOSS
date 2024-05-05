local waterbody = {}

function waterbody:new()
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	return obj
end

return waterbody