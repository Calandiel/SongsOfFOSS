# SongsOfGPL

A FOSS release of source code of the unreleased version 0.3 of Songs of the Eons.
Released with permission of the project owner.
Note that this release includes only the unfinished Lua reimplementation on a square tile world.
The 0.2 release relies critically on code that cannot be licensed under GPL and has contributions from people we can't reach anymore. That being said, this codebase still includes some potentially interesting features, such as the climate, vegetation and biome models.
Keep in mind that this build is unfinished and likely won't be worked on in the foreseeable future (though, I will review and merge in any potential merge requests that may come its way).

# Building executable on Windows

- Install [Love2D](https://love2d.org/)
- Make directory `love-windows` in root of repo (next to .sh and .bat files), and copy contents of Love2D install directory to `love-windows`
- Run `run.bat` or call love directly with the command `love-windows/love sote`
- Alternatively, Enter directory `sote`, Select all files, Right-click and "Compress to ZIP file" or "Send to" and then "Compressed (ZIP) folder"
- Rename the ZIP file created in the last step to `sote.zip`
- Cut or Copy `sote.zip` and paste it in the root of the repository (next to .sh and .bat files)
- run `runWin.sh`, may need elevated permissions. Consecutive launches check for existence of built game and if possible start it.

# Unix:

 - `make install` installs the game to `~/.local/bin`
 - `launch_sote` starts the installed game
 - `make uninstall` removes the game from `~/.local/bin`
 - `make clean` clears release folder
