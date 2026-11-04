# Development guide

WoW saves collected data in `WowEfficiency.lua`, using the SavedVariables global `WowEfficiencyDB`.
The website reads this local file to show character progress.

## Edition configuration

[`Init.lua`](../Init.lua) loads first, followed by the pure profession catalogues in `Data/Professions/`.
[`Edition.lua`](../Edition.lua) then selects configuration before quest data and collector modules load.
It stores the selected configuration in `addonNamespace.Edition`.
Both edition manifests load [`WowEfficiency.xml`](../WowEfficiency.xml), which owns the ordered file list.
Add new Lua files to that XML list; keep edition manifest metadata separate from load order.

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

### Profession data

The shared profession module discovers supported professions and records reported ranks.
Collection and status display use the same discovery method, so filtering is not duplicated in the UI.
Edition configuration selects profession eligibility, secondary-slot inclusion, and status display policy.

`Data/Professions/` owns the edition-keyed profession catalogues.
`addonNamespace.Edition.professions.data` references the selected catalogue for both discovery and detail collection.
Catalogue entries use the base skill-line ID as the key.
Retail entries place expansion-specific fields under `expansions`; shared discovery does not depend on the Retail module.
Keep static API tier IDs distinct from runtime skill-line IDs, and add them only when a consumer needs them.

Store common skill data in `professions[skillLineID].base`:

- `level`: the reported current rank.
- `maxLevel`: the reported trained maximum rank.
- `professionName`: the localized profession name.

Keep these fields nested under `base`.
The legacy schema migration interprets flat rank fields as old Retail expansion data.
Do not derive trained ranks or caps from static metadata tiers.
A temporary report with no valid maximum must not erase a stored base snapshot.

`Modules/Professions/Retail.lua` adds expansion-specific knowledge, specialization, and currency details.
Its existing expansion keys remain separate from the base snapshot.
It loads before the shared profession module and guards its Retail API access through collector selection.
Window-specific cooldown and concentration modules remain separate.

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

## Saved data

DB initialization writes the selected edition to `WowEfficiencyDB.global.gameEdition` alongside the lowercase `global.region`.
These are explicit saved values, not only AceDB defaults.
AceDB owns character keys: surname-aware full names for regional-unique-name clients, and name/realm keys for Retail.
Keep edition detection separate from AceDB's client name handling.
Both editions keep the addon folder `WowEfficiency`, SavedVariables global `WowEfficiencyDB`, and file name `WowEfficiency.lua`.
The shared weekly reset clears each character's completed quest flags when due; profession data persists.

The packaged AceDB must support surname-aware names.
`.pkgmeta` selects the dependency revision; do not replace the vendored checkout by hand.
Inspect the actual packaged implementation after dependency changes.
Controlled name tuples can check storage logic but cannot prove live client names or saved files.

## Local packaging

Run from the repository root with Bash, Git, `curl`, Subversion (`svn`), `zip`, `sha256sum`, and upstream's usual Unix tools.
Dependency downloads require network access.

```bash
bash Scripts/package.sh forever
bash Scripts/package.sh retail
bash Scripts/package.sh forever /path/to/output
```

The optional second argument selects the output directory.
By default, packages go to the sibling directory `../wow-efficiency-addon-artifacts/<edition>/`, not the source tree.
Each command creates a `WowEfficiency` folder and ZIP.
The wrapper passes `-d` to disable uploads, `-l` to skip localization fetches, and `-u` for Unix line endings.
These commands do not publish a release.

The packager excludes untracked files, so add new source files to Git before packaging.
It copies tracked working-tree changes; the Git-derived ZIP version does not identify uncommitted changes.
Use the intended annotated release tag when building a local package for that release.
Do not rename a development ZIP to make it look like a tagged release.

`Scripts/packager.lock` is the single upstream version pin for local packaging and CI.
`Scripts/release.sh` fetches the pinned upstream scripts and checks their SHA-256 digests before use.
CI runs upstream setup before packaging; fetched upstream scripts stay unmodified.
Update the pin with:

```bash
bash Scripts/update-packager.sh vX.Y.Z
```

Review the resolved commit, both script digests, and upstream changes.
Then smoke-build both editions and inspect their manifests, XML paths, libraries, and exclusion of development files.

Install the produced `WowEfficiency` folder in the target client's `Interface/AddOns/` directory (`_forever_/Interface/AddOns/` for Forever).
The folder must directly contain the manifest files, not another nested addon folder.
Use `/reload` or log out to write `WTF/Account/<account>/SavedVariables/WowEfficiency.lua` under that client.
Check startup, profession data, character-name keys, region, and edition in the real client.
Forever keys must include the full surname-aware name.
Close and restart the client to check persistence.
A successful package build does not replace these live checks.

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

