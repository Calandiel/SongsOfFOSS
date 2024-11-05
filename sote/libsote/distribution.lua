local distrib = {}

--- Creates a discrete distribution sampler function based on given probabilities.
---@param probabilities number[] The probabilities representing the discrete probability distribution.
---@return fun(): number A function that, when called, samples from the distribution according to the specified probabilities.
function distrib.create_discrete_distribution(probabilities, rng)
	-- Construct the cumulative distribution function (CDF)
	local cdf = {}
	local cumulative = 0
	for i, probability in ipairs(probabilities) do
		cumulative = cumulative + probability / 100
		cdf[i] = cumulative
	end

	return function()
		local rnd = rng:random()
		for i, p in ipairs(cdf) do
			if rnd <= p then
				return i
			end
		end
		return #probabilities + 1
	end
end

return distrib