local queue = require 'engine.queue'

print('Testing queues...')

---@type Queue<number>
local q = queue:new()

local function small_stress()
	for i = 1, 1000000 do
		q:enqueue(i)
	end

	while q:length() > 0 do
		q:dequeue()
	end
end

local function stack_test()
	for i = 1, 5 do
		q:enqueue_front(i)
	end

	local t = 0

	while q:length() > 0 do
		print(q:dequeue())
		t = t + 1
	end
end

stack_test()
stack_test()

small_stress()
small_stress()
small_stress()
small_stress()

small_stress()
small_stress()
small_stress()
small_stress()

small_stress()
small_stress()
small_stress()
small_stress()

print('Queues tested!')
