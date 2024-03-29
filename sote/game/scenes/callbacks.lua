local cb = {}

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