---@generic T
---@class Queue<T> : {(new: fun():Queue<T>), data:table<number,T>, first:integer, last:integer, enqueue:fun(self:Queue, element:T), enqueue_front:fun(self:Queue, element:T), (length:fun(self:Queue):integer), clear:fun(self), (dequeue:fun(self:Queue):T), (peek:fun(self:Queue):T)}

local Queue = {}
Queue.__index = Queue
---Returns a new queue
---@return Queue
function Queue:new()
	local q = {}

	q.first = 0
	q.last = 0
	q.data = {}

	setmetatable(q, Queue)
	return q
end


function Queue:optimize()

end

---Enqueues an element
---@param element any
function Queue:enqueue(element)
	self.last = self.last + 1
	self.data[self.last] = element

	-- if self.last % 1000000 == 0 then 
	-- 	print(self.last) 
	-- end
end

---Enqueues an element IN FRONT of the queue
function Queue:enqueue_front(element)
	if self:length() > 0 then
		self.data[self.first] = element
		self.first = self.first - 1
	else
		self:enqueue(element)
	end
end

---Dequeues an element and returns it
-- -@return any
function Queue:dequeue()
	self.first = self.first + 1

	local result = self.data[self.first]
	self.data[self.first] = nil

	return result
end

---Returns an element without dequeuing it
---@return any
function Queue:peek()
	return self.data[self.first + 1]
end

---Returns the length of the queue
---@return integer
function Queue:length()
	return self.last - self.first
end

---Clears the queue
function Queue:clear()
	self.first = 0
	self.last = 0
	for k, _ in pairs(self.data) do
		self.data[k] = nil
	end
end


return Queue
