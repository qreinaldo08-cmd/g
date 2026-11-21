# The Monster — Roblox starter project

A Rojo-compatible starter for a multiplayer, non-graphic VR/desktop horror game. One player is the monster; survivors try to last three minutes in the Lab. The initial implementation includes a generated industrial lab, interactive doors that break after monster hits, a simple lobby/round cycle, basic monster grab/defeat effect, and a compact HUD.

## Requirements
- Roblox Studio
- Rojo 7.x and the Rojo Studio plugin (for syncing)

## Open and run
1. Install Rojo and the Studio plugin using their official instructions.
2. From this repository directory run `rojo serve`.
3. In Roblox Studio, open a Baseplate, connect the Rojo plugin to the local server, then sync.
4. Use **Test → Start** with multiple clients to test multiplayer. Set the published experience's max players to 12 in Creator Dashboard / place settings.
5. Publish from Studio when ready. This repository does not publish to your Roblox account.

The Lab is built by the server script at runtime. Replace the generated geometry with authored models later if desired. VR movement is a prototype and should be tested on actual Quest and PCVR hardware; desktop WASD remains available.

## Controls
- Desktop survivors: WASD, mouse look, jump.
- Monster: approach survivors and press E (or the right trigger in VR) to grab.
- Lab doors: use their proximity prompt to open/close; monster can hit a nearby door with E / right trigger until it breaks.
- VR: hold a grip/trigger while moving a hand against a surface to push away from it. Locomotion is intentionally a prototype, not a polished reproduction of another game's movement.

The defeat effect is non-graphic: the avatar is removed and a few neutral, fading cosmetic fragments appear. No blood or realistic injury is used.
