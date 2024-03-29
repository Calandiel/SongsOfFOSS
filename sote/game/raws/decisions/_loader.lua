return function ()
	require "game.raws.decisions.debug._loader"()
	require "game.raws.decisions.party._loader"()
	require "game.raws.decisions.military._loader"()
	require "game.raws.decisions.economy._loader"()

	require "game.raws.decisions.war-decisions" ()
	require "game.raws.decisions.character-decisions" ()
	require "game.raws.decisions.office-decisions" ()
	require "game.raws.decisions.diplomacy" ()
	require "game.raws.decisions.interpersonal" ()
	require "game.raws.decisions.travel" ()
end