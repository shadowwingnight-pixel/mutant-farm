# M8 — Mutation Research & Cross-breeding V1

Status: **manual Studio acceptance PASSED**, confirmed by the project owner.
Research, specimen consumption, Coin cost, experimental seeds, planting/harvesting,
inherited traits, Discovery Book integration, rejection cases, exploit/replay
protection, Meteor interaction and schema v3 persistence/rejoin work correctly.
The owner authorized pushing completed M8 commits. No experience publication or M9 work.

## Loop and controls

Harvest two normal-inventory crops (any existing mutation), keep them instead of
selling, and visit the small workbench beside Dr. Lumen (X=-113, Z=-18). Press **R**
or tap **Research**. F still talks to Lumen; E shop/selling interactions are unchanged.

Choose slot A, click a specimen, then choose slot B. Selection reserves/consumes
nothing. The confirmation button explicitly consumes **one crop from each slot and
20 Coins**. Identical selections require two copies. A successful cross produces
one experimental seed. The panel reports rejected operations without spending anything.

Open **Seeds → Experimental seeds & harvests**, choose Plant, close the panel and
click your existing empty soil. Normal seed selection/purchasing switches back to
normal planting. Experimental harvests keep their trait and rolled mutation in
the experimental inventory; **Sell all includes them**. View their counts/traits
in the same Experimental panel before selling. These harvests cannot become research
parents in V1. All currently unreserved normal crops still participate in Sell all.

## Centralized V1 rules

`Config.Research` contains prices, traits, weights, compatibility and inventory caps.

- Compatible pairs: Tomato × Tomato, Strawberry × Strawberry, Pumpkin × Pumpkin,
  and Tomato × Strawberry (either order). Pumpkin with another species is rejected.
- Output species is one of the two parents, chosen equally; same-species pairs
  keep their species. Existing crop unlock rules and seed prices are unchanged.
- Each result inherits one dominant trait, weighted by both parental mutations:
  Normal favors Growth, Giant favors Size, Golden favors Value, Crystal favors
  Affinity/Value, Cosmic favors Affinity. Other traits always remain possible.
- **Growth:** 20% shorter growth, +10% sale value.
- **Size:** 25% larger plant/fruit, +20% sale value.
- **Value:** +50% sale value.
- **Affinity:** +10% sale value; non-Normal mutation weights ×1.5 at maturity,
  after existing environmental modifiers. Normal keeps its weight. Cosmic is never
  guaranteed. Base mutation values/probabilities remain unchanged for normal crops.
- Sale values round down after multiplying base crop value, mutation and trait.
- Twelve finite result classes (three crops × four traits), named e.g. **EXP-T-GR**.
  Crop and trait are immutable catalog metadata; identical results stack. No per-item
  GUIDs or unbounded family trees. Parent crop/mutation IDs refer to existing basket
  stacks; exact individual lineage is not retained.
- Maximum 999 seeds per class and 999 harvests per class/mutation. Research rejects
  before consuming if any possible seed result is full. A full harvest stack leaves
  the mature plant intact until space is available. No new normal crop species.

Plants use existing growth stages, soil ownership and maturity rolls. Colored
research stakes and EXP/trait labels distinguish them; Size also changes geometry.
Cosmic-parent research reuses bounded spark/reveal effects without promising Cosmic.

## Discovery and saving

**Book → Research / Hybrid discoveries** shows first research, four compatible crop
pairs, four inherited traits and whether each trait has been grown/harvested. Unknown
entries stay ???. Experimental harvests also record the existing crop/mutation Book
entry and count toward that crop's existing harvest progression. Normal Book basket
counts remain normal inventory; trait-bearing counts are in the Experimental panel.

Schema **v3** adds experimental seeds/harvests, selected experimental seed, research
count and bounded discovery flags. Versions 0–2 receive defaults and retain existing
data. Invalid/newer fields fail closed; no second store or save system. Counts and
inventory/research changes are saved together using existing session-owned writes.
Successful research schedules a save within about three seconds. Normal outage and
last-successful-save limits remain. **Actively planted crops still reset on leaving**;
harvest experimental plants before leaving, or leave seeds unplanted for persistence QA.

Requests whitelist action/IDs and validate living character, loaded profile,
distance, rate, compatibility, owned quantities and Coins. Confirmation tickets
expire after 60 seconds and are single-use. RNG and capacity checks happen before
an atomic non-yielding debit/seed grant. Duplicate tickets cannot generate another
result. Separate fresh confirmations are separate paid experiments.

## Safe Studio QA

Use the existing dedicated Studio test experience and API access from
[M4 persistence testing](MILESTONE4.md). Do not publish the live experience.
In Edit mode before Play, choose an unused isolated test slot:

```lua
workspace:SetAttribute("MutantFarmStudioPersistence", true)
workspace:SetAttribute("MutantFarmTestSlot", "m8-accept-01")
```

Use a different unused name if needed. Keep that slot and player/UserId for rejoin.
Set the Boolean false for session-only testing, which does not prove persistence.

The following are **Server Command Bar during Play** helpers. They are installed
and callable only in Studio/server context, never through a production client.
Grants alter your Studio profile and can persist in its isolated cloud test slot.

```lua
-- Grant 2 actual test specimens of each type (no production probability changes):
game.ServerStorage.MutantFarmResearch:Invoke("Grant", "Tomato", "Normal", 2)
game.ServerStorage.MutantFarmResearch:Invoke("Grant", "Tomato", "Giant", 2)
game.ServerStorage.MutantFarmResearch:Invoke("Grant", "Tomato", "Golden", 2)
game.ServerStorage.MutantFarmResearch:Invoke("Grant", "Strawberry", "Crystal", 2)
game.ServerStorage.MutantFarmResearch:Invoke("Grant", "Tomato", "Cosmic", 2)
game.ServerStorage.MutantFarmResearch:Invoke("Grant", "Pumpkin", "Normal", 2)
-- Set test Coins, not an additional reward:
game.ServerStorage.MutantFarmResearch:Invoke("Coins", nil, nil, 500)
-- Inspect Coins, normal specimens, experimental seeds/harvests, traits and Book flags:
print(game.ServerStorage.MutantFarmResearch:Invoke("Inspect"))
```

Grant amounts are 1–20, test Coins 0–5000. Optional fifth argument targets a UserId;
otherwise helpers select the first test player. Existing mutation-preview commands
remain cosmetic only and cannot supply harvestable research specimens.

## Exact acceptance walkthrough

1. Stop Play, sync Rojo, start Play. Verify the test-cloud footer. Farm normally:
   buy, plant and harvest **two crops**. Do not sell them. Finish M7 objectives first
   if you want reward-free Coin comparisons, or record any tutorial rewards separately.
2. Talk to Dr. Lumen (F), then open Research (R). Inspect available counts. Select
   A and B; verify neither counts nor Coins change until confirmation. Check cost.
3. Confirm once. Expect **exactly two parents removed, 20 Coins removed and one seed
   added**. Verify first-research feedback and use Inspect to record its class/trait.
4. Seeds → Experimental: select the result. Plant on empty soil, observe marker,
   designation and growth. Growth trait takes 12s Tomato / 17.6s Strawberry / 25.6s
   Pumpkin; other traits retain 15/22/32s. Harvest exactly once. Inspect trait/rolled
   mutation and Book's research section. Check the basket's calculated sale value.
5. Test Giant + Normal, Golden Tomato + Crystal Strawberry, and Cosmic + Normal
   using the helpers. Results vary; trait tendencies are not guarantees. Confirm
   the brief Cosmic-parent reveal and Lumen's special Cosmic-parent dialogue.
6. Select Pumpkin + Tomato: expect incompatibility, unchanged Coins/parents/seeds.
   Set test Coins to zero and try a compatible pair: expect insufficient Coins and
   no consumption. Restore 500. Choose the same specimen twice when only one remains:
   expect rejection. Walking away from the lab must prevent confirmation spending.
7. Spam the confirmation button: one accepted request clears the slots; another
   experiment requires selecting again. For an explicit **same-ticket replay** test,
   first run in the **Client Command Bar** while beside the bench:

   ```lua
   if _G.m8Listen then _G.m8Listen:Disconnect() end
   _G.m8Listen = game.ReplicatedStorage.FarmFeedback.OnClientEvent:Connect(function(p)
       if p.kind == "ResearchState" then _G.m8Ticket = p.token end
   end)
   ```

   Reopen Research to receive a ticket. Ensure at least two Normal Tomatoes and
   20 Coins; note Inspect counts. Then run in the **Client Command Bar**:

   ```lua
   local ticket = _G.m8Ticket
   for i = 1, 20 do
       game.ReplicatedStorage.FarmResearch:FireServer("Cross", "Tomato_Normal", "Tomato_Normal", ticket)
       task.wait(0.1)
   end
   _G.m8Listen:Disconnect()
   ```

   Expect **at most one** paid experiment (none if ticket expired/cooldown), never
   twenty. Inspect again on Server. Malformed/unknown specimen IDs must grant nothing.
8. Create another experimental seed and leave it unplanted; retain one experimental
   harvest too. Record Inspect output, Book, normal inventory and M7 step. Server:

   ```lua
   print(game.ServerStorage.MutantFarmSave:Invoke())
   ```

   Wait for Saved, Stop/Play using the same slot. Verify all seeds, harvest traits,
   research count/discoveries, Coins, M7 step, expansions and normal progression remain.
   Reopen/close Research without confirming: no duplicated or consumed items.
9. Plant an experiment, then force Meteor before maturity:

   ```lua
   game.ServerStorage.MutantFarmEnvironment:Invoke("Meteor")
   print(game.ServerStorage.MutantFarmEnvironment:Invoke("Inspect"))
   -- Wait for maturity, harvest; no particular mutation is guaranteed.
   game.ServerStorage.MutantFarmEnvironment:Invoke("EndMeteor")
   game.ServerStorage.MutantFarmEnvironment:Invoke("Resume")
   ```

10. Sell the experimental harvest: correct trait-adjusted Coins, cleared basket,
    discoveries retained. Recheck normal farming, crop selection, NPC objectives,
    expansions, weather and existing QA controls. Test narrow/mobile screen scrolling
    and slot controls, and separate inventories in a two-player session. Keep Output
    open for runtime errors.

## Automated validation / limits

Rojo build, module placement, static authority/Studio guards and whitespace checks
passed. Added deterministic tests covering identical-parent consumption, invalid
pairs/requests, low Coins, capacity, inheritance bounds, farming/sales, affinity
with weather and schema migration. Standalone Luau tools remain unavailable, so
these regression suites are written but **not executed**. Rojo does not compile Luau
or establish Studio runtime correctness. Owner manual Studio acceptance has passed.

No recursive hybrid breeding, exact per-seed lineage, reserved specimen storage,
new normal crop species or new mutation tier. Dialogue samples current conditions
when opened. Research has a 1.5s cooldown and a 60s confirmation lifetime; reopen the
bench if confirmation expires. Environmental authority and production odds are unchanged.
