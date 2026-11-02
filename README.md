## Overview

This World of Warcraft addon is the official companion for the WoW Efficiency website (`https://www.wowefficiency.com/`).

Its primary function is to automatically collect detailed information about your characters directly from the game. This includes:

*   **Profession Data:** Skill levels, knowledge points (spent and unspent), specialization progress, profession stats like Concentration, and cooldown tracking.
*   **Quest Completion:** Records of completed quests, used for task tracking.

This collected data is saved locally within your WoW SavedVariables (`WowEfficiency.lua`). The WoW Efficiency website can then utilize this data to provide comprehensive tracking, analysis, and efficiency tools for your characters.

## Releases

### Release notes

`RELEASE_NOTES.md` contains the current release's player-facing notes in Markdown.
Replace its contents for each release.
Describe changes that players can observe.
Review the notes against the release changes before merging.
Keep development details and release tooling changes out of this file.
The release tag supplies the version, so the notes do not need a version heading.

The `manual-changelog` setting in `.pkgmeta` selects `RELEASE_NOTES.md` with Markdown markup.
The packager uses these notes for CurseForge and the GitHub release.
The ZIP also contains `RELEASE_NOTES.md`.
The workflow rejects missing, empty, or whitespace-only notes before packaging and publishing.

### Publish a release

1. Test the addon in-game.
2. Prepare `RELEASE_NOTES.md`.
3. Review the notes against the release changes.
4. Merge the release changes into `main`.
5. Create an annotated `vMAJOR.MINOR.PATCH` tag on the merged commit.
6. Push that tag to start the GitHub Actions release workflow.
7. Check the workflow result.
8. Check the uploaded file.

Choose the addon version independently of the WoW patch number.
The workflow accepts only annotated version tags whose commits are reachable from `main`.
[BigWigs packager](https://github.com/BigWigsMods/packager) uploads the package to CurseForge project `1268061` and attaches the ZIP to a GitHub release.
CurseForge approval can remain pending after a successful upload.

The workflow requires `CF_API_KEY` and uses GitHub's built-in `GITHUB_TOKEN` with `contents: write` permission.
A missing `CF_API_KEY` stops the release.
Never paste secrets into chat or commit them.

The packager replaces `## Version: @project-version@` in the packaged TOC with the Git tag.
The separate `## Interface` value declares WoW client compatibility.
It does not set the addon release version.

### Local packaging fallback

Run this command from the repository root:

```bash
bash Scripts/release.sh -p 1268061 -d
```

This command packages the working tree into `.release/` without publishing it.
The local ZIP is not a published release.
The packager derives the version from Git.
Use a checkout of the intended annotated release tag when you need a local package for that release.
Do not rename a development ZIP to make it look like a tagged release.

## Acknowledgements

This addon's approach to data collection, quest tracking, and profession knowledge was informed by several community projects:

- **[ChoreTracker](https://github.com/ThingEngineering/choretracker)** by Freddie — task and chore tracking addon
- **[CraftSim](https://github.com/derfloh205/CraftSim)** by Genju — profession crafting simulation and profit calculation
- **[Myu's Knowledge Points Tracker](https://www.curseforge.com/wow/addons/myus-knowledge-points-tracker)** by Myu — profession knowledge point tracking and visualization
- **[WeeklyKnowledge](https://github.com/DennisRas/WeeklyKnowledge)** by Liquidor — profession knowledge tracking grid
- **[wowthing-collector](https://github.com/ThingEngineering/wowthing-collector)** by Freddie — in-game data collector for wowthing.org
