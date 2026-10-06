# Installation and upgrade

> **Audience:** adopter maintainers, platform engineers
> **Status:** matches `kit/` as of this edit
> **Authority:** `kit/corebase-specharness/scripts/install.sh`, `kit/manifest.json`,
> `kit/corebase-specharness/scripts/core/_lib/doctor_checks.py`,
> `kit/corebase-specharness/scripts/core/handlers/lifecycle.py` (`init`)

## Requirements

CoreBase SpecHarness installs from the `kit/` payload into a target repository. The
installed package includes the embedded Python runtime under
`corebase-specharness/scripts/core/`.

- Bash-compatible shell
- `python3` 3.10 or newer
- Local read access to the source payload
- Write access to the target for a live install

The installer lives at `kit/corebase-specharness/scripts/install.sh`. It treats
`dirname(script)/../..` as the payload root: the directory that contains
`manifest.json`. In this repository that directory is `kit/`. After a release
archive is extracted, that directory is the archive root.

```bash
bash kit/corebase-specharness/scripts/install.sh --help
bash kit/corebase-specharness/scripts/install.sh /path/to/project --dry-run
bash kit/corebase-specharness/scripts/install.sh /path/to/project
bash kit/corebase-specharness/scripts/install.sh /path/to/project --non-interactive

python3 /path/to/project/corebase-specharness/scripts/core/cli.py \
  doctor --root /path/to/project --json
```

`--non-interactive` is accepted and ignored. The installer is already
non-interactive.

Only one target is accepted. Unknown or repeated positional arguments fail. A
live install creates a missing target directory. A dry-run resolves the path
without creating it.

After install, the project is self-contained:

```bash
python3 corebase-specharness/scripts/core/cli.py <command>
```

The runtime finds the repo by walking upward from `--root` or the current
directory until it sees `corebase-specharness/scripts/core/cli.py`.

## Installer versus `init`

These are different operations. Do not treat them as aliases.

| Step | Command | What it does |
| --- | --- | --- |
| 1. Install or upgrade the kit | `bash kit/corebase-specharness/scripts/install.sh <target>` | Copies overwrite-owned files, seeds missing copy-if-missing files, chmods three scripts, runs doctor |
| 2. Scaffold missing local dirs | `python3 corebase-specharness/scripts/core/cli.py init --json` | Creates missing directories and missing seed stubs; does not overwrite existing adopter files |
| 3. Tailor the repository | `/starter-init` | Agent procedure that customizes seeded memory and proposes confirmed gates |

`init` creates these directories when absent:

- `corebase-specharness/memories/repo`
- `corebase-specharness/memories/domain`
- `corebase-specharness/project`
- `artifacts/features`

It writes a stub only when the destination does not exist:

```text
# <Title Case Stem>

[USER REVIEW NEEDED]
```

Seed stubs: `core-policies.md`, `learned-heuristics.md`,
`project-knowledge-base.md`, `adr-log.md`, `architecture.md`,
`product-sense.md`, `project-constraints.md`, `glossary.md`.

`init` does **not** add `.corezero-backup-*/` to `.gitignore`. Backup directories are
unmanaged leftovers. Adopters ignore or delete them.

`init` reports `details.onboarding_readiness`:

| Field | Source |
| --- | --- |
| `detected_stacks` | Presence of `package.json` (node), `pyproject.toml` / `requirements.txt` / `setup.py` (python), `go.mod` (go), `Cargo.toml` (rust), `pom.xml` / `build.gradle` / `build.gradle.kts` (java) |
| `portable_router` | `AGENTS.md` if present |
| `preserved_native_instruction_files` | `CLAUDE.md`, `.cursorrules`, `.windsurfrules`, `.github/copilot-instructions.md` when present |
| `confirmed_gates` | Gate names already listed in `harness-config.yaml` |
| `unknowns` | `repository stack` and/or `confirmed verification gates` when those are empty |
| `recommended_next_skill` | `/starter-init` |

The installer does not run `init` or `/starter-init`.

## Manifest ownership

`kit/manifest.json` defines exactly two file-operation groups. Entries are
string paths or glob patterns relative to both the kit root and the target.

### `files.overwrite` (kit-owned)

Back up an existing target file, then replace it with the kit copy:

```text
AGENTS.md
EXTERNAL_SKILLS.md
skills/README.md
skills/_shared/**
skills/context-memory/**
skills/harness-maintain/**
skills/harness-verify/**
skills/spec-adr/**
skills/spec-implement/**
skills/spec-plan/**
skills/spec-requirements/**
skills/spec-research/**
skills/spec-tasks/**
skills/spec-testing-scenario/**
skills/starter-init/**
corebase-specharness/references/context-routes.yaml
corebase-specharness/references/tool-providers-registry.json
corebase-specharness/scripts/core/**
corebase-specharness/scripts/install.sh
corebase-specharness/rules/**
corebase-specharness/CONTEXT_AND_MEMORY.md
corebase-specharness/project/state-machine.yaml
corebase-specharness/scripts/validate-static-audit.py
```

Local edits to those paths are replaced on upgrade, including edits to the
root `AGENTS.md`.

### `files.copyIfMissing` (adopter-owned after first copy)

Copy a matching source file only when the target path does not exist:

```text
README.md
corebase-specharness/memories/repo/core-policies.md
corebase-specharness/memories/repo/learned-heuristics.md
corebase-specharness/memories/repo/project-knowledge-base.md
corebase-specharness/memories/repo/adr-log.md
corebase-specharness/project/architecture.md
corebase-specharness/project/tech-stack.md
corebase-specharness/project/product-sense.md
corebase-specharness/project/project-constraints.md
corebase-specharness/project/glossary.md
corebase-specharness/project/harness-config.yaml
corebase-specharness/project/tool-providers.md
corebase-specharness/project/providers/**
artifacts/features/README.md
corebase-specharness/memories/domain/**
corebase-specharness/memories/archive/deprecated-heuristics.md
```

Paths outside the two groups are untouched. Feature artifacts, active
sessions, and files created outside managed patterns
stay because the installer never selects them.

The manifest validator also enforces required keys (`name`, `version`,
`requires_python`, `files`), a semantic version, only the two ownership
groups, no exact ownership overlap, existing non-glob source files, and no unmanaged leftover directories shipped in the kit payload.

## Installer sequence

`kit/corebase-specharness/scripts/install.sh` does this:

1. Parses one target plus `--dry-run`, `--non-interactive`, or help.
2. Locates the source payload (`dirname(script)/../..`) and requires
   `manifest.json`.
3. Requires `python3` 3.10 or newer.
4. Validates the manifest shape and path safety before any target mutation.
   Unsafe paths are absolute or contain `..`. Glob patterns must match at
   least one source file. Non-glob entries must be existing files.
5. Resolves the target path, creating it only for a live install.
6. Allocates `<target>/.corezero-backup-<random>/` with `mktemp` on a live
   install. Dry-run assigns `.corezero-backup-dry-run` in memory and never
   creates it.
7. Expands and copies `files.overwrite`, backing up existing destination
   files first. Existing overwrite symlinks are copied with `cp -P` then
   removed before the kit file is written.
8. Expands `files.copyIfMissing`, preserving any destination that already
   exists.
9. For a live install:
   - marks `install.sh` and `validate-static-audit.py` executable;
   - runs the installed `cli.py doctor --root <target> --json`;
   - fails the install command if doctor fails.

Copy expansion includes only regular files. It excludes `.gitkeep`, Python
cache directories (`__pycache__`) and bytecode (`.pyc`, `.pyo`), and files
whose names start with `test_`.

Doctor is `python3 corebase-specharness/scripts/core/cli.py doctor`.

## Dry-run

`--dry-run` prints planned actions without writing to the target:

- backup of existing overwrite-owned files
- overwrite copies
- preserved existing seeds
- new seed copies

Dry-run does not create the target, create a backup directory, copy or chmod
files, or run doctor.

## Backups

For a live install, existing overwrite-owned files are copied to:

```text
<target>/.corezero-backup-<random>/
```

The directory name comes from `mktemp -d "$target/.corezero-backup-XXXXXXXX"`.
It is not a timestamp. The backup preserves each repository-relative path.

The backup is created lazily. A first install into an empty target still
allocates the directory via `mktemp`, but it stays empty if nothing needed a
backup. It is not a complete repository snapshot: newly copied files,
existing adopter-owned seeds, and unrelated files are not included.

The installer does not remove old backup directories. Neither `install.sh`
nor `init` nor `/starter-init` adds `.corezero-backup-*/` to `.gitignore`.
Maintainers remain responsible for retention, ignore rules, and cleanup.

## Upgrade

Upgrade by running the current source checkout's installer against the existing
target:

```bash
bash kit/corebase-specharness/scripts/install.sh /path/to/project --dry-run
bash kit/corebase-specharness/scripts/install.sh /path/to/project
```

From an extracted release archive whose root contains `manifest.json`:

```bash
bash corebase-specharness/scripts/install.sh /path/to/project
```

Expected outcome:

1. Kit-owned overwrite files, including the embedded runtime and root
   instructions, are backed up and refreshed.
2. Existing copy-if-missing project and memory files remain unchanged,
   including `corebase-specharness/project/harness-config.yaml`. New-install context
   seed is `reserve_tokens: 1500` and profile payloads ≤ 4000; existing
   adopter config keeps its previous budget numbers.
3. New copy-if-missing files are seeded when absent.
4. Unmanaged feature artifacts, sessions, and adopter files
   remain untouched.
5. Executable permissions are restored on the three shipped scripts.
6. Installed package health is checked by doctor.
7. The installer prints an upgrade report: kit version, overwrite count,
   preserved seed count, and a reminder that harness config, memories,
   feature artifacts, and sessions are not replaced.

If the command fails during copying or doctor, the installer does not roll
back automatically. Restore replaced files from the backup when needed.
Repository version control is the rollback authority for the entire target.

## What the installer does not do

The installer does not:

- install Python, Node, provider, or project dependencies
- invoke a project package manager
- detect and write project verification gates
- configure, authenticate, index, or enable tool providers
- rewrite existing copy-if-missing configuration or memory
- create feature artifacts or active sessions
- create vendor-specific instruction files
- write Git hooks
- run `init` or `/starter-init`
- infer project commands, architecture, product rules, or domain knowledge
- add `.corezero-backup-*/` to `.gitignore`

After installation, provider selection remains in adopter-owned
`corebase-specharness/project/tool-providers.md`, and project gates remain in
`corebase-specharness/project/harness-config.yaml`.

## Post-install

From the target repository root:

```bash
python3 corebase-specharness/scripts/core/cli.py doctor --root . --json
python3 corebase-specharness/scripts/core/cli.py status --root . --json
```

Invoke `/starter-init` only when the repository has not yet been tailored.
Otherwise invoke the required peer skill directly. See [WORKFLOW.md](WORKFLOW.md).

## Troubleshooting

| Symptom | Check |
| --- | --- |
| `python3` is rejected | Run `python3 --version`; the installer requires 3.10 or newer. |
| Target was not created during preview | Expected: `--dry-run` never creates the target. |
| `corebase-specharness/scripts/core/cli.py` is missing | Review installer output and confirm the source manifest contains the overwrite-owned runtime. |
| A root instruction or skill edit was replaced | `AGENTS.md` and shipped skills are overwrite-owned. Restore from `.corezero-backup-<random>/` if needed. |
| A seed did not receive a kit update | Expected: an existing copy-if-missing file is preserved. Merge the new seed manually when desired. |
| Doctor fails during installation | Run `python3 corebase-specharness/scripts/core/cli.py doctor --root . --json` from the target and fix the reported check. |
| Provider unavailable | Install and configure the provider separately, or leave the category set to `active: none` and `mode: optional`. |
| Backup directories accumulate | Expected: the installer never deletes them and never gitignores them. |

## Related documents

- Installed paths: [ARCHITECTURE.md](ARCHITECTURE.md)
- Delivery workflow: [WORKFLOW.md](WORKFLOW.md)
- Harness behavior: [HARNESS.md](HARNESS.md)
- Command reference: [REFERENCE.md](REFERENCE.md)
- Release validation: [RELEASING.md](RELEASING.md)
