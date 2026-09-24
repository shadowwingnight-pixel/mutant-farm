# Mutant Farm

Milestone 1 prototype: buy Tomato Seeds, plant, grow, mutate, harvest and sell.
**Milestone 1 validated:** the project owner confirmed the required manual
gameplay loop passed in Roblox Studio on 2026-09-25. Milestone 2 has not started.
All progress is session-only (no persistence).

## Source layout

| Directory | Roblox Studio destination |
| --- | --- |
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `src/shared` | `ReplicatedStorage.Shared` |

Use `*.server.luau` for server Scripts, `*.client.luau` for LocalScripts,
and `*.luau` for ModuleScripts. The `.gitkeep` files preserve empty folders
in Git and do not create Roblox instances. Shared code is visible to clients.

## Install Rojo on Windows

Download the Windows ZIP for your architecture from the
[official stable Rojo release](https://github.com/rojo-rbx/rojo/releases/latest).
Extract `rojo.exe` to a dedicated folder such as `C:\Tools\Rojo` and add that
folder to your **user Path** environment variable. Open a new PowerShell
window and run `rojo --version`. No additional toolchain is required.

With Roblox Studio installed and closed, install the matching Studio plugin:

```powershell
rojo plugin install
```

See the [official installation guide](https://rojo.space/docs/v7/getting-started/installation/).

## Connect Roblox Studio

1. In PowerShell, start the local server:

   ```powershell
   Set-Location D:\MutantFarm
   rojo serve default.project.json
   ```

2. Leave that terminal running. Open Roblox Studio and create or open a local
   Baseplate place.
3. In Studio's Plugins toolbar, open **Rojo**. Set the host to `localhost`
   and port to `34872` if prompted, then click **Connect**.
4. If a sync preview or confirmation appears, review it and accept the sync.
5. In Explorer, verify `Server`, `Client`, and `Shared` at the destinations
   listed above. Stop any existing play session and press Play to generate
   your farm and initialize the server/client scripts.
6. When you later add and save Luau files under `src`, Rojo syncs them into
   Studio while connected. Edit source files in this folder for this workflow;
   Studio script edits are not automatically saved back by live sync.

Use **Disconnect** in the plugin and `Ctrl+C` in PowerShell to stop syncing.
The farm is generated in `Workspace.MutantFarms` at runtime. The project does
not map or overwrite Studio-authored Workspace objects.

See the [official live-sync guide](https://rojo.space/docs/v7/getting-started/new-game/#live-syncing-into-studio).

## Optional build

Once Rojo is available, validate and build a local place with:

```powershell
rojo build default.project.json -o build.rbxlx
```

Generated place files are ignored by Git. The repository is local only; no
GitHub repository or remote is required for Studio sync.

## Milestone 1 controls and balance

- Start with 100 Coins and six personal soil plots.
- Green shop: walk close, then press E or tap the prompt to buy one seed (10 Coins).
- Empty soil: walk close and click/tap to plant. Each crop takes 15 seconds,
  with visible stages at 0, 5, 10 and 15 seconds.
- READY soil: click/tap to harvest into your basket.
- Orange stand: press E or tap the prompt to sell the entire basket.
- HUD shows Coins, seeds, Tomatoes, mutation counts, basket value and next action.
- Each player gets a separate farm; other players cannot transact or harvest there.
- Respawning retains session inventory and plants; leaving discards them.

| Mutation | Chance | Sell multiplier | Coins per Tomato |
| --- | --- | --- | --- |
| Normal | 70% | 1x | 18 |
| Golden | 18% | 3x | 54 |
| Giant | 10% | 2x | 36 |
| Crystal | 1.9% | 6x | 108 |
| Cosmic | 0.1% | 20x | 360 |

Balance lives in `src/shared/Config.luau`. Only the server reads authoritative
state, spends seeds/Coins, rolls mutations and grants rewards. Player attributes
are replicated display snapshots, never input. Native clicks/prompts validate
ownership, a living character, distance and a shared action cooldown server-side.
There are no client-to-server inventory or pricing remotes.

`FarmState` contains testable state/economy logic; `FarmWorld` generates primitives;
`Main` handles player lifecycle and interactions; `FarmHUD` displays replicated
state and animates Cosmic stars. No external assets or runtime packages are used.

## Validation and manual acceptance

Status recorded on 2026-09-25:

- Required manual gameplay loop: **PASS**, confirmed by the project owner in
  Roblox Studio (buy Tomato Seed → plant → grow → harvest → sell).
- Rojo build and generated-script layout checks: **PASS** at the implementation checkpoint.
- Standalone Luau compilation/state tests: written but not run; test-tool download was not approved.
- Additional multiplayer, mobile and rare-mutation visual checks below are not yet confirmed.

Run `./tests/validate.ps1` for the build and generated-script layout check.
With the official standalone Luau tools already available, run:

```powershell
./tests/validate.ps1 -LuauDirectory 'PATH_TO_LUAU_TOOLS'
```

This compiles all scripts and runs deterministic state tests, including every
one of the 10,000 possible mutation rolls, one-time payouts and repeat planting.
Rojo build success alone does not prove engine runtime behavior.

Required Studio test (with Rojo connected, start a fresh Play session):

1. Join: verify your farm, six soil plots and HUD showing 100 Coins / 0 seeds / 0 Tomatoes.
2. Walk to the green shop; press E once. Expect 90 Coins / 1 seed.
3. Walk to empty soil and click it. Expect 0 seeds and a sprout.
4. Watch for 15 seconds: sprout → growing → ripening → READY with one mutation label.
5. Click the READY soil. Expect 1 Tomato, its mutation/value in the basket, and empty soil.
6. Walk to the orange stand; press E. Expect an empty basket and Coins increasing
   by the listed sell value (108 total for Normal).
7. Return to the green shop and buy again. Expect 1 seed and 10 fewer Coins.

Additional checks: clicking while growing never harvests early; repeated harvests
or empty sales never duplicate rewards; buying at 0 Coins is refused. Plant all
six plots, harvest/replant, and reset your character. In Studio's two-player test,
verify separate inventories and that another player's plots/shop/sell stand do
not accept your interactions. Try Device Emulator for tap targets and HUD sizing.

Rare appearance preview, without changing probabilities: during Play, switch the
Studio Command Bar to **Server** and run the following. This creates isolated
visual previews only; it does not roll crops or grant inventory/rewards. Stop Play
to discard them. Replace `"Cosmic"` with `"Golden"`, `"Giant"` or `"Crystal"`.

```lua
local W = require(game.ServerScriptService.Server.FarmWorld)
local C = require(game.ReplicatedStorage.Shared.Config)
local p = game.Players:GetPlayers()[1]
local farm = workspace.MutantFarms:FindFirstChild("Farm_" .. p.UserId)
local soil = farm:FindFirstChild("Soil_1")
local preview = Instance.new("Model", workspace)
preview.Name = "MutationPreview"
local base = W.part(preview, "Base", Vector3.new(8, 0.5, 8), soil.Position + Vector3.new(0, 0, 9), Color3.fromRGB(83, 53, 40))
local crop = Instance.new("Model", preview)
W.render({soil = base, label = W.label(base, "Preview", 2), crop = crop}, {stage = 4, cropId = "Tomato", mutation = "Cosmic"}, C)
```

Cosmic should show a violet fruit, glowing shards, sparkling highlights, and a
moving cyan/gold star ring. These additional checks remain available for further
coverage; the required Milestone 1 gameplay loop is validated. Milestone 2 has not started.
