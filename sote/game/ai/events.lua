local ev = {}

---@param realm Realm
function ev.run(realm)
	DATA.for_each_realm_provinces_from_realm(realm, function (item)
		local province = DATA.realm_provinces_get_province(item)
		DATA.for_each_character_location_from_location(province, function (location)
			local character = DATA.character_location_get_character(location)
			for _, ev in pairs(RAWS_MANAGER.events_by_name) do
				if ev.automatic then
					if love.math.random() < ev.base_probability then
						if ev:trigger(character) then
							ev:on_trigger(character)
						end
					end
				end
			end
		end)
	end)
end

return ev
