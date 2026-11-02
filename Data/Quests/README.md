# Quest Data Structure

Expansion-specific quest data lives in `Data/Quests/<Expansion>/<Group>/`.
Cross-expansion quest data lives in `Data/Quests/Shared/`.
Data files populate the addon namespace before `Modules/Quests.lua` builds the tracked quest list.

Read [Add Quest Data](../../.claude/skills/add-quest-data.md) before changing quest IDs, adding files, or adding groups.
That skill defines the namespace conventions, TOC requirements, and existing weekly collection behavior.
