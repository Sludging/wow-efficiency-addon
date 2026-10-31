# Skill: Add Quest Data

Use this skill when the user wants to add, modify, or organize quest tracking data in the addon.

## Quest Sources

For patch work, read `../wow-efficiency/.claude/skills/static-data-updates/SKILL.md` from the addon repository root.

Use official notes to set the relevant scope.
Check whether local reference addons in `.reference-repos/` are maintained.
Refresh maintained repositories before using their data.
Use reference addon IDs and tracking rules first.
Use guides such as Wowhead to cross-check.
Use datamining, UI source, and in-game queries only for missing information.

## How Quest Data Works

Quest data lives in `Data/Quests/` as pure data files, separate from tracking logic. Each file populates the shared addon namespace (e.g., `WowEfficiency.ProfessionQuests`) which the Quests module reads at load time. Add quest IDs to existing groups without changing collection logic.

Quest groups (like `Professions`, `Delves`) each have their own namespace key and subdirectory. Within a group, each file represents a specific topic (e.g., one file per profession) and organizes quest IDs into named categories.

## What Needs to Change

The scope depends on what's being added:

Addon quest IDs control collection.
Website objectives define tracked goals.
Update website objectives when tracked quests or rules change.
Add static metadata when the website needs names or images for new IDs.
Static metadata does not define objectives or player state.
Not every edit needs changes in all layers.

### Adding quest IDs to an existing file
Edit the addon data file. Apply the website changes described above when needed.

### Adding a new file to an existing group (e.g., a new profession)
1. Create the data file in the appropriate `Data/Quests/<Expansion>/<Group>/` directory. Follow the pattern of an existing file in the same group - they all share the same namespace key and structure.
2. Add the file to `WowEfficiency.toc` in the quest data section. It must appear **before** `Modules\Quests.lua` in the TOC. Place it alphabetically within its group.

### Adding an entirely new quest group (e.g., "Raids", "Events")
1. Create a new subdirectory under `Data/Quests/` and add data file(s) following the namespace pattern - look at existing groups for the convention, but use a new namespace key (e.g., `WowEfficiency.RaidQuests`).
2. Add the files to `WowEfficiency.toc` before `Modules\Quests.lua`.
3. Update the `StructuredQuests` table in `Modules/Quests.lua` to include the new group from the namespace.

## Key Things to Remember

- Quest IDs are plain numbers. Use the source order above.
- TOC paths use backslashes (`Data\Quests\TWW\Professions\Alchemy.lua`)
- Data files must load before `Modules\Quests.lua` in the TOC or the data won't be available
- The `Table:FlattenQuestIDs()` utility recursively extracts all numeric IDs from any nesting depth, so category structure is flexible
