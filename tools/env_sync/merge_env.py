#!/usr/bin/env python3
"""Merge local and backup env files.

Strategy:
- keep local values
- add missing keys from backup
- never overwrite local values automatically
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Dict

EXPORT_RE = re.compile(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$")


def parse_env_file(filepath: Path) -> Dict[str, str]:
    result: Dict[str, str] = {}
    if not filepath.exists():
        print(f"WARNING: File not found: {filepath}", file=sys.stderr)
        return result
    for raw_line in filepath.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        m = EXPORT_RE.match(line)
        if not m:
            continue
        key, value = m.group(1), m.group(2).strip()
        if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
            value = value[1:-1]
        result[key] = value
    return result


def shell_quote(value: str) -> str:
    return "'" + value.replace("'", "'\"'\"'") + "'"


def merge_env(local_file: Path, backup_file: Path):
    local_env = parse_env_file(local_file)
    backup_env = parse_env_file(backup_file)
    merged = dict(local_env)
    diff = {"added": {}, "updated": {}, "removed": {}, "unchanged": {}}

    for key, backup_value in backup_env.items():
        if key not in local_env:
            merged[key] = backup_value
            diff["added"][key] = backup_value
        elif local_env[key] != backup_value:
            diff["updated"][key] = {"local": local_env[key], "backup": backup_value}
        else:
            diff["unchanged"][key] = local_env[key]

    for key, local_value in local_env.items():
        if key not in backup_env:
            diff["removed"][key] = local_value

    return merged, diff


def write_env(filepath: Path, env_dict: Dict[str, str]) -> None:
    filepath.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"export {key}={shell_quote(env_dict[key])}" for key in sorted(env_dict)]
    filepath.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"✅ Wrote merged env to {filepath}", file=sys.stderr)


def print_report(diff) -> None:
    print("\n" + "=" * 70, file=sys.stderr)
    print("ENV MERGE REPORT", file=sys.stderr)
    print("=" * 70, file=sys.stderr)

    if diff["added"]:
        print(f"\n📥 ADDED ({len(diff['added'])} keys from backup):", file=sys.stderr)
        for key, value in sorted(diff["added"].items()):
            masked = value[:20] + "..." if len(value) > 20 else value
            print(f"   + {key} = {masked}", file=sys.stderr)

    if diff["updated"]:
        print(f"\n⚠️  UPDATED ({len(diff['updated'])} keys differ, keeping local):", file=sys.stderr)
        for key, values in sorted(diff["updated"].items()):
            local_val = values['local'][:15] + "..." if len(values['local']) > 15 else values['local']
            backup_val = values['backup'][:15] + "..." if len(values['backup']) > 15 else values['backup']
            print(f"   ~ {key}", file=sys.stderr)
            print(f"     local:  {local_val}", file=sys.stderr)
            print(f"     backup: {backup_val}", file=sys.stderr)

    if diff["removed"]:
        print(f"\n🗑️  REMOVED ({len(diff['removed'])} keys only in local):", file=sys.stderr)
        for key in sorted(diff["removed"]):
            print(f"   - {key}", file=sys.stderr)

    if diff["unchanged"]:
        print(f"\n✅ UNCHANGED ({len(diff['unchanged'])} keys match):", file=sys.stderr)
        for key in sorted(diff["unchanged"])[:5]:
            print(f"   = {key}", file=sys.stderr)
        if len(diff["unchanged"]) > 5:
            print(f"   ... and {len(diff['unchanged']) - 5} more", file=sys.stderr)

    print("\n" + "=" * 70, file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(description="Merge local and backup env files")
    parser.add_argument("--local", default=str(Path.home() / ".env.rc"), help="Local env file")
    parser.add_argument("--backup", required=True, help="Backup env file (decrypted)")
    parser.add_argument("--output", default=None, help="Output merged file (default: overwrite local)")
    parser.add_argument("--dry-run", action="store_true", help="Show diff without writing")
    args = parser.parse_args()

    local_file = Path(args.local).expanduser()
    backup_file = Path(args.backup).expanduser()
    output_file = Path(args.output).expanduser() if args.output else local_file

    merged, diff = merge_env(local_file, backup_file)
    print_report(diff)

    has_changes = bool(diff["added"] or diff["updated"] or diff["removed"])
    if has_changes and not args.dry_run:
        write_env(output_file, merged)
        print(f"\n✅ Merge complete: {len(merged)} total keys", file=sys.stderr)
    elif has_changes:
        print("\n(DRY RUN: no changes written)", file=sys.stderr)
    else:
        print("\n✅ No changes needed (local and backup are in sync)", file=sys.stderr)


if __name__ == "__main__":
    main()
