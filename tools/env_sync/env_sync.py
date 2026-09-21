#!/usr/bin/env python3
"""env_sync — encrypt / decrypt / merge env files + privacy vault.

Single-file CLI with subcommands:

    env_sync.py encrypt  [--input FILE | --in-text TEXT | --in -] [--output FILE | --out -]
    env_sync.py decrypt  [--input FILE | --in -]                  [--output FILE | --out -]
    env_sync.py merge    --backup FILE [--local FILE] [--output FILE] [--dry-run]
    env_sync.py vault-backup   [--manifest PATH] [--force]
    env_sync.py vault-restore  [--manifest PATH] [--force] [--dry-run]

Symlink dispatch (argv[0] basename selects subcommand):
    encrypt_env  → encrypt
    decrypt_env  → decrypt
    merge_env    → merge

Crypto: AES-256-CBC + PBKDF2-HMAC-SHA256 (100k iter), salted base64.
Format is **byte-compatible** with:
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -a -pass env:SYNC_ENV_KEY

So files encrypted here can be decrypted by `openssl enc -d ...` directly,
and the Hermes sync-config skill's encrypt_env.sh produces files this tool
can decrypt. Implementation calls system `openssl` via subprocess — no Python
crypto dependency.

Key: $SYNC_ENV_KEY (≥8 chars), --key, or interactive prompt (--prompt / TTY vault-*).
"""

from __future__ import annotations

import argparse
import getpass
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, NamedTuple, Optional

# ─────────────────────────── defaults ───────────────────────────

DEFAULT_ENV_FILE = Path.home() / ".env.rc"
DEFAULT_ENCRYPTED_FILE = Path.home() / ".local" / "state" / "my-utils" / "env.rc.enc"
EXPORT_RE = re.compile(r"^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)=(.*)$")

# Repo root = tools/env_sync/../..
_REPO_ROOT = Path(__file__).resolve().parent.parent.parent
DEFAULT_VAULT_DIR = _REPO_ROOT / "privacy"
DEFAULT_MANIFEST = DEFAULT_VAULT_DIR / "manifest"

# Symlink basename → subcommand. Matched after stripping .py and trailing _env.
SYMLINK_DISPATCH = {
    "encrypt_env": "encrypt",
    "decrypt_env": "decrypt",
    "merge_env": "merge",
    "env_sync": None,  # explicit subcommand required
}


class VaultEntry(NamedTuple):
    name: str
    mode: str  # file | env-merge
    path: Path


def fail(msg: str, code: int = 1) -> "None":
    print(f"ERROR: {msg}", file=sys.stderr)
    raise SystemExit(code)


def get_key(explicit: Optional[str], *, allow_prompt: bool = False) -> str:
    key = explicit or os.environ.get("SYNC_ENV_KEY")
    if not key and allow_prompt and sys.stdin.isatty():
        key = getpass.getpass("Enter SYNC_ENV_KEY (password, ≥8 chars): ")
        if not key:
            fail("empty password")
        # Keep for subsequent openssl calls / child logic in this process
        os.environ["SYNC_ENV_KEY"] = key
    if not key:
        fail("SYNC_ENV_KEY not set and --key not provided (use --prompt on a TTY)")
    if len(key) < 8:
        fail("Encryption key must be at least 8 characters")
    return key


def _should_prompt(args) -> bool:
    return bool(getattr(args, "prompt", False) or getattr(args, "command", "") in {
        "vault-backup", "vault-restore",
    })


# ─────────────────────────── openssl crypto ───────────────────────────

def _have_openssl() -> str:
    path = shutil.which("openssl")
    if not path:
        fail("`openssl` binary not found in PATH — required for AES-256-CBC")
    return path


def encrypt_bytes(plaintext: bytes, key: str) -> bytes:
    """AES-256-CBC + PBKDF2 100k, salted base64. Returns base64-encoded ciphertext bytes.

    Uses `openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -a` via stdin/stdout.
    Key is passed via env to avoid argv leak.
    """
    openssl = _have_openssl()
    env = {**os.environ, "SYNC_ENV_KEY": key}
    res = subprocess.run(
        [openssl, "enc", "-aes-256-cbc", "-pbkdf2", "-iter", "100000",
         "-salt", "-a", "-pass", "env:SYNC_ENV_KEY"],
        input=plaintext,
        capture_output=True,
        env=env,
        check=False,
    )
    if res.returncode != 0:
        fail(f"openssl encrypt failed: {res.stderr.decode('utf-8', 'replace').strip()}")
    return res.stdout


def decrypt_bytes(ciphertext_b64: bytes, key: str) -> bytes:
    """Inverse of encrypt_bytes. Wrong key → openssl error → fail()."""
    openssl = _have_openssl()
    env = {**os.environ, "SYNC_ENV_KEY": key}
    res = subprocess.run(
        [openssl, "enc", "-d", "-aes-256-cbc", "-pbkdf2", "-iter", "100000",
         "-salt", "-a", "-pass", "env:SYNC_ENV_KEY"],
        input=ciphertext_b64,
        capture_output=True,
        env=env,
        check=False,
    )
    if res.returncode != 0:
        err = res.stderr.decode("utf-8", "replace").strip()
        fail(f"openssl decrypt failed (wrong key or corrupted data?): {err}")
    return res.stdout


# ─────────────────────────── I/O helpers ───────────────────────────

def read_input(path_or_dash: Optional[str], inline_text: Optional[str], default: Optional[Path]) -> bytes:
    """Resolve input source. Priority: inline_text > path/- > default."""
    if inline_text is not None:
        return inline_text.encode("utf-8")
    if path_or_dash == "-":
        return sys.stdin.buffer.read()
    if path_or_dash:
        p = Path(path_or_dash).expanduser()
    elif default is not None:
        p = default
    else:
        fail("no input specified")
    if not p.exists():
        fail(f"Input file not found: {p}")
    return p.read_bytes()


def write_output(data: bytes, path_or_dash: Optional[str], default: Optional[Path], *,
                 stderr_msg: Optional[str] = None) -> None:
    """Write to file, '-' (stdout), or default. Trailing newline added for text-ish output."""
    if path_or_dash == "-":
        sys.stdout.buffer.write(data)
        if not data.endswith(b"\n"):
            sys.stdout.buffer.write(b"\n")
        sys.stdout.buffer.flush()
        return
    if path_or_dash:
        p = Path(path_or_dash).expanduser()
    elif default is not None:
        p = default
    else:
        # No path given → default to stdout
        sys.stdout.buffer.write(data)
        if not data.endswith(b"\n"):
            sys.stdout.buffer.write(b"\n")
        sys.stdout.buffer.flush()
        return
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(data)
    try:
        p.chmod(0o600)
    except Exception:
        pass
    if stderr_msg:
        print(stderr_msg.format(path=p), file=sys.stderr)


# ─────────────────────────── env merge ───────────────────────────

def parse_env_file(filepath: Path) -> Dict[str, str]:
    out: Dict[str, str] = {}
    if not filepath.exists():
        print(f"WARNING: File not found: {filepath}", file=sys.stderr)
        return out
    for raw in filepath.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = EXPORT_RE.match(line)
        if not m:
            continue
        key, val = m.group(1), m.group(2).strip()
        if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
            val = val[1:-1]
        out[key] = val
    return out


def shell_quote(value: str) -> str:
    """Single-quote with embedded single-quote escape ('\\'')."""
    return "'" + value.replace("'", "'\"'\"'") + "'"


def merge_env(local: Path, backup: Path):
    le = parse_env_file(local)
    be = parse_env_file(backup)
    merged = dict(le)
    diff = {"added": {}, "updated": {}, "removed": {}, "unchanged": {}}
    for k, bv in be.items():
        if k not in le:
            merged[k] = bv
            diff["added"][k] = bv
        elif le[k] != bv:
            diff["updated"][k] = {"local": le[k], "backup": bv}
        else:
            diff["unchanged"][k] = le[k]
    for k, lv in le.items():
        if k not in be:
            diff["removed"][k] = lv
    return merged, diff


def write_env(filepath: Path, env_dict: Dict[str, str]) -> None:
    filepath.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"export {k}={shell_quote(env_dict[k])}" for k in sorted(env_dict)]
    filepath.write_text("\n".join(lines) + "\n", encoding="utf-8")
    try:
        filepath.chmod(0o600)
    except Exception:
        pass
    print(f"✅ Wrote merged env to {filepath}", file=sys.stderr)


def _mask(v: str, n: int = 20) -> str:
    return v[:n] + "..." if len(v) > n else v


def print_report(diff) -> None:
    print("\n" + "=" * 70, file=sys.stderr)
    print("ENV MERGE REPORT", file=sys.stderr)
    print("=" * 70, file=sys.stderr)
    if diff["added"]:
        print(f"\n📥 ADDED ({len(diff['added'])} keys from backup):", file=sys.stderr)
        for k, v in sorted(diff["added"].items()):
            print(f"   + {k} = {_mask(v)}", file=sys.stderr)
    if diff["updated"]:
        print(f"\n⚠️  UPDATED ({len(diff['updated'])} keys differ, keeping local):", file=sys.stderr)
        for k, vs in sorted(diff["updated"].items()):
            print(f"   ~ {k}", file=sys.stderr)
            print(f"     local:  {_mask(vs['local'], 15)}", file=sys.stderr)
            print(f"     backup: {_mask(vs['backup'], 15)}", file=sys.stderr)
    if diff["removed"]:
        print(f"\n🗑️  REMOVED ({len(diff['removed'])} keys only in local):", file=sys.stderr)
        for k in sorted(diff["removed"]):
            print(f"   - {k}", file=sys.stderr)
    if diff["unchanged"]:
        print(f"\n✅ UNCHANGED ({len(diff['unchanged'])} keys match):", file=sys.stderr)
        for k in sorted(diff["unchanged"])[:5]:
            print(f"   = {k}", file=sys.stderr)
        if len(diff["unchanged"]) > 5:
            print(f"   ... and {len(diff['unchanged']) - 5} more", file=sys.stderr)
    print("\n" + "=" * 70, file=sys.stderr)


# ─────────────────────────── subcommands ───────────────────────────

def cmd_encrypt(args) -> None:
    key = get_key(args.key, allow_prompt=_should_prompt(args))
    plaintext = read_input(args.input, args.in_text, DEFAULT_ENV_FILE if args.in_text is None and not args.input else None)
    ciphertext = encrypt_bytes(plaintext, key)

    # Default output: file → DEFAULT_ENCRYPTED_FILE; text/stdin → stdout
    explicit_default = DEFAULT_ENCRYPTED_FILE if args.in_text is None and (args.input is None or args.input != "-") else None
    if args.in_text is not None or args.input == "-":
        explicit_default = None  # stdout for inline text or stdin input

    write_output(
        ciphertext,
        args.output,
        explicit_default,
        stderr_msg="✅ Encrypted → {path}",
    )


def cmd_decrypt(args) -> None:
    key = get_key(args.key, allow_prompt=_should_prompt(args))
    # Decrypt input default: DEFAULT_ENCRYPTED_FILE only when neither --input nor --in-text given
    default_in = DEFAULT_ENCRYPTED_FILE if args.in_text is None and not args.input else None
    ciphertext_b64 = read_input(args.input, args.in_text, default_in)
    plaintext = decrypt_bytes(ciphertext_b64, key)

    # Default output: stdout (decrypted plaintext is rarely written silently)
    if args.output:
        write_output(plaintext, args.output, None, stderr_msg="✅ Decrypted → {path}")
    else:
        sys.stdout.buffer.write(plaintext)
        if not plaintext.endswith(b"\n"):
            sys.stdout.buffer.write(b"\n")
        sys.stdout.buffer.flush()


def cmd_merge(args) -> None:
    local = Path(args.local).expanduser()
    backup = Path(args.backup).expanduser()
    output = Path(args.output).expanduser() if args.output else local

    merged, diff = merge_env(local, backup)
    print_report(diff)

    has_changes = bool(diff["added"] or diff["updated"] or diff["removed"])
    if has_changes and not args.dry_run:
        write_env(output, merged)
        print(f"\n✅ Merge complete: {len(merged)} total keys", file=sys.stderr)
    elif has_changes:
        print("\n(DRY RUN: no changes written)", file=sys.stderr)
    else:
        print("\n✅ No changes needed (local and backup are in sync)", file=sys.stderr)


# ─────────────────────────── privacy vault ───────────────────────────

def load_manifest(path: Path) -> List[VaultEntry]:
    if not path.exists():
        fail(f"manifest not found: {path}")
    entries: List[VaultEntry] = []
    for lineno, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split("|")
        if len(parts) != 3:
            fail(f"{path}:{lineno}: expected name|mode|path, got: {raw!r}")
        name, mode, src = (p.strip() for p in parts)
        if not name or "/" in name or name.endswith(".enc"):
            fail(f"{path}:{lineno}: invalid name {name!r} (no path chars; omit .enc)")
        if mode not in {"file", "env-merge"}:
            fail(f"{path}:{lineno}: mode must be file|env-merge, got {mode!r}")
        entries.append(VaultEntry(name=name, mode=mode, path=Path(src).expanduser()))
    if not entries:
        fail(f"manifest has no entries: {path}")
    return entries


def enc_path_for(vault_dir: Path, name: str) -> Path:
    return vault_dir / f"{name}.enc"


def _chmod_private(path: Path) -> None:
    try:
        # Private keys and env files: owner rw only
        mode = 0o600
        name = path.name
        if name.endswith(".pub") or name == "config":
            mode = 0o644 if name.endswith(".pub") else 0o600
        path.chmod(mode)
    except OSError:
        pass


def cmd_vault_backup(args) -> None:
    key = get_key(args.key, allow_prompt=True)
    manifest = Path(args.manifest).expanduser()
    vault_dir = manifest.parent
    entries = load_manifest(manifest)
    ok = skip = 0
    print(f"Vault backup → {vault_dir}", file=sys.stderr)
    for e in entries:
        enc = enc_path_for(vault_dir, e.name)
        if not e.path.exists():
            print(f"  skip (missing source): {e.name} ← {e.path}", file=sys.stderr)
            skip += 1
            continue
        if enc.exists() and not args.force:
            # Always re-encrypt when source exists unless we want skip-unchanged;
            # default is overwrite ciphertext so git sees updates.
            pass
        plaintext = e.path.read_bytes()
        ciphertext = encrypt_bytes(plaintext, key)
        if args.dry_run:
            print(f"  dry-run encrypt: {e.path} → {enc} ({len(plaintext)} bytes)", file=sys.stderr)
            ok += 1
            continue
        enc.parent.mkdir(parents=True, exist_ok=True)
        enc.write_bytes(ciphertext if ciphertext.endswith(b"\n") else ciphertext + b"\n")
        try:
            enc.chmod(0o644)  # ciphertext is meant to be committed
        except OSError:
            pass
        print(f"  encrypted: {e.path} → {enc}", file=sys.stderr)
        ok += 1
    print(f"Done: {ok} encrypted, {skip} skipped", file=sys.stderr)
    if ok == 0:
        fail("nothing encrypted — check manifest paths")


def cmd_vault_restore(args) -> None:
    key = get_key(args.key, allow_prompt=True)
    manifest = Path(args.manifest).expanduser()
    vault_dir = manifest.parent
    entries = load_manifest(manifest)
    ok = skip = 0
    print(f"Vault restore ← {vault_dir}", file=sys.stderr)
    for e in entries:
        enc = enc_path_for(vault_dir, e.name)
        if not enc.exists():
            print(f"  skip (no ciphertext): {e.name}", file=sys.stderr)
            skip += 1
            continue
        plaintext = decrypt_bytes(enc.read_bytes(), key)
        dest = e.path

        if e.mode == "env-merge":
            with tempfile.NamedTemporaryFile(prefix="my-utils-vault-", suffix=".env", delete=False) as tmp:
                tmp_path = Path(tmp.name)
                tmp.write(plaintext)
            try:
                if args.dry_run:
                    _, diff = merge_env(dest, tmp_path)
                    print_report(diff)
                    print(f"  dry-run env-merge → {dest}", file=sys.stderr)
                    ok += 1
                    continue
                dest.parent.mkdir(parents=True, exist_ok=True)
                if not dest.exists() or not dest.read_text(encoding="utf-8").strip():
                    # Fresh machine: write backup as-is
                    backup_env = parse_env_file(tmp_path)
                    if not backup_env:
                        # Plaintext may not be KEY=VAL (skip empty)
                        dest.write_bytes(plaintext)
                        _chmod_private(dest)
                    else:
                        write_env(dest, backup_env)
                    print(f"  restored (new): {enc.name} → {dest}", file=sys.stderr)
                    ok += 1
                    continue
                merged, diff = merge_env(dest, tmp_path)
                print_report(diff)
                if diff["added"]:
                    write_env(dest, merged)
                print(f"  restored (env-merge): {enc.name} → {dest}", file=sys.stderr)
                ok += 1
            finally:
                try:
                    tmp_path.unlink()
                except OSError:
                    pass
            continue

        # mode == file
        if dest.exists() and not args.force:
            print(f"  skip (exists, use --force): {dest}", file=sys.stderr)
            skip += 1
            continue
        if args.dry_run:
            print(f"  dry-run write: {enc.name} → {dest} ({len(plaintext)} bytes)", file=sys.stderr)
            ok += 1
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(plaintext)
        _chmod_private(dest)
        print(f"  restored: {enc.name} → {dest}", file=sys.stderr)
        ok += 1
    print(f"Done: {ok} restored, {skip} skipped", file=sys.stderr)
    if ok == 0 and skip == 0:
        fail("nothing to restore")


# ─────────────────────────── argparse ───────────────────────────

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="env_sync",
        description="Encrypt / decrypt / merge env files + privacy vault. "
                    "Compatible with `openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -salt -a`.",
    )
    sub = parser.add_subparsers(dest="command")

    # encrypt
    p_enc = sub.add_parser("encrypt", help="Encrypt a file or text. Output is base64.")
    g_enc = p_enc.add_mutually_exclusive_group()
    g_enc.add_argument("--input", "-i", help=f"Input file path, or '-' for stdin (default: {DEFAULT_ENV_FILE})")
    g_enc.add_argument("--in-text", help="Inline plaintext to encrypt (don't read a file)")
    p_enc.add_argument("--output", "-o", help=f"Output path, '-' for stdout (default: {DEFAULT_ENCRYPTED_FILE} for file input; stdout for text/stdin)")
    p_enc.add_argument("--key", help="Encryption key (default: $SYNC_ENV_KEY)")
    p_enc.add_argument("--prompt", action="store_true", help="Prompt for password if SYNC_ENV_KEY unset")
    p_enc.set_defaults(func=cmd_encrypt)

    # decrypt
    p_dec = sub.add_parser("decrypt", help="Decrypt a file or text (base64 input).")
    g_dec = p_dec.add_mutually_exclusive_group()
    g_dec.add_argument("--input", "-i", help=f"Input file path, or '-' for stdin (default: {DEFAULT_ENCRYPTED_FILE})")
    g_dec.add_argument("--in-text", help="Inline base64 ciphertext to decrypt")
    p_dec.add_argument("--output", "-o", help="Output path, or '-' for stdout (default: stdout)")
    p_dec.add_argument("--key", help="Decryption key (default: $SYNC_ENV_KEY)")
    p_dec.add_argument("--prompt", action="store_true", help="Prompt for password if SYNC_ENV_KEY unset")
    p_dec.set_defaults(func=cmd_decrypt)

    # merge
    p_mrg = sub.add_parser("merge", help="Merge a local env file with a decrypted backup.")
    p_mrg.add_argument("--local", default=str(DEFAULT_ENV_FILE), help=f"Local env file (default: {DEFAULT_ENV_FILE})")
    p_mrg.add_argument("--backup", required=True, help="Decrypted backup env file")
    p_mrg.add_argument("--output", default=None, help="Output merged file (default: overwrite --local)")
    p_mrg.add_argument("--dry-run", action="store_true", help="Show diff without writing")
    p_mrg.set_defaults(func=cmd_merge)

    # vault-backup
    p_vb = sub.add_parser("vault-backup", help="Encrypt all privacy/manifest sources → privacy/*.enc")
    p_vb.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help=f"Manifest path (default: {DEFAULT_MANIFEST})")
    p_vb.add_argument("--key", help="Encryption key (default: $SYNC_ENV_KEY or prompt)")
    p_vb.add_argument("--force", action="store_true", help="Reserved (re-encrypt is always on when source exists)")
    p_vb.add_argument("--dry-run", action="store_true", help="Show actions without writing")
    p_vb.set_defaults(func=cmd_vault_backup)

    # vault-restore
    p_vr = sub.add_parser("vault-restore", help="Decrypt privacy/*.enc → home paths (prompt for password)")
    p_vr.add_argument("--manifest", default=str(DEFAULT_MANIFEST), help=f"Manifest path (default: {DEFAULT_MANIFEST})")
    p_vr.add_argument("--key", help="Decryption key (default: $SYNC_ENV_KEY or prompt)")
    p_vr.add_argument("--force", action="store_true", help="Overwrite existing destination files")
    p_vr.add_argument("--dry-run", action="store_true", help="Show actions without writing")
    p_vr.set_defaults(func=cmd_vault_restore)

    return parser


def detect_symlink_subcommand(argv0: str) -> Optional[str]:
    """Look at how we were invoked. encrypt_env → 'encrypt', etc."""
    name = Path(argv0).name
    if name.endswith(".py"):
        name = name[:-3]
    return SYMLINK_DISPATCH.get(name)


def main() -> None:
    parser = build_parser()

    # Symlink dispatch: if invoked as encrypt_env / decrypt_env / merge_env,
    # inject the subcommand at the front of argv. Allow user to override only
    # by passing one of the subcommand names explicitly. -h/--help on a symlink
    # should show the *subcommand's* help, not the top-level dispatcher's.
    forced = detect_symlink_subcommand(sys.argv[0])
    argv = sys.argv[1:]
    vault_cmds = {"encrypt", "decrypt", "merge", "vault-backup", "vault-restore"}
    if forced and (not argv or argv[0] not in vault_cmds):
        argv = [forced, *argv]

    args = parser.parse_args(argv)
    if not getattr(args, "command", None):
        parser.print_help()
        raise SystemExit(2)
    args.func(args)


if __name__ == "__main__":
    main()
