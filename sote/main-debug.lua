local queue = require 'engine.queue'

print('Testing queues...')

local q = queue:new()

local function small_stress()
	for i = 1, 100 do
		q:enqueue(i)
	end

	while q:length() > 0 do
		q:dequeue()
	end
end

small_stress()
small_stress()
small_stress()
small_stress()

print('Queues tested!')
