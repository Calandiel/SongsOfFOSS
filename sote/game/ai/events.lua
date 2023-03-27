local ev = {}

---@param realm Realm
function ev.run(realm)
	for _, ev in pairs(WORLD.events_by_name) do
		if ev.automatic then
			if love.math.random() < ev.base_probability then
				if ev:trigger(realm) then
					ev:on_trigger(realm)
				end
			end
		end
	end
end

return ev
