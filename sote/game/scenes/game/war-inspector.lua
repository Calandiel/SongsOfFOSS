local re = {}
local tabb = require "engine.table"
local ui = require "engine.ui"
local uit = require "game.ui-utils"

---@return Rect
local function get_main_panel()
	local fs = ui.fullscreen()
	local panel = fs:subrect(0, 0, 750, 400, "left", 'down')
	return panel
end

---Returns whether or not clicks on the planet can be registered.
---@return boolean
function re.mask()
	if ui.trigger(get_main_panel()) then
		return false
	else
		return true
	end
end

---@param gam GameScene
function re.draw(gam)
	---@diagnostic disable-next-line: assign-type-mismatch
	local wwar = gam.selected.war
	if wwar ~= nil then
		---@type War
		local war = wwar
		local panel = get_main_panel()
		ui.panel(panel)

		if uit.icon_button(ASSETS.icons["cancel.png"], panel:subrect(0, 0, uit.BASE_HEIGHT, uit.BASE_HEIGHT, "right", 'up')) then
			gam.click_tile(-1)
			gam.selected.building = nil
			gam.inspector = nil
		end


		local ui_panel = panel:subrect(5, uit.BASE_HEIGHT, panel.width - 10, panel.height - 10 - uit.BASE_HEIGHT,
			"left", 'up')
		local tabs = {
			{
				text = "GEN",
				tooltip = "General",
				closure = function()
					local width = 200
					-- ATTACKERS
					local pp = ui_panel:copy()
					pp.width = width
					ui.panel(pp)
					pp.height = uit.BASE_HEIGHT
					ui.text_panel("Attackers", pp)
					-- Draw the scrollview
					pp.height = ui_panel.height - uit.BASE_HEIGHT
					pp.y = pp.y + uit.BASE_HEIGHT
					gam.war_attacker_scrollbar = gam.war_attacker_scrollbar or 0
					gam.war_attacker_scrollbar = uit.scrollview(pp, function(i, rect)
						if i > 0 then
							---@type Realm
							local rr = tabb.nth(war.attackers, i)
							local ww = rect.width
							rect.width = rect.height
							if uit.coa(rr, rect) then
								gam.inspector = "realm"
								gam.selected.realm = rr
							end
							rect.width = ww - rect.height - 5
							rect.x = rect.x + rect.height + 5
							ui.text_panel(rr.name, rect)
						end
					end, uit.BASE_HEIGHT, tabb.size(war.attackers),
						uit.BASE_HEIGHT, gam.war_attacker_scrollbar)
					pp.y = pp.y - uit.BASE_HEIGHT

					-- DEFENDERS
					pp.x = pp.x + ui_panel.width - pp.width
					pp.height = ui_panel.height
					ui.panel(pp)
					pp.height = uit.BASE_HEIGHT
					ui.text_panel("Defenders", pp)
					-- Draw the scrollview
					pp.height = ui_panel.height - uit.BASE_HEIGHT
					pp.y = pp.y + uit.BASE_HEIGHT
					gam.war_defender_scrollbar = gam.war_defender_scrollbar or 0
					gam.war_defender_scrollbar = uit.scrollview(pp, function(i, rect)
						if i > 0 then
							---@type Realm
							local rr = tabb.nth(war.defenders, i)
							local ww = rect.width
							rect.width = rect.height
							if uit.coa(rr, rect) then
								gam.inspector = "realm"
								gam.selected.realm = rr
							end
							rect.width = ww - rect.height - 5
							rect.x = rect.x + rect.height + 5
							ui.text_panel(rr.name, rect)
						end
					end, uit.BASE_HEIGHT, tabb.size(war.defenders),
						uit.BASE_HEIGHT, gam.war_defender_scrollbar)
					pp.y = pp.y - uit.BASE_HEIGHT

					local bb = ui_panel:subrect(0, 0, ui_panel.width - 2 * width, uit.BASE_HEIGHT, "center", 'down')
					bb.width = bb.width / 3
					if uit.text_button("Surrender", bb) then

					end
					bb.x = bb.x + bb.width
					if uit.text_button("White peace", bb) then

					end
					bb.x = bb.x + bb.width
					if uit.text_button("Enforce demands", bb) then

					end
				end
			},
		}
		local layout = ui.layout_builder()
			:position(panel.x, panel.y)
			:spacing(2)
			:horizontal()
			:build()
		gam.war_inspector_tab = gam.war_inspector_tab or "GEN"
		gam.war_inspector_tab = uit.tabs(gam.war_inspector_tab, layout, tabs, 1)

	end
end

return re
