local function fix(val, threshold)
	if val < 0 then
		return val + threshold
	elseif val >= threshold then
		return val - threshold
	else
		return val
	end
end

local queue_capacity = 10000000

-- The queue is implemented as a circular buffer.
-- The capacity of this buffer is by default set to 10 million
---@generic T
---@class (exact) Queue<T> : {(new: fun():Queue<T>), data:table<number,T>, first:integer, last:integer, enqueue:fun(self:Queue, element:T), enqueue_front:fun(self:Queue, element:T), (length:fun(self:Queue):integer), clear:fun(self), (dequeue:fun(self:Queue):T), (peek:fun(self:Queue):T)}


local Queue = {}
Queue.__index = Queue
---Returns a new queue
---@generic T
---@return Queue<T>
function Queue:new()
	local q = {}

	q.first = 0
	q.last = 0
	q.len = 0
	q.data = {}

	setmetatable(q, Queue)
	return q
end

---Enqueues an element
---@generic T
---@param element T
function Queue:enqueue(element)
	self.last = fix(self.last + 1, queue_capacity)
	self.len = self.len + 1
	self.data[self.last] = element

	-- if self.last % 1000000 == 0 then
	-- 	print(self.last)
	-- end
end

---Enqueues an element IN FRONT of the queue (this is technically a stack then)
---@generic T
---@param element T
function Queue:enqueue_front(element)
	if self:length() > 0 then
		self.data[self.first] = element
		self.first = fix(self.first - 1, queue_capacity)
		self.len = self.len + 1
	else
		self:enqueue(element)
	end
end

---Dequeues an element and returns it
---@generic T
---@return T
function Queue:dequeue()
	-- print("dequeue")
	self.first = fix(self.first + 1, queue_capacity)
	-- print("???")
	self.len = self.len - 1
	-- print("???")
	local ret = self.data[self.first]
	-- print("???")
	self.data[self.first] = nil
	-- print('ok')
	return ret
end

---Returns an element without dequeuing it
---@generic T
---@return T
function Queue:peek()
	return self.data[fix(self.first + 1, queue_capacity)]
end

---Returns the length of the queue
---@generic T
---@return T
function Queue:length()
	return self.len
end

---Returns whether the queue is empty
---@generic T
---@return T
function Queue:is_empty()
	return self.len == 0
end

---Clears the queue
function Queue:clear()
	self.first = 0
	self.last = 0
	self.len = 0
	for k, _ in pairs(self.data) do
		self.data[k] = nil
	end
end

return Queue
