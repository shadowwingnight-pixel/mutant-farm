# Milestone 5 — Living World

Status: **manual Studio acceptance PASSED**, confirmed by the project owner.
Day/night, Clear, Rain, Thunderstorm, Meteor Shower, HUD, environmental mutation
modifiers, farming during environmental states, event cleanup and existing gameplay
all passed. The owner authorized pushing Milestone 5. This task did not publish/update
the experience. Milestone 6 has not started.

## Behavior and balance

Server-wide cycle: Day 120s → Evening 40s → Night 80s → Day (four minutes total).
Lighting blends for five seconds at transitions. Weather rolls every 90s:
Clear 60%, Rain 30%, Thunderstorm 10%; a roll can retain the current weather.
Thunderstorm produces a brief lightning bolt/soft flash every 10–18s.

Meteor Shower has a 12% chance per eligible 120-second check, lasts 45 seconds,
and has a 240-second cooldown after ending. It overlays the current weather/time;
those systems keep running. Ending restores the **current** weather/time appearance,
not stale settings from before the event. Events do not damage players or crops.

Baseline mutation weights remain 7,000 / 1,800 / 1,000 / 190 / 10. Modifiers multiply
weights, then round once to a positive integer and normalize by the new total.
They do not multiply the final probability directly. Normal's weight stays 7,000.

| Condition | Golden/Giant weight | Crystal weight | Cosmic weight |
| --- | --- | --- | --- |
| Clear + Day/Evening | ×1 | ×1 | ×1 |
| Rain | ×1.10 | ×1.30 | ×1.40 |
| Thunderstorm | ×1.20 | ×1.70 | ×2 |
| Night | ×1.05 | ×1.15 | ×1.20 |
| Meteor Shower | ×1.15 | ×1.80 | ×3 |

Weather, Night and Meteor factors stack multiplicatively. Approximate Cosmic chances:
baseline **0.100%**, Rain/Day **0.135%**, Thunderstorm/Day **0.187%**,
Clear/Night **0.118%**, Clear/Day/Meteor **0.283%**,
Thunderstorm/Night/Meteor **0.610%**. All outcomes remain possible; Cosmic is never
guaranteed. Crop values and mutation sell multipliers have not changed.

**Conditions at maturity determine the single roll.** Planting during an event does
not reserve its bonus; mature before it ends. READY crops never reroll when conditions
change. All three crops share the same server-side environmental weights.

All timing, weather weights, mutation factors and effect limits are in
`Config.Environment`; the original `Config.Mutations` table is unchanged.

## Architecture and limits

- `EnvironmentState`: pure server schedule, preview holds and derived mutation weights.
- `EnvironmentService`: server RNG, atomic replicated snapshot, outbound lightning,
  Studio-only BindableFunction. Main advances it before each crop-growth pass and
  passes cached server weights to `FarmState:advance`. No client environment requests.
- `EnvironmentView`: cosmetic Lighting/Atmosphere interpolation, local rain/meteors,
  lightning, compact HUD and brief meteor announcement. Late joiners read the current
  snapshot, including the server event deadline. Clients never decide mutation odds.
- No save-schema or persistence changes. World conditions are ephemeral per server;
  farm ownership, economy, growth timers, expansions, Book and save feedback remain intact.
- Rain uses 24/40 pooled cosmetic Parts at 20Hz, with collision/query/touch/shadows
  disabled. Meteors cap at three Parts with 1.4s lifetimes; lightning caps at three
  Parts with 0.3s lifetimes. No downloaded textures, meshes or audio.
- Clear destroys rain. Event end immediately clears meteor Parts and restores the
  normal condition palette. Leaving storm clears lightning/flash. UI destruction
  disconnects this module's connections, destroys its objects and restores prior Lighting.
- Lightning is **silent by default**. `Visuals.ThunderSoundId` is an empty optional
  hook for a future owned/authorized sound; no copyrighted audio was added.
- Rain is a camera-local open-farm prototype, without roof occlusion. Visuals and
  narrow/mobile layouts need Studio review. Weather transitions do not stop farming.

Lighting is client-rendered from authoritative server conditions because Roblox's
[Lighting.ClockTime](https://create.roblox.com/docs/reference/engine/classes/Lighting#ClockTime)
is not replicated. Interpolation uses Roblox's
[TweenService](https://create.roblox.com/docs/reference/engine/classes/TweenService).

## Exact Studio acceptance test

1. Stop any running Play session. Sync the current Rojo source (`localhost:34872`),
   then press **Play**. For visual QA use the existing default Studio memory mode;
   do not change persistence settings or publish anything. Check Output for errors.
2. Switch the Command Bar to the **server** context. Run the commands below **one at
   a time**, allowing at least five seconds to view each transition. Each prints JSON
   with current state, hold flags, individual factors/weights and normalized percentages.

   ```lua
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("EndMeteor"))
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Day"))
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Clear"))
   ```

   Expect DAY • CLEAR; no rain/meteors; `totalWeight=10000`, Cosmic weight 10,
   Cosmic percent 0.1. Day and Clear remain held for controlled testing.

3. **Rain:**

   ```lua
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Rain"))
   ```

   Expect visible rain, cooler/hazier light, DAY • RAIN, Cosmic weight 14 and
   approximately 0.135%. Buy/plant a Tomato and confirm normal farming input works.

4. **Thunderstorm:**

   ```lua
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Thunderstorm"))
   ```

   Expect heavier rain and darker sky. Wait up to 18 seconds for a brief bolt/soft
   flash (silent). Cosmic weight 20, approximately 0.187%. Harvest/sell normally.

5. **Night:**

   ```lua
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Night"))
   ```

   Expect NIGHT • THUNDERSTORM and readable nighttime farm lighting. Cosmic weight
   becomes 24. Verify crops and interaction prompts remain visible and usable.

6. **Meteor Shower:**

   ```lua
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Meteor"))
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Inspect"))
   ```

   Expect a server-wide announcement, purple atmospheric tint, meteors overhead and
   a 45-second HUD countdown. In this stacked test Cosmic weight is 72 and chance
   approximately 0.610%. Plant/harvest before the event ends. A Normal crop is still
   expected frequently; do not require a Cosmic roll to pass the test.

7. **Automatic end:** wait 45 seconds without another command. Expect an end
   announcement, zero active meteor Parts, no event label and restored NIGHT/STORM
   palette. `Inspect` should show `meteorEndsAt=0` and Cosmic weight back to 24.
   Then test an early end:

   ```lua
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Meteor"))
   -- Wait a few seconds, then:
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("EndMeteor"))
   ```

   Repeat start/end twice: no lingering meteors, stale tint or duplicate announcements.
   Repeated Meteor while already active must not extend its original deadline.

8. **Clear, restore baseline and resume:**

   ```lua
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Clear"))
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Day"))
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Inspect"))
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Resume"))
   ```

   Clear removes rain/lightning; Day restores baseline mutation weights. Resume
   releases the time/weather holds without skipping or restarting an active event.
   Watch the four-minute DAY → EVENING → NIGHT → DAY cycle. Optional direct command:
   `game.ServerStorage.MutantFarmEnvironment:Invoke("Evening")`.

9. **Cleanup/performance:** inspect **client** Explorer during Play at
   `Workspace.LocalFarmEnvironment`. Rain: 0/24/40 Parts depending on weather;
   Meteors: at most 3, zero after end; Lightning: at most 3, gone within 0.3s.
   Reset your character: no second environment folder/HUD. Repeat storm/clear and
   meteor/end transitions to check for accumulating instances or Output errors.
10. **Regression:** farm Tomato/Strawberry/Pumpkin, change seed selection, sell,
    check unlocks/Discovery Book, and plant in expanded plots. Confirm Coins and
    save feedback still work. Repeat the existing [isolated persistence rejoin
    procedure](MILESTONE4.md#safe-studio-persistence-test--exact-procedure) if using
    the dedicated test experience; never use production data for QA.
11. **Existing mutation preview:** still visual-only, unlike environment overrides
    which affect actual Studio crop rolls:

    ```lua
    game.ServerStorage.MutantFarmPreview:Invoke("Cosmic", nil, "Pumpkin")
    game.ServerStorage.MutantFarmPreview:Invoke("Clear")
    ```

12. **Two-player check:** use Studio's server/two-client test. Force conditions from
    the server Command Bar and verify matching HUD/state, event start/end and effects
    on both clients. Join during an active event if practical. The environment bindable
    lives only in ServerStorage and is installed/invoked only when IsStudio/IsServer
    both hold; production clients cannot force conditions or supply mutation factors.

## Automated validation

`tests/validate.ps1`: Rojo build and static boundaries pass (one Script, one
LocalScript, thirteen ModuleScripts). `git diff --check` passes. No dependencies
were installed. Nine new deterministic environment tests cover baseline equivalence,
time/weather boundaries, all modifier combinations, rarity, event lifetime/cooldown,
QA holds/resume, and once-only maturity rolls/rewards across all crops.

**Standalone Luau compilation and all Luau test suites remain unexecuted:** runner
not installed. Existing gameplay/persistence tests are retained. When official tools
are available, `tests/validate.ps1 -LuauDirectory PATH` runs all three suites.
Rojo does not compile Luau. Studio runtime/gameplay acceptance was performed and
confirmed by the project owner, not by the coding agent.

Next milestone: Mutant Farm Town / open-world foundation. Do not start until requested.
