# M7 — Living Town

Status: **manual Studio acceptance PASSED**, confirmed by the project owner.
NPC dialogue, objective progression, six one-time rewards, environment-reactive
dialogue, farming interactions and persistence/rejoin behavior work correctly.
The owner authorized pushing completed M7 commits. No experience publication or
Milestone 8 work.

## Characters and controls

- **Mira**, seed keeper: straw hat, green coat and apron, beside Seed Store porch
  (X=-140, Z=34). Encouraging planting and crop-progression advice.
- **Bram**, harvest merchant: rust coat, blue apron and ledger, beside Market
  (X=-53, Z=26). Practical selling and mutation-value advice.
- **Dr. Lumen**, mutation researcher: pale coat, goggles and specimen vial outside
  Lab (X=-106, Z=-20). Discovery Book hints and environmental explanations.

Approach within nine studs and press **F**, or tap **Talk**. Existing transaction
prompts remain **E**. Continue/Done/Close are local UI actions with no rewards or
client requests. Dialogue closes after 30 seconds, respawning, or opening a shop,
Book or upgrade panel. NPCs are anchored, non-colliding original primitive figures
with idle blink tweens; no AI, Humanoids, pathfinding or per-frame update loop.

## Objectives and save behavior

Buy Tomato Seed → plant any crop → harvest any crop → sell → record a mutation
in Book → talk to Researcher. One objective appears in the existing HUD guide row;
completion uses brief checkmark feedback. The guide returns to farming hints afterward.
At the final step the existing target highlight points at the Researcher.

Each step grants **5 Coins**, exactly once, **30 total**. No seed/XP rewards and no
change to prices, sale values, mutation odds or unlock requirements. Objective Coins
do not count as sale earnings. The first harvest normally records a discovery before
selling; that saved discovery credits the Book step immediately after the first sale.
No second rare roll is needed. Talking to the Researcher early is allowed but does
not skip ahead. Old players start at step one; existing Book entries can satisfy the
discovery step when reached.

Only successful server gameplay operations dispatch objective events. NPC prompts
reuse loaded-profile, living-character, distance and action-rate checks, with a
further one-second conversation cooldown. No new client-to-server remote exists.
The completed-step integer and Coins change without yielding and are saved together.
Schema v2 accepts v0/v1 saves, defaulting missing objective progress to zero;
invalid progress/future versions fail closed. Existing profile locking, store names,
Studio isolation and save lifecycle remain unchanged. Completion schedules a save
within about three seconds; normal save-failure/last-successful-save limits still apply.

## Exact manual acceptance

1. Stop Play, sync Rojo, and use the **existing isolated Studio test experience**
   from [M4 safe testing](MILESTONE4.md). For a fresh cloud test, set in Edit mode:

   ```lua
   workspace:SetAttribute("MutantFarmStudioPersistence", true)
   workspace:SetAttribute("MutantFarmTestSlot", "m7-accept-01")
   ```

   Use another unused slot if that name already has data. Do not erase old saves.
   Retain the existing test experience's Studio API access setting. For a quick
   session-only UI test set the Boolean false, but that cannot validate rejoin saves.
2. Press Play. Verify **Studio cloud • m7-accept-01**, 100 Coins and objective
   **Buy a Tomato Seed**. Talk to Mira: F, Continue, Close. Confirm her prompt does
   not block the seed counter's E prompt. Buy one Tomato Seed: expect **95 Coins**
   (100 − 10 + 5), one seed and the planting objective.
3. Plant: expect **100 Coins** and harvest objective. Wait for READY, then harvest:
   expect **105 Coins**, a Book discovery and sell objective. Note the basket value.
4. Sell at Market: expect **105 + basket value + 10 Coins** (sale and two objective
   rewards). Book and sale steps finish; current objective becomes Visit Researcher.
   Talk to Bram; verify the existing sell interaction still works separately.
5. To test partial progress, save now in the **Server** Command Bar:

   ```lua
   print(game.ServerStorage.MutantFarmSave:Invoke())
   print(game.Players:GetPlayers()[1]:GetAttribute("ObjectiveStep")) -- 5
   ```

   Wait for Saved, Stop and Play again using the same slot and player. Verify Coins,
   Book and step 5 remain. Never change slots between these two joins.
6. Visit Dr. Lumen, press F: receive final response and **+5 Coins**. For a single
   Normal Tomato run with no other spending, final balance is **138**. Close/reopen
   dialogue repeatedly: no further reward. Save again (wait ten seconds between
   manual saves), Stop/Play: step **6**, Coins and completion remain. Buy/plant/
   harvest/sell again and confirm no tutorial rewards repeat.
7. Check reactive lines: close dialogue, run each Server command separately, then
   talk to the NPCs again. New conversations sample current server conditions:

   ```lua
   game.ServerStorage.MutantFarmEnvironment:Invoke("EndMeteor")
   game.ServerStorage.MutantFarmEnvironment:Invoke("Day")
   game.ServerStorage.MutantFarmEnvironment:Invoke("Clear")
   -- Talk to Researcher: ordinary Book hints.
   game.ServerStorage.MutantFarmEnvironment:Invoke("Rain")
   -- Talk: rain line.
   game.ServerStorage.MutantFarmEnvironment:Invoke("Thunderstorm")
   -- Talk: storm-energy line.
   game.ServerStorage.MutantFarmEnvironment:Invoke("Clear")
   game.ServerStorage.MutantFarmEnvironment:Invoke("Night")
   -- Talk: nighttime line.
   game.ServerStorage.MutantFarmEnvironment:Invoke("Meteor")
   -- Talk to Researcher within 45 seconds: special readings-spiking line.
   game.ServerStorage.MutantFarmEnvironment:Invoke("EndMeteor")
   game.ServerStorage.MutantFarmEnvironment:Invoke("Resume")
   ```

   Priority is Meteor → Thunderstorm → Rain → Night. No normal dialogue exposes
   exact odds or guarantees. Open Book after a hint and check unknown entries remain mysterious.
8. In Device Emulator, test a narrow phone and landscape screen: readable dialogue,
   tappable Continue/Close, objective text and no persistent obstruction. Try walking
   around every NPC, farming, upgrading land, all crops and existing preview controls.
   Check Output for errors. In a two-player test, ensure objectives/rewards are separate.
9. Optionally load your previous isolated M6 test slot with M7 code: confirm existing
   Coins/items/unlocks/expansion/Book remain and objectives begin at zero. It upgrades
   that test profile to v2; M6 code will correctly refuse this newer schema if rolled back.

## Automated checks and known limits

Rojo build and static authority/module/geometry checks passed. Added deterministic
tests for objective sequence, repeat-event rejection, reward totals, early discovery
credit, save/reload and legacy migration. Updated persistence tests for schema v2.
Standalone Luau compiler/runner is unavailable, so these suites remain unexecuted.
Rojo serializes source and cannot prove syntax, runtime behavior or save/rejoin.

NPCs stand in place; dialogue does not update mid-conversation. No extra ambient
residents, interiors or large quest system. Town geometry, crop visuals, weather,
profile storage protocol and existing Studio preview controls are unchanged.
Owner manual acceptance has passed; pushing completed M7 commits is authorized.
