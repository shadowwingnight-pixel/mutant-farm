# Mutant Farm

Buy seeds, plant, grow, mutate, harvest, sell, unlock crops and collect discoveries.
**Milestone 1 validated:** the project owner confirmed the required manual
gameplay loop passed in Roblox Studio on 2026-09-25.
**Milestone 2 validated:** the owner confirmed the complete gameplay loop and mutation preview system passed in Roblox Studio; see [Milestone 2 testing](docs/MILESTONE2.md).

**Milestone 3 validated by the project owner in Roblox Studio.** Tomato → Strawberry → Pumpkin,
seed selection, automatic unlocks and a 15-entry Discovery Book. See [current balance,
controls and manual tests](docs/MILESTONE3.md).

**Milestone 4 validated by the project owner in Roblox Studio:** save/rejoin preserved
progression and purchased farm expansion; the expansion system works. Versioned
server saves and purchasable 6 → 9 → 12 plot farms. Studio defaults to session-only
memory; cloud testing requires an explicit isolated test slot. Follow the
[Milestone 4 safe test instructions](docs/MILESTONE4.md) before enabling cloud tests.
Growing crops reset on leaving; harvest before leaving to retain their value.

**Milestone 5 implemented; Studio validation pending.** Shared day/evening/night,
Clear/Rain/Thunderstorm and temporary Meteor Showers influence server mutation
weights at maturity. See [Living World QA commands and balance](docs/MILESTONE5.md).
Milestone 5 commits remain local; nothing has been published or pushed for this milestone.

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

Generated place files are ignored by Git. GitHub is not required for Studio sync.
Milestones 1–4 are validated; the owner approved pushing the Milestone 4 checkpoint.

## Controls and mutation balance

- Start with 100 Coins and six personal soil plots.
- Green shop: walk close, then press E or tap to browse. Choose a crop and buy seeds.
  Buying selects that crop for planting; close X to return to the farm.
- HUD Seeds button: view unlock progress, or choose an owned seed with **Plant this seed**.
- Empty soil: walk close and click/tap to plant the selected seed. Tomato takes 15 seconds;
  Strawberry 22 and Pumpkin 32. Prices, stages, visuals and unlocks are in Config.
- READY soil: click/tap to harvest into your basket.
- Orange stand: press E or tap the prompt to sell the entire basket.
- Blue farm expansion board: press E or tap; buy nine plots for 500 Coins,
  then twelve for another 1,500 Coins. Each upgrade adds a row and extends the land.
- HUD shows Coins, total seeds, total harvested crops, selected crop and next action.
- Book button: browse discoveries and per-mutation basket counts. Harvesting records a
  combination once; undiscovered entries remain **???**. Selling never erases discoveries.
- Each player gets a separate farm; other players cannot transact or harvest there.
- Respawning retains inventory and plants. Successful cloud saves retain Coins,
  inventories, unlocks/counters, discoveries and expansions across sessions.
  Planted crops reset on leaving, including mature crops still on soil; no seed refund.
- The subtle footer reports save status and whether Studio is using memory or test cloud data.

| Mutation | Chance | Sell multiplier | Coins per Tomato |
| --- | --- | --- | --- |
| Normal | 70% | 1x | 18 |
| Golden | 18% | 3x | 54 |
| Giant | 10% | 2x | 36 |
| Crystal | 1.9% | 6x | 108 |
| Cosmic | 0.1% | 20x | 360 |

These are Clear/Day baseline odds. Environmental modifiers change normalized
chances at maturity, never crop values or mutation sell multipliers.

Balance lives in `src/shared/Config.luau`. Only the server reads authoritative
state, spends seeds/Coins, rolls mutations and grants rewards. Player attributes
are replicated display snapshots, never input. Native clicks/prompts validate
ownership, a living character, distance and a shared action cooldown server-side.
There are no client-to-server inventory or pricing remotes.
The seed UI sends only a whitelisted Buy/Select action and crop ID; expansion sends
only Expand (no price, tier or plot count). The server checks
the player's character, rate limit, shop distance for purchases, unlock and available Coins/seeds.

`FarmState` contains testable state/economy logic; `FarmWorld` generates the farm; `CropVisuals` renders plants;
`Main` handles player lifecycle and interactions; `FarmPanels` displays the shop and book;
`FarmEffects` provides bounded local effects; `FarmHUD` displays replicated
state and animates Cosmic stars. No external assets or runtime packages are used.
`PlayerData` validates/copies versioned data; `ProfileStore` uses session-owned
UpdateAsync writes; `Persistence` selects isolated stores and reports save status.

## Validation and manual acceptance

Status recorded on 2026-09-25:

- Required manual gameplay loop: **PASS**, confirmed by the project owner in
  Roblox Studio (buy Tomato Seed → plant → grow → harvest → sell).
- Rojo build and generated-script layout checks: **PASS** at the implementation checkpoint.
- Standalone Luau compilation/state tests: written but not run; test-tool download was not approved.
- Milestone 4 Rojo build/static checks: **PASS**. Persistence/expansion tests are
  written but unexecuted without standalone Luau. Studio persistence acceptance is
  **PASS**, confirmed by the owner: progression and purchased expansion survived save/rejoin.
- Additional multiplayer, mobile and rare-mutation visual checks below are not yet confirmed.

Run `./tests/validate.ps1` for the build and generated-script layout check.
With the official standalone Luau tools already available, run:

```powershell
./tests/validate.ps1 -LuauDirectory 'PATH_TO_LUAU_TOOLS'
```

This compiles all scripts and runs deterministic state/persistence tests, including
mutation rolls, one-time payouts, schema migration, session ownership and failed writes.
Rojo build success alone does not prove engine runtime behavior.

Historical Milestone 1 acceptance steps (passed). Use [Milestone 4 acceptance](docs/MILESTONE4.md)
for the current persistence and expansion test:

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

Rare-mutation previews use a Studio-only server command with the same reveal effects as gameplay.
See [current crop preview instructions](docs/MILESTONE3.md#mutation-preview). Production probabilities remain unchanged.
