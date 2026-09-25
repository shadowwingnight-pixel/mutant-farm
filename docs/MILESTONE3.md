# Milestone 3 — crops, progression and discoveries

Status: **manual gameplay validation PASSED**, confirmed by the project owner.
Milestones 1–3 are validated. The owner approved publication of this checkpoint.
No Milestone 4 work, persistence or publishing is included.

## Balance and progression

| Crop | Seed cost | Normal sale | Growth | Unlock (both requirements) |
| --- | --- | --- | --- | --- |
| Tomato | 10 Coins | 18 Coins | 15s | Available on join |
| Strawberry | 25 Coins | 45 Coins | 22s | 400 total sale Coins AND 24 Tomato harvests |
| Pumpkin | 60 Coins | 110 Coins | 32s | 1,500 total sale Coins AND 24 Strawberry harvests |

Start: 100 Coins, six plots. Unlocks are automatic after a sale and cost nothing.
Sale Coins are cumulative gross earnings from all crops, not the current wallet;
spending never removes progress or re-locks a crop. Starting Coins do not count.
Harvest counts count crops, not the multiple decorative fruits on each plant.

Use all six plots to target roughly 5–10 minutes to Pumpkin, including movement,
buying/planting/harvesting and exploring the UI. This timing is an estimate pending
the owner's play-test, not a measured Studio result. The all-Normal route is four
batches of six Tomatoes, then four batches of six Strawberries. Expected milestones:

- After 24 Tomatoes sold: 432 cumulative sale Coins, 292 wallet Coins; Strawberry unlocks.
- After 24 Strawberries sold: 1,512 cumulative sale Coins, 772 wallet Coins; Pumpkin unlocks.
- After six Pumpkins sold: 1,072 wallet Coins (assuming no extra purchases).

Existing odds/multipliers are unchanged: Normal 70%/1x; Golden 18%/3x; Giant 10%/2x;
Crystal 1.9%/6x; Cosmic 0.1%/20x. A single server roll occurs at maturity for every crop.
Rare rolls speed earnings, but crop harvest requirements still provide progression.

`src/shared/Config.luau` centralizes prices, base values, durations, seed phases,
stage thresholds/heights, unlock rules and visual styles. Strawberry is a low,
flowering bush with seeded berries; Pumpkin is a sprawling vine with a large ribbed
fruit. All use the same growth, inventory, mutation and sale code.

## Controls and collection

- Green shop **E / tap → Buy**: choose a crop; buying selects it. Buy several, then close X.
- HUD **Seeds**: inspect unlock progress anywhere; buying is enabled near your own shop.
  **Plant this seed** selects an owned seed and closes the panel. The HUD names the selected crop.
- Click/tap nearby empty soil to plant the selected seed; click READY soil to harvest.
- Orange stand **E / tap** sells the entire mixed basket.
- HUD **Book**: 15 entries across three crops. Unknown mutation names display `???`.
  The first actual harvest of a crop/mutation combination reveals it and shows
  `NEW DISCOVERY!`. Subsequent harvests do not repeat the discovery notification.
- Discovery/unlock messages remain visible briefly during rapid harvesting. The book
  and inventory counters update immediately even when notices are queued.
- Sales and character resets preserve session collection. Leaving resets everything.

## Security and future persistence

`FarmState` owns Coins, seeds, selection, per-crop baskets, cumulative sale earnings,
harvest totals, unlock booleans and discovery booleans. These are plain tables/numbers
keyed by stable crop/mutation IDs, suitable for a future versioned persistence snapshot;
no DataStore calls or persistence implementation exist yet.

`FarmAction` accepts only Buy/Select and a known crop ID. Server handlers validate
character health, shared cooldown and own-shop distance for purchases. `FarmState`
then validates unlocks, prices, balances and seed ownership. Planting uses the
server's selected crop, and harvesting uses its stored plot mutation. The client
cannot submit prices, rewards, unlocks or discoveries. `FarmFeedback` remains outbound.
Player attributes are display snapshots and are never read back into authoritative state.

## Validation

- Rojo build, script layout, static request/preview boundary checks and whitespace checks passed.
- The deterministic state suite now contains 19 tests, including the original 10,
  unlock boundaries, malformed crop IDs, progression, selection, every crop's stage
  timings, mixed payouts, discovery deduplication and all 15 combinations.
- Standalone Luau compilation/state execution remains **unrun**: no local runtime
  is installed. No external tools were downloaded. Rojo/static checks are not a
  substitute for syntax/runtime and Studio play-testing.

Repeat available checks: `./tests/validate.ps1`. With existing official Luau tools:
`./tests/validate.ps1 -LuauDirectory 'PATH_TO_LUAU_TOOLS'`.

## Required manual test

With Rojo connected, stop the old session and start a fresh **Play** session:

1. Join: 100 Coins, zero seeds/harvest. Open Seeds; only Tomato should be unlocked.
2. Visit the green shop, press E, buy six Tomato Seeds, close X, plant all six plots.
3. Watch improved growth; harvest READY crops. First harvest shows NEW DISCOVERY.
   Sell at the orange stall. Repeat until Strawberry unlocks (four batches).
4. Confirm both requirement counters and the UNLOCKED notice. Buy/select Strawberry;
   close the panel; plant, watch the low bush grow, harvest and sell. Tomato still works.
5. Repeat Strawberry batches until Pumpkin unlocks (four batches). Buy/select Pumpkin;
   plant, watch the vine/ribbed fruit, harvest and sell. Verify larger sale values.
6. Open Book: harvested combinations display their names; unharvested ones remain ???.
   Sell or harvest a duplicate; discoveries remain and duplicates do not increase the count.
7. Keep seeds from two crops; switch **Plant this seed**, plant each, and verify the
   correct seed is consumed and crop appears. Sell a mixed basket at the configured values.

Supplemental: try a locked buy, insufficient funds, opening Seeds far from the shop,
buying after walking away, fast repeat clicks, reset character and a two-player ownership
test. Verify mobile panel scrolling/close/tap targets and no Output errors. Check duration
to Pumpkin against the 5–10 minute target and report if progression feels too slow/fast.

## Mutation preview

During Play, use the **Server Command Bar**. Stand near the entrance facing the garden.
The third argument is the crop; the second remains an optional UserId for multiplayer.
Run one line at a time, and return to Client view within the three-second countdown:

```lua
game.ServerStorage.MutantFarmPreview:Invoke("Golden", nil, "Strawberry")
game.ServerStorage.MutantFarmPreview:Invoke("Giant", nil, "Pumpkin")
game.ServerStorage.MutantFarmPreview:Invoke("Crystal", nil, "Tomato")
game.ServerStorage.MutantFarmPreview:Invoke("Cosmic", nil, "Pumpkin")
```

Any of the five mutation IDs and three crop IDs can be combined. Old one-argument
commands still preview Tomato. Start recording before Cosmic; repeat to replay.
Clear using `game.ServerStorage.MutantFarmPreview:Invoke("Clear")`, or stop Play.

Preview installation/invocation are Studio/server gated in ServerStorage. Previews
are visual only: **no harvest, inventory, progression or discovery credit**; no odds
change and no production player access. Confirm the Book count stays unchanged.

Stop after manual validation. Do not begin Milestone 4.
