# M6C — Environment redesign

Status: **M6A + M6B + M6C validated by the owner in Roblox Studio**.
The manual acceptance test passed: the town, redesigned buildings, farm and
waterfront are functional and accepted as the current development-stage visual
baseline. Owner authorized pushing completed M6 commits. No experience publication
or Milestone 7 work.

## Substantial replacements

- Seed Store: solid gabled roof, deep covered service porch, braced posts, recessed
  shop volume, large windows and physical signage. Original purchase counter retained.
- Market: open four-post pavilion, stepped clerestory roof and grouped produce
  displays. Original selling counter retained.
- Research Lab: asymmetric greenhouse/silo silhouette, framed glazing treatment,
  transfer pipes and restrained specimen accents. Closed exterior only.
- Farm: roofed entrance, stone-and-timber boundaries, twin garden lanes between
  unchanged soil targets, tool shed and irrigation corner. Rear fences, hedges and
  lanes extend with 6 → 9 → 12 plots; existing crops are not rebuilt.
- River: eight variable-width reaches with rounded sand/grass banks replacing the
  straight channel; shallow continuous safety bed. Low arched wood deck, stone
  abutments, sloping rails and stone approaches replace the previous bridge.
- Background houses use filled gables and physical plaques. Old overlapping
  landmark/river decorations were removed rather than layered underneath.

## Exact Studio inspection

1. Stop Play. Confirm Rojo is connected and synced, then start a fresh Play session;
   generated geometry is constructed at startup.
2. Inspect your starter farm from its entrance and between all six plots. Check the
   gate, shed, garden lanes, soil edges and irrigation corner. Plant and harvest.
3. Purchase 9 plots, then 12 through the existing upgrade board when affordable.
   Check that rear boundaries and lanes extend, existing crops remain and every
   new plot is reachable/clickable. Use a fresh session-memory test for six plots
   if your isolated cloud test profile already owns expansions; do not reset it.
4. Follow the road west to Town Square. Inspect the Seed Store porch/counter
   (X=-153, Z=28), buy a seed; inspect Market (X=-65, Z=19), sell a harvest.
5. Walk north to Research Lab (entrance near X=-110, Z=-26). Inspect front and
   side silhouettes; the greenhouse/silo are intentionally inaccessible.
6. Walk south from the square to the river (Z=72–102). Inspect both banks away
   from the bridge, then cross at X=-110, Z=87 to the future road. Step off the
   bank and walk/jump back out; check approaches, rails and shoreline seams.
7. View the town from the farm district gate near X=-44, Z=44, then from the
   square and opposite riverbank. Judge landmark hierarchy, roof proportions,
   landscape transitions and whether these three areas meet your visual target.
8. In Play's **Server** Command Bar, run each line separately and inspect:

```lua
game.ServerStorage.MutantFarmEnvironment:Invoke("Day")
game.ServerStorage.MutantFarmEnvironment:Invoke("Evening")
game.ServerStorage.MutantFarmEnvironment:Invoke("Night")
game.ServerStorage.MutantFarmEnvironment:Invoke("Rain")
game.ServerStorage.MutantFarmEnvironment:Invoke("Thunderstorm")
game.ServerStorage.MutantFarmEnvironment:Invoke("Meteor")
game.ServerStorage.MutantFarmEnvironment:Invoke("EndMeteor")
game.ServerStorage.MutantFarmEnvironment:Invoke("Clear")
game.ServerStorage.MutantFarmEnvironment:Invoke("Resume")
```

Check warm landmark lighting, farm visibility, meteor cleanup and farming during
weather. Recheck save/rejoin only using the existing isolated
[M4 persistence procedure](MILESTONE4.md). Inspect Output for errors and try a
two-player session for separate farms/expansions and unobstructed navigation.

## Validation and limits

Rojo build, generated module placement, existing static authority guards, preserved
soil geometry checks and whitespace checks passed. Gameplay, client, shared config,
persistence and environment authority sources are unchanged from M6B.
Standalone Luau compilation/state tests could not run: toolchain unavailable.
Rojo build does not compile Luau or establish runtime correctness.

All additions are anchored; small decorative parts do not collide or receive
queries. No new particles, external assets, per-frame loops or dynamic-light
increase (11 shared town PointLights). Runtime part counts and device performance
still need Studio inspection; StaticTownParts is recorded on the town model.

Water is a static stylized surface over a shallow walkable bed, not swimming
Terrain water. No functional interiors. Existing rain has no roof occlusion and
thunder effects are silent. Visual quality, roof/shoreline appearance and traversal
were accepted by the owner in the M6 manual Studio test for the current development stage.
