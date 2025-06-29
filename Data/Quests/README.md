# Quest Data Structure

This directory contains quest data organized by logical groups and categories using a **shared namespace pattern**.

## Structure

```
Data/Quests/
├── README.md
├── Professions/
│   ├── Alchemy.lua          # Alchemy quest data
│   ├── Blacksmithing.lua    # Blacksmithing quest data
│   ├── Enchanting.lua       # Enchanting quest data
│   └── ...                  # Other profession files
└── Events/                  # Example for future expansion
    ├── Halloween.lua        # Halloween event quests
    └── Christmas.lua        # Christmas event quests
```

## File Format

Each quest data file directly populates the shared addon namespace with categories as keys and arrays of quest IDs as values:

```lua
-- Example: Data/Quests/Professions/Alchemy.lua
-- Get the addon namespace
local _, WowEfficiency = ...

-- Initialize the ProfessionQuests table if it doesn't exist
WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}

-- Populate Alchemy quest data
WowEfficiency.ProfessionQuests.Alchemy = {
    Artisan = { 84133 },
    Darkmoon = { 29506 },
    Treasure = { 83253, 83255 },
    Treatise = { 83725 },
    Uniques = { 81146, 81147, 81148, 82633, 83058 }
}
```

**Key Points:**
- Always get the addon namespace: `local _, WowEfficiency = ...`
- Initialize the parent table: `WowEfficiency.ProfessionQuests = WowEfficiency.ProfessionQuests or {}`
- Populate your specific data: `WowEfficiency.ProfessionQuests.YourCategory = { ... }`

## Adding New Quest Groups

1. Create a new directory under `Data/Quests/` (e.g., `Events/`, `Raids/`, `PvP/`)
2. Create individual quest files in that directory using the namespace pattern
3. **⚠️ IMPORTANT**: Add all new quest data files to `WowEfficiency.toc` in the "Quest Data Files" section
4. Update the `StructuredQuests` table in `Modules/Quests.lua` to include your new group:
   ```lua
   local StructuredQuests = {
       Professions = addonNamespace.ProfessionQuests or {},
       Events = addonNamespace.EventQuests or {},  -- Add this line
   }
   ```

## Adding New Quests to existing groups

To add quests to an existing profession or group:
1. Edit the appropriate `.lua` file (e.g., `Data/Quests/Professions/Alchemy.lua`)
2. Add your new category or add quest IDs to existing categories
3. The changes will be automatically loaded when the addon restarts
4. **No TOC update needed** for changes to existing files

## Adding New Individual Quest Files

When adding a new profession or individual quest file:
1. Create the new `.lua` file (e.g., `Data/Quests/Professions/Cooking.lua`)
2. Add the quest data using the namespace pattern (see File Format section above)
3. **⚠️ CRITICAL**: Add the new file to `WowEfficiency.toc` in the "Quest Data Files" section:
   ```
   # Quest Data Files - these populate the addon namespace when loaded
   Data\Quests\Professions\Alchemy.lua
   Data\Quests\Professions\Blacksmithing.lua
   Data\Quests\Professions\YourNewFile.lua  # Add this line
   ```

## TOC File Requirements

**⚠️ NEVER FORGET**: All quest data files MUST be listed in `WowEfficiency.toc` for the addon to work properly.

- Files not in the TOC won't be included in addon distributions
- WoW's addon loader won't execute files that aren't in the TOC
- Missing files will cause quest data to be missing from the tracking system

**Load Order**: Quest data files must be loaded BEFORE `Modules\Quests.lua` in the TOC so the namespace is populated when the Quests module initializes.

## Benefits

- **Modular**: Each profession/group has its own file
- **Maintainable**: Easy to find and update specific quest data
- **Extensible**: Simple to add new quest groups or categories
- **Namespace Safe**: All data is contained within the addon's namespace to avoid conflicts
- **Performance**: Quest data is loaded once at startup and automatically flattened using `Table:FlattenQuestIDs()`
- **Flexible**: The recursive flattening function handles arbitrary nesting depths without hardcoded assumptions

## How It Works

1. **Loading**: Each quest data file populates the shared `WowEfficiency` namespace when loaded by WoW
2. **Collection**: The Quests module accesses all quest data from `addonNamespace.ProfessionQuests` 
3. **Flattening**: The `Table:FlattenQuestIDs()` utility recursively extracts all quest IDs from the nested structure
4. **Tracking**: The flattened list of quest IDs is used for efficient quest completion checking
