# Quest Data Structure

This directory contains quest data organized by logical groups and categories.

## Structure

```
Data/Quests/
├── README.md
├── Professions/
│   ├── _loader.lua          # Loads all profession quest files
│   ├── Alchemy.lua          # Alchemy quest data
│   ├── Blacksmithing.lua    # Blacksmithing quest data
│   └── ...                  # Other profession files
└── Events/                  # Example for future expansion
    ├── _loader.lua          # Would load all event quest files
    ├── Halloween.lua        # Halloween event quests
    └── Christmas.lua        # Christmas event quests
```

## File Format

Each quest data file should return a table with categories as keys and arrays of quest IDs as values:

```lua
-- Example: Data/Quests/Professions/Alchemy.lua
return {
    Artisan = { 84133 },
    Darkmoon = { 29506 },
    Treasure = { 83253, 83255 },
    Treatise = { 83725 },
    Uniques = { 81146, 81147, 81148, 82633, 83058 }
}
```

## Adding New Quest Groups

1. Create a new directory under `Data/Quests/` (e.g., `Events/`, `Raids/`, `PvP/`)
2. Create individual quest files in that directory
3. Create a `_loader.lua` file that loads all files in that directory
4. **⚠️ IMPORTANT**: Add all new quest data files to `WowEfficiency.toc` in the "Quest Data Files" section
5. Update the `LoadQuestData()` function in `Modules/Quests.lua` to load your new group

## Adding New Quest Categories

To add quests to an existing profession or group:
1. Edit the appropriate `.lua` file (e.g., `Data/Quests/Professions/Alchemy.lua`)
2. Add your new category or add quest IDs to existing categories
3. The changes will be automatically loaded when the addon restarts
4. **No TOC update needed** for changes to existing files

## Adding New Individual Quest Files

When adding a new profession or individual quest file:
1. Create the new `.lua` file (e.g., `Data/Quests/Professions/Cooking.lua`)
2. Add the quest data in the proper format
3. Update the profession list in `Data/Quests/Professions/_loader.lua`
4. **⚠️ CRITICAL**: Add the new file to `WowEfficiency.toc` in the "Quest Data Files" section:
   ```
   # Quest Data Files
   Data\Quests\Professions\_loader.lua
   Data\Quests\Professions\Alchemy.lua
   Data\Quests\Professions\YourNewFile.lua  # Add this line
   ```

## TOC File Requirements

**⚠️ NEVER FORGET**: All quest data files MUST be listed in `WowEfficiency.toc` for the addon to work properly.

- Files not in the TOC won't be included in addon distributions
- The `dofile()` function can't access files that aren't in the TOC
- Missing files will cause the quest tracking system to fail silently

### Current TOC Section:
```
# Quest Data Files
Data\Quests\Professions\_loader.lua
Data\Quests\Professions\Alchemy.lua
Data\Quests\Professions\Blacksmithing.lua
# ... (all other profession files)
```

## Benefits

- **Modular**: Each profession/group has its own file
- **Maintainable**: Easy to find and update specific quest data
- **Extensible**: Simple to add new quest groups or categories
- **Safe**: Error handling prevents addon crashes if files are missing
- **Performance**: Quest data is loaded once at startup and flattened for efficient access 
