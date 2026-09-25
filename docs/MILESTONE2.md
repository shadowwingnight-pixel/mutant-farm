# Milestone 2 — presentation and feedback

Status: **validated by the project owner in Roblox Studio on 2026-09-25.**
The complete gameplay loop and mutation preview system passed. Milestone 3 has not started.

## What changed

- Meadow surroundings, striped shop awnings, seed packets, harvest crates/coins,
  soil furrows, connected paths, rail fences, trees, flowers, hay and a barrel.
- Visual growth: seed mound (first 1.3 seconds), sprout, young plant (5s),
  leafy tomato plant with three green fruits (10s), mutation/READY (15s).
- Mutation silhouettes/colors: red Normal, golden leaves/fruit, 1.8x Giant,
  cyan Crystal facets, violet Cosmic with cyan/gold orbiting stars.
- Compact resource cards, contextual next-step highlighting, short transaction
  notifications, card pulses and local spark bursts.
- Cosmic: a brief expanding glow/light pulse and a 3.6-second announcement.
  No camera takeover, input lock, flashing fullscreen effects or audio assets.

The validated `FarmState` and `Config` are unchanged: same inventories, costs,
growth duration, odds, multipliers and one server-selected mutation per crop.
The only remote added is server-to-client cosmetic feedback. No client messages
are accepted by it, and no cosmetic effect changes gameplay state.

## Validation recorded

- Rojo build and instance placement checks passed.
- Static checks passed for Studio-only preview installation/invocation,
  server-only module placement and outbound-only feedback.
- Verified `FarmState` and `Config` match validated Milestone 1 (`cd86de8`).
- Standalone Luau compilation and gameplay-state tests were not run: optional
  test-tool download awaits approval. No tool was downloaded or installed.
- Manual Studio gameplay loop and mutation preview system: **PASS**, confirmed
  by the project owner on 2026-09-25. Supplemental mobile and multiplayer checks
  have not been separately confirmed. The steps below remain for regression testing.

Run `./tests/validate.ps1` to repeat available checks. If official Luau tools are
already available, pass `-LuauDirectory 'PATH_TO_LUAU_TOOLS'` to also compile and
run the existing deterministic state tests.

## Required manual loop

With Rojo connected, **stop any old session and start a fresh Play session**.

1. Join: see 100 Coins and understand the highlighted green Seed Shop without
   instructions. Check that the HUD leaves the farm visible.
2. Walk to the green shop and press **E** (or tap its prompt): see **+1 Tomato Seed**,
   90 Coins, and a highlighted empty soil plot.
3. Click/tap that nearby soil: see the seed mound, planting burst and zero seeds.
4. Watch 15 seconds: sprout → young plant → green tomatoes → ripe mutation/READY.
   The countdown, tomato shape and mutation name should be clear.
5. Click/tap READY soil: see **+1 [mutation] Tomato**, inventory increase, harvest
   sparks and the empty plot. Giant/crystalline fruit must not obstruct clicks.
6. Follow the highlighted orange stand; press **E** / tap: see **+N Coins**, the
   Coin card pulse, and an empty basket. A single Normal sale leaves 108 Coins.
7. Buy again: see one seed and 10 fewer Coins (98 after that Normal sale).

Also check six simultaneous crops, repeated empty clicks/sales, character reset,
and a two-player session (ownership/inventories must remain separate). Use Device
Emulator to inspect HUD overlap and tap planting. These are supplemental checks.

## Mutation previews and Cosmic recording

This is a **visual-only Studio development tool**. It neither creates harvestable
crops nor changes inventory, rewards or production probabilities. A bindable is
created in ServerStorage only when both `IsStudio()` and `IsServer()` are true;
the invocation checks both again. There is no player-facing preview remote.

1. Start **Play** and stand at your farm entrance, facing the garden. The preview
   appears on the central path between the stalls, just ahead of the spawn.
2. Open Studio's **Command Bar** and choose the **Server** execution context.
3. Run **one line at a time**. Each replaces the previous preview and reveals
   after three seconds. Return to the **Client** view immediately to see the HUD.

```lua
game.ServerStorage.MutantFarmPreview:Invoke("Golden")
game.ServerStorage.MutantFarmPreview:Invoke("Giant")
game.ServerStorage.MutantFarmPreview:Invoke("Crystal")
game.ServerStorage.MutantFarmPreview:Invoke("Cosmic")
```

For Cosmic recording, start recording first, invoke the Cosmic line, then return
to Client view before the three-second countdown ends. Expect the same world
burst and short Cosmic announcement as real maturity; the subtitle identifies
it as a preview. The stars continue orbiting after the short reveal ends. Invoke
again to replay. In a two-player test, append the intended player's numeric UserId
as the second argument; omission chooses the first joined player.

Clear the preview (also cancels a pending reveal):

```lua
game.ServerStorage.MutantFarmPreview:Invoke("Clear")
```

Stopping Play also discards previews. Invalid names return a help message.
Check that previewing/clearing leaves all HUD inventory/Coins unchanged.

## Performance limits

Primitives only; decorations/crops disable collision queries where appropriate.
Local spark bursts cap at 48 concurrent spark parts and expire in 1.2 seconds;
Cosmic light pulses are limited to one per second. Orbit updates run at 30 Hz
for at most eight nearby plants, cull beyond 80 studs and clean up tag listeners.
There are no per-frame world scans, downloaded assets or persistent particle emitters.

**Stop here after manual validation. Do not begin Milestone 3.**
