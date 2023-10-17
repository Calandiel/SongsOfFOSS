local ev = {}

---@param realm Realm
function ev.run(realm)
	for _, province in pairs(realm.provinces) do
		for _, character in pairs(province.characters) do
			for _, ev in pairs(RAWS_MANAGER.events_by_name) do
				if ev.automatic then
					if love.math.random() < ev.base_probability then
						if ev:trigger(character) then
							ev:on_trigger(character)
						end
					end
				end
			end
		end
	end
end

return ev
