# Milestone 6 — Mutant Farm Town

Status: **implemented; owner Studio visual/gameplay acceptance pending**.
Update: the owner confirmed the M6A foundation loads and works after restarting and
reconnecting Rojo. The additive [M6B polish pass](MILESTONE6B.md) awaits visual validation.
Validated baseline: `02da144d6bffb39619982b56e832ae1679b83b92`.
Local commits only; no push, experience publication/update or Milestone 7 work.

## Layout

One shared town sits west of the unchanged farm grid. Its main footprint is about
136 × 182 studs; farm-district connections grow only as slots are used. Most town
landmarks are a few seconds apart at normal walking speed.

```text
             Grove / closed forest trail       Mutation Research Lab
                         \                         |
                      Seed Store             Research Walk     Produce Market
                          |                        |                 |
                          +------------------ Seed Square -----------+---- Farm District
                                             seed sculpture                your farm
                                                   |
                                              River Walk
                      ~~~~~~~~~~~~~~~~~~~~ wooden bridge ~~~~~~~~~~~~~~~~~ river
                                                   |
                                          future district / closed road
```

- **Farm district:** original plot/world coordinates, counters, boundaries and
  expansion layout unchanged. New entrance arch, name sign, path and grass foundation
  connect each farm to the town road. Spawn faces toward the town from your own gate;
  turn around to reach your plots. Farm ground remains above the new foundation.
- **Seed Square:** circular paving, original golden seed/leaf sculpture, benches,
  lamps and direction signs form the central landmark.
- **Seed Store:** green pitched roof, open counter, supply displays and clear sign.
- **Produce Market:** warm striped canopy, crates and original primitive produce.
- **Research Lab:** closed exterior with pitched silhouette, glass windows and
  glowing specimen containers. No new mutation/research interaction or mechanics.
- **River:** shallow decorative water with a solid walk-out bed; wooden bridge has
  open ends and side rails. No terrain modification, swimming system or hidden walls.
- **Natural area:** small grove and short paths, with two visibly closed future roads.
- **Lighting:** eight shadow-free lantern lights turn on at Evening/Night and off
  during Day using the existing server environment state.

## Existing-system integration

`TownWorld` generates one `Workspace.MutantFarmTown`, organized into GroundAndPaths,
TownSquare, ShopArchitecture, ResearchLab, RiverAndBridge, Nature and FarmDistrictRoads.
Farms stay in `Workspace.MutantFarms`.

Town shop/sell counters are additional access points to the **same** gameplay system.
The existing Buy request chooses the closer authoritative target (own farm counter
or shared town store), then applies the original distance/health/rate/Coins/unlock
checks. Both selling prompts call one common helper and the unchanged `FarmState:sell`.
Shared prompts act only on the visiting player's loaded session; farm prompts remain
owner-only. UI proximity and highlighting recognize both locations. No second
inventory, prices, rewards, transaction remote or persistence schema was added.

Baseline comparison confirmed no changes to FarmWorld (including plot coordinates),
FarmState, CropVisuals, Config, PlayerData, ProfileStore, Persistence, EnvironmentState,
EnvironmentService, EnvironmentView, StudioPreview or the existing Luau test suites.

## Exact Studio walkthrough

1. Stop Play, sync the current source with Rojo at `localhost:34872`, then press
   **Play**. For visual QA use ordinary Studio memory mode. If needed, while stopped
   run `workspace:SetAttribute("MutantFarmStudioPersistence", false)` in the Edit
   Command Bar. Do not publish the experience. Keep Output visible for errors.
2. Expect arrival at your named farm gate, a welcome message and the town road ahead
   to the left. Turn around: identify your own six plots (or your saved expansion
   when using the existing isolated cloud-test setup). Reset once and confirm you
   return to the same entrance without losing the running session's farm state.
3. Walk out to the lane and **left/west through the MUTANT FARM TOWN arch**. Follow
   the road to the circular Seed Square and golden seed sculpture. Walk around the
   planter and benches; you should not need to jump across any road gaps.
4. From the square go **left/west** to the green **SEEDS / FARM SUPPLIES** counter.
   Press E/tap, buy a seed, verify the familiar UI and correct Coin/seed change.
   Move away with the panel open: purchasing should become unavailable out of range.
5. Return east through the arch to your named farm, select the seed and plant.
   Watch growth and harvest. Repeat with Strawberry/Pumpkin when unlocked. The
   original farm seed counter should still buy/select seeds normally.
6. Carry harvested crops back to town. Visit the orange-canopy **PRODUCE MARKET**
   east of the square, press E/tap and verify one payout, an empty basket, correct
   unlock/discovery behavior and normal feedback. Try selling an empty basket again.
   Verify the original farm selling stand still works too.
7. Walk north from the square to **MUTATION RESEARCH**. Inspect the closed door,
   windows and glowing containers; no research actions should appear. Follow the
   side path into the grove and find the closed forest-road teaser.
8. Walk south from the square to the river. Cross the wooden bridge both ways.
   Step off into the shallow river and walk/jump out on either bank. Inspect the
   southern ROAD CLOSED sign. Both barriers should be visible objects, not invisible
   walls. No future district is implemented beyond them.
9. Back at your farm, purchase/use Expansion I and II when affordable. Verify
   6 → 9 → 12 plots, planting/harvesting on new rows, preserved existing crops and
   uninterrupted entrance-road access. No new paths should overlap soil.
10. Switch the Command Bar to the **server** context. Run each command separately,
    waiting at least five seconds between changes:

    ```lua
    print(game.ServerStorage.MutantFarmEnvironment:Invoke("EndMeteor"))
    print(game.ServerStorage.MutantFarmEnvironment:Invoke("Clear"))
    print(game.ServerStorage.MutantFarmEnvironment:Invoke("Day"))
    print(game.ServerStorage.MutantFarmEnvironment:Invoke("Evening"))
    print(game.ServerStorage.MutantFarmEnvironment:Invoke("Night"))
    print(game.ServerStorage.MutantFarmEnvironment:Invoke("Rain"))
    print(game.ServerStorage.MutantFarmEnvironment:Invoke("Thunderstorm"))
    print(game.ServerStorage.MutantFarmEnvironment:Invoke("Meteor"))
    ```

    Walk the square, store, market, lab and bridge in these states. Lanterns should
    be off by Day and lit in Evening/Night. HUD, rain, lightning (wait up to 18s),
    meteors and farming should still work. Wait 45 seconds for Meteor's automatic
    end, or invoke `"EndMeteor"`. Use `"Inspect"` to check existing server odds and
    `"Resume"` afterward to release the test holds. These are the unchanged M5 controls.
11. Confirm existing preview functionality from the server Command Bar:

    ```lua
    game.ServerStorage.MutantFarmPreview:Invoke("Cosmic", nil, "Pumpkin")
    -- After inspecting the reveal:
    game.ServerStorage.MutantFarmPreview:Invoke("Clear")
    ```

12. Test persistence with the **existing isolated test experience/slot** using the
    [M4 instructions](MILESTONE4.md#safe-studio-persistence-test--exact-procedure).
    Farm, buy/sell in town, expand, record values, invoke
    `game.ServerStorage.MutantFarmSave:Invoke()` from the server, stop/rejoin and
    verify saved progression, inventories, Book and expansion. Do not treat Studio
    memory mode as a persistence test. Growing crops still reset on leaving.
13. Use a two-player server test: both players can transact at shared town counters
    with their own balances; neither can use the other's personal farm counters or
    harvest their crops. Inspect roads to each farm. If practical test a fifth slot
    to exercise a second farm row and its district spine.
14. Walk around roofs/counters/planter/bridge edges, reset if necessary, and report
    any snagging, unreachable prompts, invisible barriers or trapping. Try a mobile
    emulator/narrow viewport and watch frame rate near the square during storms and
    Meteor. Check Output for errors throughout.

## Performance and checks

- All environment geometry is anchored. Decorative crowns, signs, water and produce
  have collision/query/shadows disabled where appropriate. No NPCs, new particles,
  physics systems, downloaded assets or per-frame town loop.
- Eight PointLights have shadows disabled and short ranges. Light changes run only
  on broad time-state changes. Existing M5 cosmetic caps/cleanup remain unchanged.
- One town is shared by all players. Each farm gets five entrance Parts; district
  ground/roads are extended per occupied row/slot rather than prebuilding empty lots.
  Roads remain for reuse after departures. Large servers will have longer farm walks;
  no transport system or server-capacity changes were introduced.
- Inspect `Workspace.MutantFarmTown.StaticTownParts` for the generated base Part
  count in Studio; added farm routes/entrances are separate. Mobile frame rate has
  **not** been measured yet.
- Rojo build/static boundary checks and `git diff --check`: **PASS**. Added checks
  cover guarded town endpoints and the existing environment hook. Protected baseline
  modules and existing regression suites are unchanged.
- Standalone Luau compilation/regression suites remain **unexecuted**, because the
  runner is unavailable. Rojo builds serialize source; they do not prove syntax,
  navigation, visuals or runtime behavior. **Studio acceptance is still pending.**

Known prototype limits: open-front shops and closed lab; static shallow water;
M5's camera-local rain has no roof occlusion and lightning remains silent. Neither
the closed-road signs nor the lab expose future mechanics. Edge/large-avatar
clearances and visual readability need the owner's walkthrough.

Next: await Milestone 6 acceptance. Milestone 7 is not started or scoped here.
