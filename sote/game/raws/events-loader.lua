local tabb = require "engine.table"
local ll = {}

local function log_stage(msg)
	if RAWS_MANAGER.do_logging then
		print(msg)
	end
end

function ll.load()
	local Event = require "game.raws.events"

	-- For automatic events:
	-- 1. Roll against << base_probability >>
	-- 2. Check << trigger >>
	-- 3. Apply << on_trigger >>
	-- ...
	-- For events in the queue
	-- 1. Check if it applies to the player
	-- 2. If it doesn't, get the option with the highest ai score
	-- 3. Apply

	log_stage("lack needs events")
	require "game.raws.events.lack-events" ()

	log_stage("war events")
	require "game.raws.events.war-events" ()

	log_stage("outlaw events")
	require "game.raws.events.outlaw-events" ()

	log_stage("raid events")
	require "game.raws.events.raid-events" ()

	log_stage("misc. events")
	require "game.raws.events.coup" ()

	log_stage("interpersonal events")
	require "game.raws.events.interpersonal"()

	log_stage("administration events")
	require "game.raws.events.administration"()

	log_stage("migration events")
	require "game.raws.events.migration"()

	log_stage("health events")
	require "game.raws.events.health"()

	log_stage("succession events")
	require "game.raws.events.succession"()

	log_stage("travel events")
	require "game.raws.events.travel"()

	log_stage("events")
	require "game.raws.events._loader"()

	log_stage("auxilary events")
	require "game.raws.events.helpers"()
end

return ll
