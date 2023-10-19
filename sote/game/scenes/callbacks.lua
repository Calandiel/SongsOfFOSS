local cb = {}

function cb.toggle_raiding_target(game, province)
    return function ()
        game.inspector = 'reward-flag'
        game.flagged_province = province

        game.recalculate_raiding_targets_map()
    end
end

function cb.nothing()
    return function () end
end

function cb.update_map_mode(game, mode)
    return function ()
        game.update_map_mode(mode)
    end
end

function cb.close_map_mode_panel(game)
    return function()
        game.show_map_mode_panel = false
    end
end

return cb