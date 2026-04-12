#!/usr/bin/env python3
"""Unified env sync command for encrypt / decrypt / merge.

Compatible with the sync-config skill env backup format, but defaults to a
repo-external backup location:
  ~/.local/state/my-utils/env.rc.enc
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import hmac
import os
import re
import sys
from pathlib import Path
from typing import Dict

DEFAULT_ENV_FILE = Path.home() / ".env.rc"
DEFAULT_ENCRYPTED_FILE = Path.home() / ".local" / "state" / "my-utils" / "env.rc.enc"
EXPORT_RE = re.compile(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$")


def fail(message: str, code: int = 1) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(code)


def get_key(explicit_key: str | None) -> str:
    key = explicit_key or os.environ.get("SYNC_ENV_KEY")
    if not key:
        fail("SYNC_ENV_KEY not set and --key not provided")
    if len(key) < 16:
        fail("Encryption key must be at least 16 characters")
    return key


def hmac_sha256(key: bytes, msg: bytes) -> bytes:
    return hmac.new(key, msg, hashlib.sha256).digest()


def derive_key(password: str, salt: bytes, key_length: int = 32, iterations: int = 100000) -> bytes:
    result = b""
    block_index = 1
    password_bytes = password.encode()
    while len(result) < key_length:
        u = hmac_sha256(password_bytes, salt + block_index.to_bytes(4, "big"))
        block = u
        for _ in range(iterations - 1):
            u = hmac_sha256(password_bytes, u)
            block = bytes(a ^ b for a, b in zip(block, u))
        result += block
        block_index += 1
    return result[:key_length]


def encrypt_cbc_like(plaintext: bytes, key: bytes, iv: bytes) -> bytes:
    padding_length = 16 - (len(plaintext) % 16)
    padded = plaintext + bytes([padding_length] * padding_length)
    out = bytearray()
    for offset in range(0, len(padded), 16):
        block = padded[offset:offset + 16]
        keystream = hashlib.sha256(key + iv + offset.to_bytes(4, "big")).digest()[:16]
        out.extend(bytes(a ^ b for a, b in zip(block, keystream)))
    return bytes(out)


def decrypt_cbc_like(ciphertext: bytes, key: bytes, iv: bytes) -> bytes:
    out = bytearray()
    for offset in range(0, len(ciphertext), 16):
        block = ciphertext[offset:offset + 16]
        keystream = hashlib.sha256(key + iv + offset.to_bytes(4, "big")).digest()[:16]
        out.extend(bytes(a ^ b for a, b in zip(block, keystream)))
    return bytes(out)


def encrypt_file(input_path: Path, output_path: Path, key: str) -> None:
    if not input_path.exists():
        fail(f"Input file not found: {input_path}")
    plaintext = input_path.read_text(encoding="utf-8").encode("utf-8")
    salt = os.urandom(16)
    iv = os.urandom(16)
    derived = derive_key(key, salt)
    ciphertext = encrypt_cbc_like(plaintext, derived, iv)
    payload = base64.b64encode(salt + iv + ciphertext).decode("ascii")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(payload, encoding="utf-8")
    print(f"✅ Encrypted {input_path} → {output_path}")


def decrypt_to_text(input_path: Path, key: str) -> str:
    if not input_path.exists():
        fail(f"Input file not found: {input_path}")
    encoded = input_path.read_text(encoding="utf-8").strip()
    try:
        payload = base64.b64decode(encoded)
    except Exception as exc:
        fail(f"Failed to decode base64: {exc}")
    if len(payload) < 32:
        fail("Encrypted data too short")
    salt, iv, ciphertext = payload[:16], payload[16:32], payload[32:]
    derived = derive_key(key, salt)
    padded = decrypt_cbc_like(ciphertext, derived, iv)
    pad = padded[-1]
    if pad <= 0 or pad > 16:
        fail("Invalid padding (wrong key or corrupted data)")
    try:
        return padded[:-pad].decode("utf-8")
    except Exception as exc:
        fail(f"Failed to decode UTF-8 plaintext: {exc}")


def decrypt_file(input_path: Path, output_path: Path | None, key: str) -> None:
    plaintext = decrypt_to_text(input_path, key)
    if output_path is not None:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(plaintext, encoding="utf-8")
        print(f"✅ Decrypted {input_path} → {output_path}", file=sys.stderr)
    else:
        print(plaintext)


def parse_env_file(filepath: Path) -> Dict[str, str]:
    result: Dict[str, str] = {}
    if not filepath.exists():
        print(f"WARNING: File not found: {filepath}", file=sys.stderr)
        return result
    for raw_line in filepath.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        match = EXPORT_RE.match(line)
        if not match:
            continue
        key, value = match.group(1), match.group(2).strip()
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


def merge_command(local_file: Path, backup_file: Path, output_file: Path, dry_run: bool) -> None:
    merged, diff = merge_env(local_file, backup_file)
    print_report(diff)

    has_changes = bool(diff["added"] or diff["updated"] or diff["removed"])
    if has_changes and not dry_run:
        write_env(output_file, merged)
        print(f"\n✅ Merge complete: {len(merged)} total keys", file=sys.stderr)
    elif has_changes:
        print("\n(DRY RUN: no changes written)", file=sys.stderr)
    else:
        print("\n✅ No changes needed (local and backup are in sync)", file=sys.stderr)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Unified env sync command for encrypt / decrypt / merge")
    subparsers = parser.add_subparsers(dest="command", required=True)

    encrypt_parser = subparsers.add_parser("encrypt", help="Encrypt ~/.env.rc to an external backup file")
    encrypt_parser.add_argument("--input", default=str(DEFAULT_ENV_FILE), help="Input env file")
    encrypt_parser.add_argument("--output", default=str(DEFAULT_ENCRYPTED_FILE), help="Output encrypted file")
    encrypt_parser.add_argument("--key", default=None, help="Encryption key (default: SYNC_ENV_KEY env var)")

    decrypt_parser = subparsers.add_parser("decrypt", help="Decrypt an encrypted env backup")
    decrypt_parser.add_argument("--input", default=str(DEFAULT_ENCRYPTED_FILE), help="Input encrypted file")
    decrypt_parser.add_argument("--output", default=None, help="Output plaintext file (default: stdout)")
    decrypt_parser.add_argument("--key", default=None, help="Decryption key (default: SYNC_ENV_KEY env var)")

    merge_parser = subparsers.add_parser("merge", help="Merge local env with decrypted backup")
    merge_parser.add_argument("--local", default=str(DEFAULT_ENV_FILE), help="Local env file")
    merge_parser.add_argument("--backup", required=True, help="Backup env file (decrypted)")
    merge_parser.add_argument("--output", default=None, help="Output merged file (default: overwrite local)")
    merge_parser.add_argument("--dry-run", action="store_true", help="Show diff without writing")

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "encrypt":
        encrypt_file(Path(args.input).expanduser(), Path(args.output).expanduser(), get_key(args.key))
    elif args.command == "decrypt":
        output_path = Path(args.output).expanduser() if args.output else None
        decrypt_file(Path(args.input).expanduser(), output_path, get_key(args.key))
    elif args.command == "merge":
        local_file = Path(args.local).expanduser()
        backup_file = Path(args.backup).expanduser()
        output_file = Path(args.output).expanduser() if args.output else local_file
        merge_command(local_file, backup_file, output_file, args.dry_run)
    else:
        fail(f"Unknown command: {args.command}")


if __name__ == "__main__":
    main()
