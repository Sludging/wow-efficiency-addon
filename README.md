# Wow Efficiency Addon

## Overview

This addon collects character progress for [WoW Efficiency](https://www.wowefficiency.com/).
It records profession data and completed quests that the public Battle.net API does not provide.
Profession data includes skill levels, knowledge points, specializations, concentration, and cooldowns.

WoW saves the collected data locally in `WowEfficiency.lua`.
The website reads this file in your browser to show your character's progress.

## Game support

The addon supports World of Warcraft Retail.
Forever support is under development and is not ready for use.

## Contributing

See the [developer guide](docs/DEVELOPMENT.md) for technical details and release instructions.

## Acknowledgements

These community projects informed the addon's data collection, quest tracking, and profession knowledge features:

- **[ChoreTracker](https://github.com/ThingEngineering/choretracker)** by Freddie — task and chore tracking addon
- **[CraftSim](https://github.com/derfloh205/CraftSim)** by Genju — profession crafting simulation and profit calculation
- **[Myu's Knowledge Points Tracker](https://www.curseforge.com/wow/addons/myus-knowledge-points-tracker)** by Myu — profession knowledge point tracking and visualization
- **[WeeklyKnowledge](https://github.com/DennisRas/WeeklyKnowledge)** by Liquidor — profession knowledge tracking grid
- **[wowthing-collector](https://github.com/ThingEngineering/wowthing-collector)** by Freddie — in-game data collector for wowthing.org
