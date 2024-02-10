# SongsOfGPL

Songs of GPL is a FOSS release of [Songs of the Eons](https://demiansky.itch.io/songs-of-the-eons).

It's written in Lua and includes the game part of the project, notably not including the original world generator.

# Running the game

On Windows, double click `run-sote-windows.bat`.

On Linux, run `./run-sote-linux.sh`.

# Contributing

## Setting up the LSP

SotE uses [Lua LSP](https://github.com/LuaLS/lua-language-server). Make sure you have it installed and working before contributing.

If you see warnings such as "undefined global love", see the following [link](https://github.com/LuaLS/lua-language-server/wiki/Libraries#manually-applying) and apply the love2d library to your LSP settings.
