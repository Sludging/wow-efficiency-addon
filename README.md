## Overview

This World of Warcraft addon is the official companion for the WoW Efficiency website (`https://www.wowefficiency.com/`).

Its primary function is to automatically collect detailed information about your characters directly from the game. This includes:

*   **Profession Data:** Skill levels, knowledge points (spent and unspent), specialization progress, profession stats like Concentration, and cooldown tracking.
*   **Quest Completion:** Records of completed quests, used for task tracking.

This collected data is saved locally within your WoW SavedVariables (`WowEfficiency.lua`). The WoW Efficiency website can then utilize this data to provide comprehensive tracking, analysis, and efficiency tools for your characters.

## Releases

### One-time setup

Create an upload token on the [CurseForge API Tokens page](https://authors.curseforge.com/#/settings/api-tokens).
Add it under **Settings → Secrets and variables → Actions → Repository secrets** as `CF_API_KEY`.
Never paste secrets into chat or commit them.

The workflow uses GitHub's built-in `GITHUB_TOKEN` with `contents: write` permission. No separate GitHub personal access token is needed. A missing `CF_API_KEY` fails the release instead of silently skipping the CurseForge upload.

### Publish a release

Use `v2.2.0` for the first automated release after published version `2.1.1` because it adds tracking features.
For later bug-fix releases, increment the patch number, such as `v2.2.1`. Keep addon versions separate from WoW patch numbers.

1. Test the addon in-game.
2. Merge the release changes into `main`.
3. Update your local `main`, create an annotated version tag, and push only that tag:

   ```bash
   git switch main
   git pull --ff-only
   git tag -a v2.2.0 -m 'Release v2.2.0'
   git push origin v2.2.0
   ```

Pushing a `v*` tag starts the GitHub Actions release workflow. [BigWigs packager](https://github.com/BigWigsMods/packager) packages the addon, uploads it to CurseForge project `1268061`, and attaches the ZIP to a GitHub release. Check the workflow result and the uploaded file. CurseForge approval may still be pending after a successful upload.

The packager replaces `## Version: @project-version@` in the packaged TOC with the Git tag. The separate `## Interface: 120105` declares WoW client compatibility; it does not set the addon release version. A `v2.2.0` release produces `WowEfficiency-v2.2.0.zip`.

### Local packaging fallback

From the repository root, run:

```bash
bash Scripts/release.sh -p 1268061 -d
```

This packages the working tree into `.release/` without uploading. The packager derives the version from Git, not a manually edited TOC version or ZIP name. Use a checkout of the intended annotated release tag, once created, for a release filename such as `WowEfficiency-v2.2.0.zip`. Do not rename a development ZIP to make it look like a tagged release.

## Acknowledgements

This addon's approach to data collection, quest tracking, and profession knowledge was informed by several community projects:

- **[ChoreTracker](https://github.com/ThingEngineering/choretracker)** by Freddie — task and chore tracking addon
- **[CraftSim](https://github.com/derfloh205/CraftSim)** by Genju — profession crafting simulation and profit calculation
- **[Myu's Knowledge Points Tracker](https://www.curseforge.com/wow/addons/myus-knowledge-points-tracker)** by Myu — profession knowledge point tracking and visualization
- **[WeeklyKnowledge](https://github.com/DennisRas/WeeklyKnowledge)** by Liquidor — profession knowledge tracking grid
- **[wowthing-collector](https://github.com/ThingEngineering/wowthing-collector)** by Freddie — in-game data collector for wowthing.org
