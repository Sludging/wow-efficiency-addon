# Development guide

WoW saves collected data in `WowEfficiency.lua`, using the SavedVariables global `WowEfficiencyDB`.
The website reads this local file to show character progress.

## Edition configuration

[`Edition.lua`](../Edition.lua) loads immediately after [`Init.lua`](../Init.lua), before data files and collector modules.
It stores the selected configuration in `addonNamespace.Edition`.

The configuration separates the game edition from its content expansions.
Retail uses the existing `TWW` and `Midnight` expansion data.
Forever uses a separate content selection.

Forever shares the Mainline project ID with Retail.
The addon therefore checks the interface version first.
Interface versions from 16000 through 16999 select Forever.
Other Mainline versions select Retail.

### Quest data

Quest data files populate the profession, delve, and event namespace roots.
The shared quest collector selects content from these roots when its file loads.
It references the selected tables and builds one list of unique quest IDs.

| Edition | Selected content keys | Minimum collection level |
| --- | --- | --- |
| Retail | `Shared`, `TWW`, `Midnight` | 70 |
| Forever | `Forever` | 1 |

`Shared` contains cross-expansion Retail data. It is not shared between editions.
The minimum collection level controls when the collector can run.
Individual objectives can have higher eligibility requirements.

Forever has no configured quest objectives.
An empty quest list does not update quest freshness.
Completed quest flags use the existing weekly reset policy.

Edition configuration alone does not establish Forever client compatibility.
Verify startup, collection, and saved data in the game before release.

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
