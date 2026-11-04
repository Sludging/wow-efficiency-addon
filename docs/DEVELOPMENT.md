# Development guide

WoW saves collected data in `WowEfficiency.lua`, using the SavedVariables global `WowEfficiencyDB`.
The website reads this local file to show character progress.

## Edition configuration

[`Edition.lua`](../Edition.lua) loads immediately after [`Init.lua`](../Init.lua), before data files and collector modules.
It stores the selected configuration in `addonNamespace.Edition`.

Model the game edition above its content expansions.
Use the selected edition to choose content and collector behavior rather than treating an edition as another expansion.
`Edition.lua` is the source of truth for client detection, collector selection, content keys, and collection thresholds.
Read those values from the configuration instead of duplicating them in modules or documentation.

Edition detection must distinguish clients that share a project ID.
Do not assume the project ID alone identifies the edition.

### Collector selection

`addonNamespace.Edition.collectors` selects collector implementations by their Ace module names.
Each collector checks its selection before registering a module or capturing edition-specific game APIs.
This keeps inactive implementations from requiring their APIs during file loading.
The selection describes supported addon implementations, not which systems or APIs exist in an edition.
Share data structures and collector behavior where their contracts match; edition support does not require a separate addon.

The shared status panel creates cards only for registered collectors.
It must not require inactive collector modules.
Create frames once, then update their text, textures, visibility, and layout in place.
Refreshes must not create frames and should subscribe only to relevant data-update events.
If no active collector has a status card, show a short notice.
Keep display eligibility distinct from collection eligibility, and derive edition-dependent behavior from the selected configuration.

### Quest data

Quest data files populate the profession, delve, and event namespace roots.
The shared quest collector selects content from these roots when its file loads.
It references the selected tables and builds one list of unique quest IDs.

Select content keys and the minimum collection level from the edition configuration.
The collection threshold controls when the collector can run; individual objectives can have higher eligibility requirements.
Keep edition-specific data selection separate from shared collection behavior.

An empty selected quest list must not advance quest freshness.
Completed quest flags use the shared weekly reset policy rather than a separate edition-specific reset mechanism.

Configuration and static inspection alone do not establish client compatibility.
Verify startup, API calls, event delivery, collection, and saved data in the target game client before release.

## Releases

### Release notes

[`RELEASE_NOTES.md`](../RELEASE_NOTES.md) contains the current release notes for players.
Replace its contents for each release.
Describe changes that players can observe.
Review the notes against the release changes before merging.
Keep development details and release tooling changes out of this file.
The release tag supplies the version, so the notes do not need a version heading.

The `manual-changelog` setting in [`.pkgmeta`](../.pkgmeta) selects `RELEASE_NOTES.md` as Markdown.
The packager uses these notes for CurseForge and the GitHub release.
The ZIP also contains `RELEASE_NOTES.md`.
The workflow rejects missing, empty, or whitespace-only notes before packaging and publishing.

### Publish a release

1. Test the addon in the game.
2. Prepare `RELEASE_NOTES.md`.
3. Review the notes against the release changes.
4. Merge the release changes into `main`.
5. Create an annotated `vMAJOR.MINOR.PATCH` tag on the merged commit.
6. Push that tag to start the GitHub Actions release workflow.
7. Check the workflow result.
8. Check the uploaded file.

Choose the addon version independently of the WoW patch number.
The workflow accepts only annotated version tags whose commits are reachable from `main`.
[BigWigs packager](https://github.com/BigWigsMods/packager) uploads the package to CurseForge project `1268061`.
It also attaches the ZIP to a GitHub release.
CurseForge approval can remain pending after a successful upload.

The workflow requires `CF_API_KEY`.
It uses GitHub's built-in `GITHUB_TOKEN` with `contents: write` permission.
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
The local script does not support Forever packaging.
The local ZIP is not a published release.
The packager derives the version from Git.
Use a checkout of the intended annotated release tag when you need a local package for that release.
Do not rename a development ZIP to make it look like a tagged release.
