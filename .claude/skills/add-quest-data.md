# Add Quest Data

Use this skill when adding, changing, or organizing addon quest IDs.

## Data Layout

Quest data files populate the shared addon namespace.
They contain data rather than collection logic.
Expansion-specific files use `Data/Quests/<Expansion>/<Group>/<Topic>.lua`.
The existing expansion keys are `TWW` and `Midnight`.

The existing groups use these namespace roots:

- `Professions` uses `WowEfficiency.ProfessionQuests`.
- `Delves` uses `WowEfficiency.DelveQuests`.
- `Events` uses `WowEfficiency.EventQuests`.

Each root contains an expansion table.
That table contains topics with named quest categories.
For example, `Data/Quests/Midnight/Professions/Alchemy.lua` defines categories under `WowEfficiency.ProfessionQuests.Midnight.Alchemy`.
Event data follows the same pattern under `WowEfficiency.EventQuests.Midnight`.

Cross-expansion data lives in `Data/Quests/Shared/`.
For example, `Darkmoon.lua` defines profession quest arrays under `WowEfficiency.ProfessionQuests.Shared.Darkmoon`.

## Change an Existing File

1. Find the file for the expansion and topic.
2. Check the existing namespace and category names.
3. Add or correct IDs in the appropriate category.

Use flat arrays of positive numeric quest IDs for category values.
Use reference addons in `.reference-repos/` to cross-check quest IDs when available.
Keep non-quest numeric values outside these tables.
`Table:FlattenQuestIDs()` recursively collects every positive numeric value and removes duplicate IDs.

Changes to an existing file do not require a TOC change.
Changes within an existing group do not require collection logic changes.

## Add a File to an Existing Group

1. Create the file in `Data/Quests/<Expansion>/<Group>/`.
2. Get the addon namespace with `local _, WowEfficiency = ...`.
3. Initialize the namespace root if it does not exist.
4. Initialize the expansion table if it does not exist.
5. Define the topic's quest categories.
6. Add the file to `WowEfficiency.toc` before `Modules\Quests.lua`.

Follow an existing file from the same group for namespace initialization.
Use backslashes in TOC paths.
Keep the file with its expansion and group in the TOC.
WoW does not execute files that are absent from the TOC.

## Add a New Group

1. Create `Data/Quests/<Expansion>/<Group>/`.
2. Create the data files with a new namespace root.
3. Initialize the namespace root and expansion table in each file.
4. Add each file to `WowEfficiency.toc` before `Modules\Quests.lua`.
5. Add the namespace root to `StructuredQuests` in `Modules/Quests.lua`.

Use a distinct root such as `WowEfficiency.RaidQuests` for a new group.
The `StructuredQuests` entry makes that root available to the existing flattener.
Use the existing `Professions`, `Delves`, or `Events` group when it already fits the data.

## Collection and Weekly Reset

`Modules/Quests.lua` assembles `StructuredQuests` after the data files load.
The module flattens the groups into its tracked quest list.
It checks each ID with `C_QuestLog.IsQuestFlaggedCompleted`.
Quest and loot events trigger collection through a three-second event bucket.

The DB module stores completed IDs in each character's `completedQuests` map.
Completed IDs remain stored until the DB module processes that character's weekly reset.
New IDs use this existing collection and reset behavior.
