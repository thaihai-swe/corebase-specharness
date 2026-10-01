#!/usr/bin/env bash
# Deterministic CoreBase SpecHarness installer
# Supports:
#   1. Remote 1-line installation:
#        curl -fsSL https://raw.githubusercontent.com/thaihai-swe/corebase-specharness/main/kit/corebase-specharness/scripts/install.sh | bash
#        curl -fsSL https://raw.githubusercontent.com/thaihai-swe/corebase-specharness/main/kit/corebase-specharness/scripts/install.sh | bash -s -- /path/to/repo
#   2. Local repository installation:
#        bash install.sh [target_dir] [--dry-run]
#   3. Automatic Python 3.10+ resolution via system Python or standalone `uv`
set -euo pipefail

err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
log() { printf '%s\n' "$*" >&2; }

target=""
dry_run=false
non_interactive=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run=true; shift ;;
    --non-interactive) shift ;;
    -h|--help) printf 'Usage: install.sh [target_dir] [--dry-run] [--non-interactive]\n'; exit 0 ;;
    *) [[ -z "$target" ]] || err "unexpected argument: $1"; target="$1"; shift ;;
  esac
done

# Default target directory to current working directory if omitted
target="${target:-.}"

# ==============================================================================
# 1. Resolve Python 3.10+ runtime (Native Python or UV bootstrap)
# ==============================================================================
find_or_provision_python() {
  # 1.1 Check native system Python binaries in PATH
  for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
        echo "$candidate"
        return 0
      fi
    fi
  done

  # 1.2 Locate existing uv binary in PATH or common paths
  local uv_bin=""
  for candidate in uv "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv" /opt/homebrew/bin/uv /usr/local/bin/uv; do
    if command -v "$candidate" >/dev/null 2>&1; then
      uv_bin="$candidate"
      break
    elif [[ -x "$candidate" ]]; then
      uv_bin="$candidate"
      break
    fi
  done

  # 1.3 If uv is found, check for or install Python >= 3.10
  if [[ -n "$uv_bin" ]]; then
    local uv_py
    uv_py="$("$uv_bin" python find ">=3.10" 2>/dev/null || true)"
    if [[ -n "$uv_py" && -x "$uv_py" ]]; then
      echo "$uv_py"
      return 0
    fi

    log "==> uv detected, installing standalone Python 3.11..."
    "$uv_bin" python install 3.11 >&2 || true
    uv_py="$("$uv_bin" python find ">=3.10" 2>/dev/null || true)"
    if [[ -n "$uv_py" && -x "$uv_py" ]]; then
      echo "$uv_py"
      return 0
    fi
  fi

  # 1.4 If neither Python >= 3.10 nor uv is found, auto-bootstrap uv via curl
  if command -v curl >/dev/null 2>&1; then
    log "==> Python 3.10+ not found on system. Bootstrapping standalone uv to provision Python 3.11..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh >&2; then
      export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
      uv_bin="$HOME/.local/bin/uv"
      [[ -x "$uv_bin" ]] || uv_bin="$HOME/.cargo/bin/uv"
      if [[ -x "$uv_bin" ]]; then
        "$uv_bin" python install 3.11 >&2 || true
        local uv_py
        uv_py="$("$uv_bin" python find ">=3.10" 2>/dev/null || true)"
        if [[ -n "$uv_py" && -x "$uv_py" ]]; then
          echo "$uv_py"
          return 0
        fi
      fi
    fi
  fi

  # 1.5 Exhausted all options: print actionable remediation
  echo "ERROR: CoreBase SpecHarness requires Python 3.10 or newer." >&2
  echo "" >&2
  echo "How to fix:" >&2
  echo "  • Install uv & Python 3.11 (fastest, standalone, no root needed):" >&2
  echo "      curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
  echo "      uv python install 3.11" >&2
  echo "  • Or install via Homebrew (macOS):" >&2
  echo "      brew install python@3.11" >&2
  echo "  • Or install via package manager (Ubuntu/Debian):" >&2
  echo "      sudo apt update && sudo apt install python3.11 python3.11-venv" >&2
  exit 1
}

PYTHON="$(find_or_provision_python)"

# ==============================================================================
# 2. Resolve source payload directory (Local checkout vs Remote GitHub download)
# ==============================================================================
REMOTE_CLEANUP_DIR=""
cleanup_temp() {
  if [[ -n "$REMOTE_CLEANUP_DIR" && -d "$REMOTE_CLEANUP_DIR" ]]; then
    rm -rf "$REMOTE_CLEANUP_DIR"
  fi
}
trap cleanup_temp EXIT INT TERM

resolve_source_dir() {
  local script_dir=""

  # Only inspect local paths if BASH_SOURCE is an actual readable file on disk
  # When executed via piped curl (curl ... | bash), BASH_SOURCE is unset and -f fails safely
  if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || echo "")"

    # Case A: Inside root of cloned repo containing kit/
    if [[ -f "$script_dir/kit/manifest.json" ]]; then
      echo "$script_dir/kit"
      return 0
    fi

    # Case B: Inside nested scripts dir: kit/corebase-specharness/scripts/
    if [[ -f "$script_dir/../../manifest.json" ]]; then
      cd "$script_dir/../.." && pwd
      return 0
    fi

    # Case C: Inside release archive extract (where manifest.json is at root)
    if [[ -f "$script_dir/manifest.json" ]]; then
      echo "$script_dir"
      return 0
    fi
  fi

  # Case D: Remote execution (curl ... | bash) -> download latest kit from GitHub
  local tmp_dir
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/corebase-specharness-XXXXXX")"
  REMOTE_CLEANUP_DIR="$tmp_dir"

  log "==> Downloading latest CoreBase SpecHarness kit payload from GitHub..."
  if command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    curl -fsSL "https://github.com/thaihai-swe/corebase-specharness/archive/refs/heads/main.tar.gz" | tar -xz -C "$tmp_dir" --strip-components=1
  elif command -v git >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/thaihai-swe/corebase-specharness.git "$tmp_dir" >/dev/null 2>&1
  else
    err "curl + tar or git is required to download CoreBase SpecHarness"
  fi

  if [[ -f "$tmp_dir/kit/manifest.json" ]]; then
    echo "$tmp_dir/kit"
  elif [[ -f "$tmp_dir/manifest.json" ]]; then
    echo "$tmp_dir"
  else
    err "manifest.json not found in downloaded kit payload"
  fi
}

source_dir="$(resolve_source_dir)"
manifest="$source_dir/manifest.json"
[[ -f "$manifest" ]] || err "manifest.json not found at $source_dir"

# ==============================================================================
# 3. Preflight: Validate manifest schema and path safety before mutation
# ==============================================================================
"$PYTHON" - "$manifest" "$source_dir" <<'PY' || err "manifest preflight failed"
import glob, json, sys
from pathlib import Path

manifest_path, source = sys.argv[1:]
try:
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    print(f"manifest is not valid JSON: {exc}", file=sys.stderr)
    raise SystemExit(1)
errors = []
for key in ("name", "version", "requires_python", "files"):
    if key not in manifest:
        errors.append(f"manifest missing required key: {key}")
files = manifest.get("files", {})
if not isinstance(files, dict):
    errors.append("manifest files must be an object")
    files = {}
unknown = set(files) - {"overwrite", "copyIfMissing"}
if unknown:
    errors.append("manifest files has unsupported keys: " + ", ".join(sorted(unknown)))
for group in ("overwrite", "copyIfMissing"):
    for item in files.get(group, []):
        if not isinstance(item, str) or not item:
            errors.append(f"manifest {group} entries must be non-empty strings")
            continue
        path = Path(item)
        if path.is_absolute() or ".." in path.parts:
            errors.append(f"manifest {group} path is unsafe: {item}")
            continue
        if any(token in item for token in "*?["):
            if not glob.glob(str(Path(source) / item), recursive=True):
                errors.append(f"manifest {group} pattern matches nothing: {item}")
        elif not (Path(source) / item).is_file():
            errors.append(f"manifest {group} source missing: {item}")
if errors:
    print("manifest validation failed:", file=sys.stderr)
    print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
    raise SystemExit(1)
PY

# Resolve canonical target directory path
if $dry_run; then
  target="$("$PYTHON" - "$target" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).expanduser().resolve())
PY
)"
else
  mkdir -p "$target"
  target="$(cd "$target" && pwd)"
fi

if $dry_run; then
  backup="$target/.corezero-backup-dry-run"
else
  backup="$(mktemp -d "$target/.corezero-backup-XXXXXXXX")" || err "failed to allocate backup directory"
fi

# ==============================================================================
# 4. Copy and Seed Functions
# ==============================================================================
copy_file() {
  local src="$1" rel="$2" mode="$3"
  local dst="$target/$rel"

  # Skip if source and destination point to the exact same physical file
  if [[ -e "$dst" && "$src" -ef "$dst" ]]; then
    return 0
  fi

  if [[ "$mode" == seed && ( -e "$dst" || -L "$dst" ) ]]; then
    log "  preserve seed: $rel"
    return 0
  fi

  if [[ -L "$dst" && "$mode" == overwrite ]]; then
    if $dry_run; then
      log "  [dry-run] backup overwrite link: $rel"
      log "  [dry-run] remove overwrite link: $rel"
    else
      mkdir -p "$(dirname "$backup/$rel")"
      cp -P "$dst" "$backup/$rel"
      rm -- "$dst"
    fi
  elif [[ -f "$dst" && "$mode" == overwrite ]]; then
    if $dry_run; then
      log "  [dry-run] backup: $rel"
    else
      mkdir -p "$(dirname "$backup/$rel")"
      cp "$dst" "$backup/$rel"
    fi
  fi

  if $dry_run; then
    log "  [dry-run] copy: $rel"
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
}

copy_group() {
  local group="$1" mode="$2"
  "$PYTHON" - "$manifest" "$group" "$source_dir" <<'PY' | while IFS= read -r rel; do
import glob, json, sys
from pathlib import Path
manifest, group, source = sys.argv[1:]
for item in json.loads(Path(manifest).read_text())['files'][group]:
    for raw in glob.glob(str(Path(source) / item), recursive=True):
        path = Path(raw)
        if path.is_file() and path.name != '.gitkeep' and '__pycache__' not in path.parts and not path.name.endswith(('.pyc', '.pyo')) and not path.name.startswith('test_'):
            print(path.relative_to(source).as_posix())
PY
    [[ -n "$rel" ]] || continue
    copy_file "$source_dir/$rel" "$rel" "$mode"
  done
}

copy_skills_to_agent() {
  [[ -d "$source_dir/skills" ]] || err "skills directory not found"
  "$PYTHON" - "$source_dir" <<'PY' | while IFS= read -r rel; do
import sys
from pathlib import Path
source = Path(sys.argv[1])
for path in (source / "skills").rglob("*"):
    if path.is_file() and path.name != ".gitkeep" and "__pycache__" not in path.parts and not path.name.endswith((".pyc", ".pyo")) and not path.name.startswith("test_"):
        print(path.relative_to(source).as_posix())
PY
    [[ -n "$rel" ]] || continue
    copy_file "$source_dir/$rel" ".agents/$rel" overwrite
  done
}

# ==============================================================================
# 5. Execute Installation & Mirroring
# ==============================================================================
manifest_version="$("$PYTHON" - "$manifest" <<'PY'
import json, sys
print(json.loads(open(sys.argv[1], encoding="utf-8").read())["version"])
PY
)"
overwrite_count="$("$PYTHON" - "$manifest" "$source_dir" <<'PY'
import glob, json, sys
from pathlib import Path
manifest, source = sys.argv[1:]
items = json.loads(Path(manifest).read_text())["files"]["overwrite"]
print(sum(1 for item in items for raw in glob.glob(str(Path(source) / item), recursive=True)
          if Path(raw).is_file() and Path(raw).name != ".gitkeep" and "__pycache__" not in Path(raw).parts
          and not Path(raw).name.endswith((".pyc", ".pyo")) and not Path(raw).name.startswith("test_")))
PY
)"
preserved_count="$("$PYTHON" - "$manifest" "$source_dir" "$target" <<'PY'
import glob, json, sys
from pathlib import Path
manifest, source, target = sys.argv[1:]
items = json.loads(Path(manifest).read_text())["files"]["copyIfMissing"]
print(sum(1 for item in items for raw in glob.glob(str(Path(source) / item), recursive=True)
          if Path(raw).is_file() and Path(raw).name != ".gitkeep" and "__pycache__" not in Path(raw).parts
          and not Path(raw).name.endswith((".pyc", ".pyo")) and not Path(raw).name.startswith("test_")
          and ((Path(target) / Path(raw).relative_to(source)).exists() or (Path(target) / Path(raw).relative_to(source)).is_symlink())))
PY
)"
agent_skill_count="$("$PYTHON" - "$source_dir" <<'PY'
import sys
from pathlib import Path
source = Path(sys.argv[1])
print(sum(1 for path in (source / "skills").rglob("*")
          if path.is_file() and path.name != ".gitkeep" and "__pycache__" not in path.parts
          and not path.name.endswith((".pyc", ".pyo")) and not path.name.startswith("test_")))
PY
)"

log "Installing CoreBase SpecHarness v$manifest_version into: $target"
copy_group overwrite overwrite
copy_group copyIfMissing seed
copy_skills_to_agent

# ==============================================================================
# 6. Postflight: Permissions & Doctor Verification
# ==============================================================================
if ! $dry_run; then
  chmod +x "$target/corebase-specharness/scripts/install.sh" "$target/corebase-specharness/scripts/validate-static-audit.py" 2>/dev/null || true
  "$PYTHON" "$target/corebase-specharness/scripts/core/cli.py" doctor --root "$target" --json >/dev/null 2>&1 || true
fi

log "Installed embedded runtime: $PYTHON corebase-specharness/scripts/core/cli.py"
log "Upgrade report: refreshed $overwrite_count kit-owned files; preserved $preserved_count adopter-owned seeds."
log "Mirrored $agent_skill_count skill files under .agents/skills."
log "harness-config.yaml, memories, feature artifacts, and sessions are not replaced."
log "Next (new/untailored repo): run /starter-init before delivery skills."
log "Next (tailored upgrade): invoke the appropriate named delivery skill directly."#!/usr/bin/env bash
# Deterministic CoreBase SpecHarness installer
# Supports:
#   1. Remote 1-line installation:
#        curl -fsSL https://raw.githubusercontent.com/thaihai-swe/corebase-specharness/main/install.sh | bash
#        curl -fsSL https://raw.githubusercontent.com/thaihai-swe/corebase-specharness/main/install.sh | bash -s -- /path/to/repo
#   2. Local repository installation:
#        bash install.sh [target_dir] [--dry-run]
#   3. Automatic Python 3.10+ resolution via system Python or standalone `uv`
set -euo pipefail

err() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
log() { printf '%s\n' "$*"; }

target=""
dry_run=false
non_interactive=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) dry_run=true; shift ;;
    --non-interactive) shift ;;
    -h|--help) printf 'Usage: install.sh [target_dir] [--dry-run] [--non-interactive]\n'; exit 0 ;;
    *) [[ -z "$target" ]] || err "unexpected argument: $1"; target="$1"; shift ;;
  esac
done

# Default target directory to current working directory if omitted
target="${target:-.}"

# ==============================================================================
# 1. Resolve Python 3.10+ runtime (Native Python or UV bootstrap)
# ==============================================================================
find_or_provision_python() {
  # 1.1 Check native system Python binaries in PATH
  for candidate in python3.14 python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
        echo "$candidate"
        return 0
      fi
    fi
  done

  # 1.2 Locate existing uv binary
  local uv_bin=""
  for candidate in uv "$HOME/.local/bin/uv" "$HOME/.cargo/bin/uv" /opt/homebrew/bin/uv /usr/local/bin/uv; do
    if command -v "$candidate" >/dev/null 2>&1; then
      uv_bin="$candidate"
      break
    elif [[ -x "$candidate" ]]; then
      uv_bin="$candidate"
      break
    fi
  done

  # 1.3 If uv is found, check for or install Python >= 3.10
  if [[ -n "$uv_bin" ]]; then
    local uv_py
    uv_py="$("$uv_bin" python find ">=3.10" 2>/dev/null || true)"
    if [[ -n "$uv_py" && -x "$uv_py" ]]; then
      echo "$uv_py"
      return 0
    fi

    log "==> uv detected, auto-installing standalone Python 3.11..."
    "$uv_bin" python install 3.11 >&2 || true
    uv_py="$("$uv_bin" python find ">=3.10" 2>/dev/null || true)"
    if [[ -n "$uv_py" && -x "$uv_py" ]]; then
      echo "$uv_py"
      return 0
    fi
  fi

  # 1.4 If neither Python >= 3.10 nor uv is found, auto-bootstrap uv via curl
  if command -v curl >/dev/null 2>&1; then
    log "==> Python 3.10+ not found on system. Bootstrapping standalone uv to provision Python 3.11..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh >&2; then
      export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
      uv_bin="$HOME/.local/bin/uv"
      [[ -x "$uv_bin" ]] || uv_bin="$HOME/.cargo/bin/uv"
      if [[ -x "$uv_bin" ]]; then
        "$uv_bin" python install 3.11 >&2 || true
        local uv_py
        uv_py="$("$uv_bin" python find ">=3.10" 2>/dev/null || true)"
        if [[ -n "$uv_py" && -x "$uv_py" ]]; then
          echo "$uv_py"
          return 0
        fi
      fi
    fi
  fi

  # 1.5 Exhausted all options: print actionable remediation
  echo "ERROR: CoreBase SpecHarness requires Python 3.10 or newer." >&2
  echo "" >&2
  echo "How to fix:" >&2
  echo "  • Install uv & Python 3.11 (fastest, standalone, no root needed):" >&2
  echo "      curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
  echo "      uv python install 3.11" >&2
  echo "  • Or install via Homebrew (macOS):" >&2
  echo "      brew install python@3.11" >&2
  echo "  • Or install via package manager (Ubuntu/Debian):" >&2
  echo "      sudo apt update && sudo apt install python3.11 python3.11-venv" >&2
  exit 1
}

PYTHON="$(find_or_provision_python)"

# ==============================================================================
# 2. Resolve source payload directory (Local checkout vs Remote GitHub download)
# ==============================================================================
REMOTE_CLEANUP_DIR=""
cleanup_temp() {
  if [[ -n "$REMOTE_CLEANUP_DIR" && -d "$REMOTE_CLEANUP_DIR" ]]; then
    rm -rf "$REMOTE_CLEANUP_DIR"
  fi
}
trap cleanup_temp EXIT INT TERM

resolve_source_dir() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"

  # Case A: Inside root of cloned repo containing kit/
  if [[ -n "$script_dir" && -f "$script_dir/kit/manifest.json" ]]; then
    echo "$script_dir/kit"
    return 0
  fi

  # Case B: Inside nested scripts dir: kit/corebase-specharness/scripts/
  if [[ -n "$script_dir" && -f "$script_dir/../../manifest.json" ]]; then
    cd "$script_dir/../.." && pwd
    return 0
  fi

  # Case C: Inside release archive extract (where manifest.json is at root)
  if [[ -n "$script_dir" && -f "$script_dir/manifest.json" ]]; then
    echo "$script_dir"
    return 0
  fi

  # Case D: Remote execution (curl ... | bash) -> download latest kit from GitHub
  local tmp_dir
  tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/corebase-specharness-XXXXXX")"
  REMOTE_CLEANUP_DIR="$tmp_dir"

  log "==> Downloading latest CoreBase SpecHarness kit payload from GitHub..."
  if command -v curl >/dev/null 2>&1 && command -v tar >/dev/null 2>&1; then
    curl -fsSL "https://github.com/thaihai-swe/corebase-specharness/archive/refs/heads/main.tar.gz" | tar -xz -C "$tmp_dir" --strip-components=1
  elif command -v git >/dev/null 2>&1; then
    git clone --depth 1 https://github.com/thaihai-swe/corebase-specharness.git "$tmp_dir" >/dev/null 2>&1
  else
    err "curl + tar or git is required to download CoreBase SpecHarness"
  fi

  if [[ -f "$tmp_dir/kit/manifest.json" ]]; then
    echo "$tmp_dir/kit"
  elif [[ -f "$tmp_dir/manifest.json" ]]; then
    echo "$tmp_dir"
  else
    err "manifest.json not found in downloaded kit payload"
  fi
}

source_dir="$(resolve_source_dir)"
manifest="$source_dir/manifest.json"
[[ -f "$manifest" ]] || err "manifest.json not found at $source_dir"

# ==============================================================================
# 3. Preflight: Validate manifest schema and path safety before mutation
# ==============================================================================
"$PYTHON" - "$manifest" "$source_dir" <<'PY' || err "manifest preflight failed"
import glob, json, sys
from pathlib import Path

manifest_path, source = sys.argv[1:]
try:
    manifest = json.loads(Path(manifest_path).read_text(encoding="utf-8"))
except (OSError, json.JSONDecodeError) as exc:
    print(f"manifest is not valid JSON: {exc}", file=sys.stderr)
    raise SystemExit(1)
errors = []
for key in ("name", "version", "requires_python", "files"):
    if key not in manifest:
        errors.append(f"manifest missing required key: {key}")
files = manifest.get("files", {})
if not isinstance(files, dict):
    errors.append("manifest files must be an object")
    files = {}
unknown = set(files) - {"overwrite", "copyIfMissing"}
if unknown:
    errors.append("manifest files has unsupported keys: " + ", ".join(sorted(unknown)))
for group in ("overwrite", "copyIfMissing"):
    for item in files.get(group, []):
        if not isinstance(item, str) or not item:
            errors.append(f"manifest {group} entries must be non-empty strings")
            continue
        path = Path(item)
        if path.is_absolute() or ".." in path.parts:
            errors.append(f"manifest {group} path is unsafe: {item}")
            continue
        if any(token in item for token in "*?["):
            if not glob.glob(str(Path(source) / item), recursive=True):
                errors.append(f"manifest {group} pattern matches nothing: {item}")
        elif not (Path(source) / item).is_file():
            errors.append(f"manifest {group} source missing: {item}")
if errors:
    print("manifest validation failed:", file=sys.stderr)
    print("\n".join(f"- {error}" for error in errors), file=sys.stderr)
    raise SystemExit(1)
PY

# Resolve canonical target directory path
if $dry_run; then
  target="$("$PYTHON" - "$target" <<'PY'
from pathlib import Path
import sys
print(Path(sys.argv[1]).expanduser().resolve())
PY
)"
else
  mkdir -p "$target"
  target="$(cd "$target" && pwd)"
fi

if $dry_run; then
  backup="$target/.corezero-backup-dry-run"
else
  backup="$(mktemp -d "$target/.corezero-backup-XXXXXXXX")" || err "failed to allocate backup directory"
fi

# ==============================================================================
# 4. Copy and Seed Functions
# ==============================================================================
copy_file() {
  local src="$1" rel="$2" mode="$3"
  local dst="$target/$rel"
  if [[ "$mode" == seed && ( -e "$dst" || -L "$dst" ) ]]; then log "  preserve seed: $rel"; return 0; fi
  if [[ -L "$dst" && "$mode" == overwrite ]]; then
    if $dry_run; then
      log "  [dry-run] backup overwrite link: $rel"
      log "  [dry-run] remove overwrite link: $rel"
    else
      mkdir -p "$(dirname "$backup/$rel")"
      cp -P "$dst" "$backup/$rel"
      rm -- "$dst"
    fi
  elif [[ -f "$dst" && "$mode" == overwrite ]]; then
    if $dry_run; then log "  [dry-run] backup: $rel"; else mkdir -p "$(dirname "$backup/$rel")"; cp "$dst" "$backup/$rel"; fi
  fi
  if $dry_run; then log "  [dry-run] copy: $rel"; else mkdir -p "$(dirname "$dst")"; cp "$src" "$dst"; fi
}

copy_group() {
  local group="$1" mode="$2"
  "$PYTHON" - "$manifest" "$group" "$source_dir" <<'PY' | while IFS= read -r rel; do
import glob, json, sys
from pathlib import Path
manifest, group, source = sys.argv[1:]
for item in json.loads(Path(manifest).read_text())['files'][group]:
    for raw in glob.glob(str(Path(source) / item), recursive=True):
        path = Path(raw)
        if path.is_file() and path.name != '.gitkeep' and '__pycache__' not in path.parts and not path.name.endswith(('.pyc', '.pyo')) and not path.name.startswith('test_'):
            print(path.relative_to(source).as_posix())
PY
    [[ -n "$rel" ]] || continue
    copy_file "$source_dir/$rel" "$rel" "$mode"
  done
}

copy_skills_to_agent() {
  [[ -d "$source_dir/skills" ]] || err "skills directory not found"
  "$PYTHON" - "$source_dir" <<'PY' | while IFS= read -r rel; do
import sys
from pathlib import Path
source = Path(sys.argv[1])
for path in (source / "skills").rglob("*"):
    if path.is_file() and path.name != ".gitkeep" and "__pycache__" not in path.parts and not path.name.endswith((".pyc", ".pyo")) and not path.name.startswith("test_"):
        print(path.relative_to(source).as_posix())
PY
    [[ -n "$rel" ]] || continue
    copy_file "$source_dir/$rel" ".agents/$rel" overwrite
  done
}

# ==============================================================================
# 5. Execute Installation & Mirroring
# ==============================================================================
manifest_version="$("$PYTHON" - "$manifest" <<'PY'
import json, sys
print(json.loads(open(sys.argv[1], encoding="utf-8").read())["version"])
PY
)"
overwrite_count="$("$PYTHON" - "$manifest" "$source_dir" <<'PY'
import glob, json, sys
from pathlib import Path
manifest, source = sys.argv[1:]
items = json.loads(Path(manifest).read_text())["files"]["overwrite"]
print(sum(1 for item in items for raw in glob.glob(str(Path(source) / item), recursive=True)
          if Path(raw).is_file() and Path(raw).name != ".gitkeep" and "__pycache__" not in Path(raw).parts
          and not Path(raw).name.endswith((".pyc", ".pyo")) and not Path(raw).name.startswith("test_")))
PY
)"
preserved_count="$("$PYTHON" - "$manifest" "$source_dir" "$target" <<'PY'
import glob, json, sys
from pathlib import Path
manifest, source, target = sys.argv[1:]
items = json.loads(Path(manifest).read_text())["files"]["copyIfMissing"]
print(sum(1 for item in items for raw in glob.glob(str(Path(source) / item), recursive=True)
          if Path(raw).is_file() and Path(raw).name != ".gitkeep" and "__pycache__" not in Path(raw).parts
          and not Path(raw).name.endswith((".pyc", ".pyo")) and not Path(raw).name.startswith("test_")
          and ((Path(target) / Path(raw).relative_to(source)).exists() or (Path(target) / Path(raw).relative_to(source)).is_symlink())))
PY
)"
agent_skill_count="$("$PYTHON" - "$source_dir" <<'PY'
import sys
from pathlib import Path
source = Path(sys.argv[1])
print(sum(1 for path in (source / "skills").rglob("*")
          if path.is_file() and path.name != ".gitkeep" and "__pycache__" not in path.parts
          and not path.name.endswith((".pyc", ".pyo")) and not path.name.startswith("test_")))
PY
)"

log "Installing CoreBase SpecHarness v$manifest_version into: $target"
copy_group overwrite overwrite
copy_group copyIfMissing seed
copy_skills_to_agent

# ==============================================================================
# 6. Postflight: Permissions & Doctor Verification
# ==============================================================================
if ! $dry_run; then
  chmod +x "$target/corebase-specharness/scripts/install.sh" "$target/corebase-specharness/scripts/validate-static-audit.py"
  "$PYTHON" "$target/corebase-specharness/scripts/core/cli.py" doctor --root "$target" --json >/dev/null
fi

log "Installed embedded runtime: $PYTHON corebase-specharness/scripts/core/cli.py"
log "Upgrade report: refreshed $overwrite_count kit-owned files; preserved $preserved_count adopter-owned seeds."
log "Mirrored $agent_skill_count skill files under .agents/skills."
log "harness-config.yaml, memories, feature artifacts, and sessions are not replaced."
log "Next (new/untailored repo): run /starter-init before delivery skills."
log "Next (tailored upgrade): invoke the appropriate named delivery skill directly."
