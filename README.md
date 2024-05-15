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

# Roadmap

- **Done**
- *Doing*
- Not started

## Abandoned features

Some of the previously implemented features that show up on the roadmap below have been dropped, either due design considerations, new insight on performance or lack of time:
- Multiplayer - the feature was never highly desired by the community and after we left the Unity engine, it didn't make sense to invest time into it
- Wiki - we didn't have enough community contributors to justify maintaining it ourselves
- Animal POPs and animal migrations - we can infer most needed data from evapotranspiration and productivity of flora
- Map editor - we can import PNGs for maps directly now so an editor isn't needed
- Frontiers on feral/settled province borders - we simulate hunter gatherer tribes as realms instead so the feature would make the simulation aspect worse
- Mac support - we don't have a Mac computer to sign the binaries, should be possible to bring this back later

## Version 0.0 (Ginnungagap)

- **Prelimenary terrain generation**
- **Prelimenary oceanography**
- **Basic UI**
- **Planet renderer**
- **C++/C# interopability**

## Version 0.1 (Muspelheim)

- **Mapmodes**
- **Tile view**
- **Hotspots**
- **Erosion**
- **Water movement on land**
- **Simple limestone islands**
- **Detailed orogeny and terrain generation**
- **Detailed oceanography**
- **Climate simulation**
- **Wiki rework**
- **Subreddit rework**

## Version 0.2 (Niflheim)

- **Lakes**
- **Rivers**
- **Flood Plains**
- **Fjords and Rias**
- **Ice Age Geography**
- **Glaciers**
- **Dynamic snow**
- **"Mediterranean" Seas**
- **Prelimenary ecology**
- **Soil organics**
- **Resource generation based on geology (metals)**
- **Biome generation**
- **Province generation**
- **Basic networking**
- **In-game chat for multiplayer**
- **Taunts for multiplayer chat**
- **Improved climate generation**
- **Droughts, heat waves, cold snaps and other extreme weather events**
- **Ocean Currents - a static model was implemented for the purposes of world generation, will be revisited and improved in future updates**
- **Rocks types**
- **Sediments**
- **Volcanic ash generation**
- **Soil moisture**
- **Modding support for races**
- **Modding support for resources**
- **"Harmony" based mods**
- **UI rework**
- **Rendering optimization**
- **Faster map mode switching**
- **River rendering**
- **Accurate glaciations**
- **Alluvial soils**
- **Soil texture (clay-silt-sand)**
- **Mineral richness calculations for soil**
- **"True colour" map mode**
- **Prelimenary map editor - mostly to explore the idea. Not really feature complete in this update**
- **Plant and biomass placement**
- **Placement of initial sentient POPs**
- **Prelimenary realms**
- **Preliminary culture generation**
- **Preliminary religion generation**
- **Preliminary language generation**
- **Ability to start the game and progress time**
- **Varying game speeds**
- **Checksums and compatibility tests in multiplayer**
- **Province and realm borders**

Version 0.3 (Midgard)

- **Watertables**
- **Character portraits**
- **Out-of-sync detection**
- **Portrait modding**
- **Simple playable characters**
- **Prelimenary economics**
- **Simple gift economies**
- **Primitive currencies**
- **Prices fully driven by supply and demand**
- **Simple migration model**
- **"Early stone age" technologies**
- **"Late stone age" technologies**
- **Support for technology modding**
- **Placeholder buildings**

## Version 0.4 (Helheim)

- **Further, flora-based climate refinements**
- Prelimenary placement of magical resources
- More detailed migration and population dynamics
- Plagues and diseases
- Simulation of technological advancement/decay during world generation
- More detailed characters
- **More complex production model**
- Families
- **"Antiquity" technologies**
- **Warbands**

## Version 0.5 (Alfheim)

- Accessibility features for colourblind people
- **Linux support**
- Placement of magical resources
- "Iron era" technologies
- Finish porting the worldgen out of C++

## Version 0.6 (Jotunheim)

- "Early medieval" technologies
- Artifacts and heroes
- Magic

## Version 0.7 (Svartalfheim)

- "High medieval" technologies
- Detailed governments
- Laws

## Version 0.8 (Vanaheim)

- "Renaissance" technologies
- Detailed internal politics
- A more accurate battle solver

## Version 0.9 (Asgard)

- "Enlightement" technologies
- Naval warfare
- Naval battle solver
- Tectonics code update

## Alpha
- UI/UX polish based on player feedback
- General bugfixing

## Beta
- More UI/UX polish based on player feedback

## Version 1.0 (Yggdrasil)

- Post-release support
