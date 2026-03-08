# WowEfficiency Addon

A World of Warcraft addon that collects in-game data not available from the public Battle.net API. Data is stored in WoW's SavedVariables (`WowEfficiencyDB`) and uploaded by users to the companion website (wowefficiency.com).

No test framework or linter - changes are verified by loading in-game. Release is manual: PR to `main`, run `Scripts/release.sh` (BigWigs packager), upload zip to CurseForge.

## Architecture Decisions

### Why Ace3

The addon uses Ace3 rather than raw WoW API frames/events because:
- **AceAddon** gives us a proper module system with lifecycle hooks (`OnInitialize`, `OnEnable`) and dependency ordering, avoiding the fragile "who loaded first" problem with raw addon files.
- **AceDB** handles the SavedVariables serialization and provides per-character/per-profile/global scoping out of the box - critical since we store data per character but settings per profile.
- **AceBucket** debounces event storms. WoW fires events like `QUEST_TURNED_IN` or `SKILL_LINES_CHANGED` in rapid bursts; bucketing them into 3-second windows prevents redundant API calls.
- **AceConsole** provides slash command registration (`/we`) with subcommand parsing.

### Module Separation

Each feature area is its own Ace module to enforce clear boundaries:
- **DB module** owns all SavedVariables access. Other modules never touch `WowEfficiencyDB` directly - they go through `db:GetCharDBKey()` / `db:UpdateCharDBKey()`. The update path auto-timestamps via `TrackLastUpdated()` so the website knows data freshness.
- **Quests module** handles quest completion tracking. It flattens the nested quest data structure (loaded from `Data/Quests/` files) into a flat list at load time so the runtime check is a simple loop.
- **Professions module** collects skill levels, knowledge points, and specialization trees. Sub-modules (`Cooldowns`, `Concentration`) handle data that requires an open profession window (`TRADE_SKILL_LIST_UPDATE` only fires when the UI is open).
- **Debug module** provides conditional printing gated by a profile-level `debugMode` flag, toggled via `/we debug`.

### Data Files vs Module Code

Quest IDs live in `Data/Quests/` as pure data files separate from logic, organized into subdirectories: `Shared/` (cross-expansion quests like Darkmoon), `TWW/Professions/`, `TWW/Delves/`, and `Midnight/Professions/`. This is intentional:
- Data files populate the shared addon namespace at load time (e.g., `WowEfficiency.ProfessionQuests.TWW.Alchemy = { ... }`, `WowEfficiency.ProfessionQuests.Shared.Darkmoon = { ... }`)
- The Quests module reads from the namespace and flattens everything via `Table:FlattenQuestIDs()`
- This means adding new quests or a new expansion never requires touching module logic - just data files and the TOC

### Weekly Reset Handling

The DB module tracks `nextWeeklyReset` per character. On login, if server time has passed the stored reset time, it wipes `completedQuests` and recalculates the next reset. This is why quest data is ephemeral (weekly) while profession data persists.

### Level Gate

Data collection uses per-expansion minimum levels: TWW requires level 70+, Midnight requires level 80+. The Professions module gates extraction per-expansion inside its loop using `minLevel` from each expansion's Constants entry. The Quests module gates on level 70 (the lowest expansion minimum) so quest tracking activates as soon as any expansion content is relevant.

### Profession Constants

All Constants tables use a profession-first, expansion-second keying pattern: `Constants[skillLineID].TWW`, `Constants[skillLineID].Midnight`. Each expansion sub-key contains `minLevel`, `skillLineVariantID`, `catchUpCurrencyID`, and (for crafting professions) `concentrationCurrencyID`. The DB stores profession data the same way: `professions[skillLineID].TWW = { level, maxLevel, ... }`. Sub-module constants (Cooldowns, Concentration) follow the same pattern. The cooldowns constants list expansion-specific `recipeID`s that have daily/charge-based cooldowns.

## TOC Load Order

The TOC file controls what WoW loads and in what order. The ordering is intentional:
1. Libraries first (they provide the framework)
2. `Init.lua` creates the addon object that everything else references
3. `DB` and `Debug` modules next since all other modules depend on them
4. Data files before `Modules/Quests.lua` so the namespace is populated when the Quests module reads it. Data files are ordered: `Data\Quests\Shared\` → `Data\Quests\TWW\` → `Data\Quests\Midnight\`
5. `Core.lua` last because it wires up slash commands that reference all modules

**Any new `.lua` file must be added to the TOC or WoW silently ignores it.** TOC paths use backslashes.

## Slash Commands

`/we` is the entry point, with subcommands: `check` (show stored quest data), `debug` (toggle debug output), `wipe` (reset all stored data). These are defined in `Core.lua`.

## Do Not Modify

- `Libs/` - vendored Ace3/LibStub, managed by `.pkgmeta`
- `.release/` - generated output from the packager
- `Scripts/` - release tooling
