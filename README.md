# Coin Rush

A multiplayer Roblox game: every round, coins appear around an arena and the
player who collects the most wins. Everything (arena, coins, UI) is built from
code, so there are no assets to import.

- Gold/orange coins are worth 5, yellow coins 1, blue pads give a speed boost.
- 90-second rounds with a 10-second intermission; wins show on the leaderboard.
- Tweak everything in `src/shared/Config.luau`.

## Run it
1. Install [Rojo](https://rojo.space) (`aftman add rojo-rbx/rojo` or the VS Code extension).
2. Open Roblox Studio, create a new Baseplate place and delete the default Baseplate.
3. Run `rojo serve` in this folder, then click **Connect** in the Rojo Studio plugin.
4. Press **Play** (use Test > Clients and Servers to try multiplayer).
5. To publish: File > Publish to Roblox.

Or run `rojo build -o CoinRush.rbxlx` and open the file directly.
