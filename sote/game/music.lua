
local mm = {}

CURRENT_TRACK = nil
function mm.update()
	-- Update the currently played track...
	if CURRENT_TRACK == nil or not CURRENT_TRACK:isPlaying() then
		-- update the current song...
		if ASSETS.music ~= nil then
			local ll = #ASSETS.music
			CURRENT_TRACK = ASSETS.music[love.math.random(1, ll)]
			love.audio.play(CURRENT_TRACK)
		end
	end
end

return mm