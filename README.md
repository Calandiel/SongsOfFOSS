# SongsOfGPL

Songs of GPL is a FOSS release of [Songs of the Eons](https://demiansky.itch.io/songs-of-the-eons).

It's written in Lua and includes the game part of the project, notably not including the original world generator.

You can reach out to us on [Reddit](https://www.reddit.com/r/SongsOfTheEons/) and [Discord](https://discord.gg/6THT2pa). If you have questions about the project or want to contribute, you can message us in the development channel on Discord! ^^

# Running the game

On Windows, double click `run-sote-windows.bat`.

On Linux, run `./run-sote-linux.sh`.

# Contributing

SotE is open to contributors. Search for a suitable [issue](https://github.com/Calandiel/SongsOfGPL/issues) and ping one of the core contributors in a pull request to get merged!

## Setting up the LSP

SotE uses [Lua LSP](https://github.com/LuaLS/lua-language-server). Make sure you have it installed and working before contributing.

If you see warnings such as "undefined global love", see the following [link](https://github.com/LuaLS/lua-language-server/wiki/Libraries#manually-applying) and apply the love2d library to your LSP settings.
