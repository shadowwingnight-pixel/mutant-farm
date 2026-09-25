# Milestone 4 — persistence and farm expansion

Status: **persistence acceptance PASSED**, confirmed by the project owner in Roblox
Studio. Save/rejoin preserved progression and purchased farm expansion, and the
expansion system works. Milestones 1–4 are validated; the owner authorized pushing
this checkpoint. This task did not publish the Roblox experience.

## What is saved

Schema `version = 1`: Coins, seeds by crop, harvested inventory by crop/mutation,
cumulative sale Coins and harvest counts, crop unlocks, discovery flags, selected
seed and purchased expansion tier. All values originate from server state.

**Plants on soil are not saved**, including READY plants. Consumed seeds are not
refunded. Harvest before leaving; harvested crops in the basket are saved.
Respawning within the same server does not clear plants.

`PlayerData` handles validation and snapshots; `ProfileStore` handles ownership
and writes; `Persistence` selects the Roblox store. Only a successful load can
create a playable session. A successful missing-key lookup creates new defaults.
Malformed/unsupported records or failed loads refuse entry without saving defaults.
Flat v0 data with valid Coins migrates missing optional fields; future versions and
unknown inventory IDs are rejected rather than silently discarded.

UpdateAsync acquires a unique session token with a 180-second lease. Writes check
that token and lease, and use write IDs for retries after an ambiguous response.
Autosave runs about every 60 seconds (initial per-player stagger); expansion brings
the next save forward to about three seconds. Each operation retries at most three
times with 2/4-second delays. Failed autosaves schedule another attempt after 15
seconds. Gameplay stops before an unrenewed lease expires. Leaving saves/releases;
shutdown attempts saves in parallel within a 25-second wait. Roblox outages or
forced termination can still lose changes since the last successful save.

## Expansion balance and controls

| Tier | Plots | Purchase cost |
| --- | --- | --- |
| Starter Farm | 6 | Included |
| Expansion I | 9 | 500 Coins |
| Expansion II | 12 | 1,500 more Coins |

Costs/counts live in `Config.Expansions`. Gross earnings/unlock counters are not
reduced by purchases. The blue **FARM EXPANSION** board near the selling area opens
the upgrade panel with E/tap. It shows current size, next price, insufficient-Coins
and max-size states. New rows appear behind the existing garden; grass, paths and
fences extend without removing existing plants. Purchases validate the player's
own board distance, living character, cooldown, Coins and next tier server-side.

## Safe Studio persistence test — exact procedure

**Prerequisite:** cloud DataStore calls require a published experience and Studio API
access. Use an **existing dedicated test experience you own**, with the current
Rojo source synced into it. This task did not create or publish one. If no suitable
test experience exists, leave cloud testing pending; memory play cannot prove rejoin
persistence. Do not publish the main experience as a shortcut.

1. Stop Play. Open the existing test experience, connect Rojo at `localhost:34872`
   and accept the current source sync. In its **Game Settings → Security**, enable
   **Enable Studio Access to API Services**, then save the setting. Keep Output open.
2. Still in **Edit mode**, open **View → Command Bar** and run:

   ```lua
   workspace:SetAttribute("MutantFarmStudioPersistence", true)
   workspace:SetAttribute("MutantFarmTestSlot", "m4-accept-a")
   ```

   These attributes are outside the Rojo source tree. Alternatively add the Boolean
   and String attributes through Workspace Properties. Keep the same slot and the
   same Studio player/UserId for both joins. Use an unused slot for clean defaults;
   names must be 1–20 letters/digits/underscores/hyphens.
3. Press **Play**. The footer must show **Studio cloud • m4-accept-a** and **Loaded**,
   not “Session only.” A fresh slot starts at 100 Coins, six plots, only Tomato
   unlocked, no seeds/harvests/discoveries. A loading error must refuse entry;
   it must not put you into a fresh playable farm.
4. Farm normally: buy/plant/grow/harvest/sell, unlock Strawberry (and preferably
   Pumpkin), and record discoveries. Keep some seeds and harvested crops unsold
   to test both inventories. At the blue board purchase Expansion I for 500 Coins;
   verify nine usable plots and a larger garden. Keep enough Coins for seeds.
5. Harvest remaining plants. Note/screenshot Coins, all seed counts, basket counts
   per mutation in Book, discoveries, unlocked crops, Seeds-panel progression
   counters, and expansion tier. In the **server** Command Bar while Play is running:

   ```lua
   print(game.ServerStorage.MutantFarmSave:Invoke())
   ```

   Expect **Saved** in Output and the footer. If it reports failure or “Session
   only,” do not count this as a persistence pass. This Studio/server-only helper
   permits one manual save per ten seconds; optionally pass a specific UserId.
6. Stop Play normally and let Studio finish stopping. Press Play again with the
   **same test slot**. Verify every recorded value remains, nine plots return empty,
   and farming/buying/harvesting/selling still work. The required save/rejoin test
   is not complete until you perform this step.
7. For a **new test player profile**, stop Play and change the slot in Edit mode:

   ```lua
   workspace:SetAttribute("MutantFarmTestSlot", "m4-fresh-b")
   ```

   Play: verify clean 100-Coins/six-plot/Tomato-only defaults and empty inventories,
   counters and Book. This creates a different isolated profile; it does not delete
   the first one. Stop, restore `m4-accept-a`, and verify the original progress again.
8. Repeat with Expansion II: twelve plots, 1,500 Coin deduction, max status, no
   further purchases. Save/rejoin and verify all twelve persist. Test planting and
   harvesting on new plots and confirm existing plants survive an expansion.

For normal offline Studio play afterward, stop Play and run in Edit mode:

```lua
workspace:SetAttribute("MutantFarmStudioPersistence", false)
```

Memory mode always displays **Session only • not persistent**. Its saves are local
to the running server and disappear when it stops. No cloud requests occur.

### Isolation and failure checks

- Studio cloud always uses store **MutantFarm_StudioTests**, scope **test_v1**,
  keys `test_<slot>_player_<UserId>`. Production uses **MutantFarm_Players**,
  scope **live_v1**, keys `player_<UserId>`. Studio attributes cannot select the
  production store. Mutation previews remain Studio-only and do not grant items,
  unlocks or discoveries.
- After a successful test save/stop, temporarily disable Studio API access on the
  dedicated test experience while keeping cloud mode selected. Play should refuse
  loading rather than create defaults. Re-enable access and rejoin the original
  slot: the last saved data should remain. Restore the test setting afterward.
- Wait over 65 seconds after changing inventory: verify autosave feedback, then
  rejoin. Also make a change and leave normally without invoking manual save to
  exercise the departure save. Check Output for any save warnings.
- After a crash/forced stop a stale lock can block rejoin for up to three minutes.
  Wait and retry; do not delete or overwrite the stored record to bypass it.
- Two-player Studio test: each player has their own inventory/land; another player's
  board/plots cannot spend your Coins or grant their crops. In a multi-client test,
  pass the intended UserId to the manual-save helper.

## Validation performed and limits

- Rojo build: **PASS**, one server Script, one LocalScript, ten ModuleScripts.
- Static checks: **PASS** for server module placement, preview guards, outbound
  feedback, request validation, store separation, session token check and shutdown hook.
- `git diff --check`: **PASS** at implementation checkpoint.
- Added twelve deterministic persistence/expansion tests covering defaults, migration,
  corrupt records, inventory round trips, seed consumption, expansion pricing,
  failed loads/writes, competing/expired leases, idempotent retries and release/rejoin.
  **Not executed:** standalone Luau is not installed. Existing gameplay tests are
  also retained. No new dependencies were installed.
- **Owner-confirmed Studio acceptance: PASS.** Save/rejoin preserved progression
  and purchased farm expansion; the expansion system works.
- Separate failure-injection, forced-shutdown, multiplayer and fresh-profile checks
  have not been individually reported. Rojo does not compile Luau or prove runtime behavior.

Milestone 5 has not started.
