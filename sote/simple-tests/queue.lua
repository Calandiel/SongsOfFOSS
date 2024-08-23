local queue = require "engine.queue"

print('Testing queues...')


local function test_clear()
	local q = queue:new()

	q:enqueue_front(1)

	q:clear()

	q:enqueue_front(1)

	if (q:length() == 1) then
		print("OK: CLEAR LENGTH TEST")
	else
		print("ERROR: CLEAR LENGTH TEST")
	end
end


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
	q:enqueue_front(1)
	if (q:length() == 1) then
		print("OK: enqueue front length test")
	else
		print("ERROR: enqueue front length test")
	end

	q:clear()

	for i = 1, 5 do
		q:enqueue_front(i)
	end

	local t = 0

	while q:length() > 0 do
		print(q:dequeue())
		t = t + 1
	end
end

test_clear()

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
