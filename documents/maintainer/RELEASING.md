# Release process

> **Audience:** kit maintainers
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/manifest.json`, `.github/workflows/`,
> `kit/corebase-specharness/scripts/install.sh`

## Version and payload authority

| Item | Authoritative source |
| --- | --- |
| Package version | `kit/manifest.json` → `version` |
| Release tag | `v<semver>` matching the manifest version |
| Installed payload and ownership | `kit/manifest.json` |
| Installation behavior | `kit/corebase-specharness/scripts/install.sh` |
| Embedded CLI behavior | `kit/corebase-specharness/scripts/core/` |

The current release payload is an embedded, project-local kit. A project
installation contains `corebase-specharness/scripts/core/**`.

## Commit conventions

Prefer Conventional Commits. `.github/workflows/auto-bump.yml` inspects the
merge commit on `main` and derives the bump:

| Commit signal | Release effect |
| --- | --- |
| `major:` prefix, `feat!` / `fix!` / `refactor!` / `perf!` / `chore!:`, or body `BREAKING CHANGE:` | major bump |
| `minor:`, `feature:`, or `feat:` | minor bump |
| `patch:`, `fix:`, `perf:`, or `revert:` | patch bump |
| `chore:` / `docs:` / `refactor:` without `!` | no release bump |
| commit starts with `release:` | skipped (the workflow's own bot commit) |
| commit contains `[skip release]` | skipped |

The workflow then updates `kit/manifest.json` `version`, commits
`release: vX.Y.Z [skip ci]`, tags `vX.Y.Z`, pushes `main` and the tag, and
maintains `release/<major>.<minor>.x`:

- major or minor bump: create or update the branch at this commit
- patch bump: fast-forward the existing branch; skip the branch update if
  that line does not exist

Tag publication must not create a GitHub Release unless CI succeeds for that
tag. `release.yml` runs the CI workflow first.

To bypass auto-release, use `[skip release]` or a non-release prefix.

## Pre-release validation

```bash
python3 -m compileall -q kit/corebase-specharness/scripts/core
python3 kit/corebase-specharness/scripts/validate-static-audit.py --root kit
python3 kit/corebase-specharness/scripts/core/cli.py doctor --root kit --json
bash kit/corebase-specharness/scripts/install.sh /tmp/corebase-specharness-release-check --dry-run
bash kit/corebase-specharness/scripts/install.sh /tmp/corebase-specharness-release-live
cd /tmp/corebase-specharness-release-live && python3 corebase-specharness/scripts/core/cli.py doctor --json
```

`.github/workflows/ci.yml` `validate` job, in order:

1. `python3 -m compileall -q kit/corebase-specharness/scripts/core`
2. `validate-static-audit.py --root kit`
3. `cli.py doctor --root kit --json`
4. Live install smoke into `mktemp -d`:
   - installer `--dry-run` then live install
   - installed `doctor`
   - installed `context-load --skill starter-init --intent bootstrap`
   - installed `provider-list`, `provider-check`, and
     `provider-run --category code-intelligence`
   - installed static-audit validator
   - negative checks: `context-index` and `task-next` must not exist

Required outcomes:

- doctor, compile, static audit, dry-run, and live-install
  checks pass
- the target contains `corebase-specharness/scripts/core/cli.py`
- doctor runs clean from the target
- manifest ownership preserves adopter artifacts and repository memory across
  upgrades
- shipped skill paths remain flat and do not contain source-checkout path
  prefixes
- removed commands `context-index` and `task-next` stay gone

## Release flow

```text
change lands on main
  -> CI validates the kit and isolated project installation
  -> auto-bump updates kit/manifest.json when commit type requires it
  -> tag vX.Y.Z is created
  -> release workflow re-runs CI on the tagged commit
  -> on success: GitHub Release publishes the kit archive
  -> Pages workflow publishes documentation
```

`release.yml` also verifies that the tag `vX.Y.Z` matches
`kit/manifest.json` `version` before packaging.

## Release asset

`release.yml` packages the contents of `kit/` into
`corebase-specharness-kit-vX.Y.Z.tar.gz`:

```bash
tar -czf "$asset" --exclude='__pycache__' --exclude='*.pyc' --exclude='.DS_Store' -C kit .
```

The archive root is kit contents (`manifest.json` at the top), not a `kit/`
wrapper directory. The workflow asserts that the archive contains
`corebase-specharness/scripts/core/cli.py` and `manifest.json`, then extracts the exact
asset, runs `bash corebase-specharness/scripts/install.sh` from that extraction into a
clean target, and runs installed `doctor`.

```text
corebase-specharness-kit-vX.Y.Z.tar.gz
  manifest.json
  README.md
  AGENTS.md
  EXTERNAL_SKILLS.md
  skills/
  references/
  corebase-specharness/scripts/core/
  corebase-specharness/scripts/install.sh
  corebase-specharness/scripts/validate-*.py
  corebase-specharness/project/
  corebase-specharness/rules/
  corebase-specharness/memories/
```

Adopter install from the extracted archive:

```bash
bash corebase-specharness/scripts/install.sh /path/to/project
cd /path/to/project
python3 corebase-specharness/scripts/core/cli.py doctor
```

The installed project contains the local runtime. No global engine,
`COREBASE_SPECHARNESS_ENGINE_DIR`, PATH setup, or `bin/corebase-specharness` launcher is used.

## Adopter upgrade contract

An adopter upgrades by obtaining the desired kit source or release archive and
running its installer against the project:

```bash
bash corebase-specharness/scripts/install.sh /path/to/adopter/repo
```

The installer refreshes overwrite-managed payload files, keeps existing
copy-if-missing files, preserves unmanaged adopter files, and runs doctor.

## Rollback guidance

1. Restore replaced files from `.corezero-backup-<random>/`.
2. Retain artifacts and repository memory unless the adopter explicitly
   chooses otherwise.
3. Re-run a dry-run and doctor against a temporary target before retrying the
   upgrade.

The installer does not roll back automatically. Repository version control is
the rollback authority for the entire target.

## Pages publication

`.github/workflows/pages.yml` publishes presentation output on push to
`main`:

| Source | Site path |
| --- | --- |
| `kit/corebase-specharness/*` | `_site/adopters/` |
| `kit/README.md` | `_site/adopters/README.md` |
| `product-page/index.html` | `_site/index.html` |
| `documents/diagrams` | `_site/documents/diagrams` |
| `documents/INDEX.md` | `_site/maintainers/README.md` |
| `documents/maintainer/SKILLS.md` | `_site/maintainers/skills.md` |
| `documents/maintainer/` | `_site/maintainers/maintainer/` |

Pages is presentation, not authority. Repository files named in the
authority table remain canonical.

## Related documents

- Install guide: [INSTALL.md](INSTALL.md)
- Installed architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Documentation authority: [../INDEX.md](../INDEX.md)
