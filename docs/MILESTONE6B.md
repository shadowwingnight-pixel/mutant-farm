# Milestone 6B — town visual expansion and polish

Status: **validated as part of the completed M6A + M6B + M6C Studio acceptance**.
The owner accepted the redesigned town as the current visual baseline. M6C supersedes
the initial M6B landmark and waterfront visuals. No experience publication.
Milestone 7 has not started.

## Additions

- Seed Store: deeper awning, fascia, corner beams, chimney, doorstep planters and light.
- Market: frontage beams, canopy details, stacked crates and an exterior lantern.
- Mutation Lab: roof lantern silhouette, structural/window trims, specimen bases and
  entrance lighting. Still closed and non-functional.
- Three closed scenery buildings: Garden House west of the square, Old Bakery east,
  and Seed Barn northeast of the lab. Pitched roofs, chimneys, shutters, doors and
  warm windows make a small inhabited street without adding interiors or interactions.
- Garden Street, doorstep walks, short road edges, bridge approach stones, square
  flower beds and a decorative notice board. The original seed sculpture stays central.
- Bridge plank seams/braces, bank rocks/reeds, shrubs and distant hill/tree silhouettes.
  Future-road barriers remain; the scenery behind them is not a new playable district.
- Farm entrance hedges, flowers, path edges, hay and a barrel. All additions are at
  the front of the farm, outside soil/expansion positions; spawn coordinates unchanged.

`TownPolish` contains reusable scenery builders, invoked once from `TownWorld` for
the shared town and once per farm entrance. Instances are organized under
`MutantFarmTown.VisualPolish` and each farm's `EntranceScenery`.

## Short Studio walkthrough

Stop Play, reconnect/sync Rojo (`localhost:34872`) and start a fresh **Play** session.
Generated geometry is built at startup, so restarting is required after source sync.
Use ordinary Studio memory mode for visual QA; retain the existing isolated cloud
test slot when deliberately testing persistence. Do not publish the experience.

1. **Spawn → Farm entrance:** inspect the first view, named gate, planting/path edges
   and distant backdrop. Follow the town direction. Return once to confirm your
   original soil, counters and 6/9/12 plot layout remain unobstructed.
2. **Town Square:** walk left through the town arch to the seed sculpture. Check
   flower beds, benches, notice board and clear exits around the square.
3. **Seed Store → Market:** inspect the awning/roof details and lanterns. Buy from
   the original UI, farm/harvest and sell at the market. Confirm normal pricing,
   inventory, selection and feedback; no decorative prop should obstruct a prompt.
4. **Decorative streets:** follow the narrow Garden Street behind the square's
   benches to Garden House and Old Bakery. Doors are deliberately closed; no new
   shop/NPC/UI should appear. Look toward the Seed Barn beyond the lab.
5. **Mutation Lab → Grove:** inspect roof lantern, framed windows, containers and
   planted corners. Walk the original grove path to the existing forest barrier.
6. **River → Bridge → Future road:** inspect reeds/rocks and bridge details. Cross
   both ways, step into the shallow river and exit either bank. Walk to the southern
   road-closed sign and view the background hills/trees. Check for snagging or trapping.

Then use the **server Command Bar**, one command at a time, allowing five seconds
between transitions:

```lua
print(game.ServerStorage.MutantFarmEnvironment:Invoke("EndMeteor"))
print(game.ServerStorage.MutantFarmEnvironment:Invoke("Clear"))
print(game.ServerStorage.MutantFarmEnvironment:Invoke("Day"))
print(game.ServerStorage.MutantFarmEnvironment:Invoke("Night"))
print(game.ServerStorage.MutantFarmEnvironment:Invoke("Rain"))
print(game.ServerStorage.MutantFarmEnvironment:Invoke("Thunderstorm"))
print(game.ServerStorage.MutantFarmEnvironment:Invoke("Meteor"))
```

Check the three main landmarks remain identifiable by Night; house windows glow,
and street/building lights are on. Wait up to 18s for lightning, and 45s for Meteor
to finish (or invoke `"EndMeteor"`). Farm and transact during the weather tests.
Invoke `"Day"` to check lamps/windows return to their daytime materials, then
`"Resume"` to release the test holds. Evening should light the town too.

Finally buy/use farm expansions, check all three crops and the Book, and repeat
the [existing isolated persistence rejoin check](MILESTONE4.md#safe-studio-persistence-test--exact-procedure)
if testing cloud saves. Existing mutation previews remain available. Try a narrow
viewport/mobile emulator and check Output and frame rate, especially during storms.

## Performance and verification

- Static anchored geometry; no new particles, moving scenery, frame loops or assets.
- Three additional short-range shadow-free PointLights, one per existing landmark
  (**11 town lights total**). House windows only switch materials; they add no lights.
  The existing broad time-state update controls everything; M5 is unchanged.
- Decorative additions disable collision, query and shadows. Each new house has
  one solid exterior body; no internal collision maze. Eight small added Parts per
  farm entrance; the detailed town is shared rather than copied for each player.
- Inspect `VisualPolish.AddedParts`, `VisualPolish.AddedPointLights` and
  `MutantFarmTown.StaticTownParts` in Studio for generated counts. No mobile frame
  rate or visual result is claimed before testing.
- Rojo build/static checks and whitespace validation: **PASS**. One server Script,
  one LocalScript, fifteen ModuleScripts. New checks ensure scenery has no gameplay
  endpoints/frame loops and uses existing lighting updates.
- Baseline comparison: gameplay/transactions, farm coordinates, configuration,
  persistence, M5, Studio controls, client UI and all existing Luau suites are unchanged.
- Standalone Luau compilation/regression suites are still **unexecuted** because
  the runner is unavailable. Rojo builds do not prove runtime correctness or visuals.

Known prototype limits: distant scenery is non-colliding visual backdrop, not
explorable land; new houses have closed solid exteriors. M5's camera-local rain still
has no roof occlusion and thunder remains silent. Check sightlines, text readability
and corner clearances when making future visual changes; M6A–C acceptance has passed.

M6A–C acceptance passed. Do not begin Milestone 7.
