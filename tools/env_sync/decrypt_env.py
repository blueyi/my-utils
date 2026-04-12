#!/usr/bin/env python3
"""Decrypt an env.rc.enc backup created by my-utils or sync-config.

Default input is intentionally OUTSIDE the git repo:
  ~/.local/state/my-utils/env.rc.enc
"""

from __future__ import annotations

import argparse
import base64
import hashlib
import hmac
import os
import sys
from pathlib import Path

DEFAULT_INPUT = Path.home() / ".local" / "state" / "my-utils" / "env.rc.enc"


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


def decrypt_cbc_like(ciphertext: bytes, key: bytes, iv: bytes) -> bytes:
    out = bytearray()
    for offset in range(0, len(ciphertext), 16):
        block = ciphertext[offset:offset + 16]
        keystream = hashlib.sha256(key + iv + offset.to_bytes(4, "big")).digest()[:16]
        out.extend(bytes(a ^ b for a, b in zip(block, keystream)))
    return bytes(out)


def decrypt_file(input_path: Path, output_path: Path | None, key: str) -> str:
    encoded = input_path.read_text(encoding="utf-8").strip()
    payload = base64.b64decode(encoded)
    if len(payload) < 32:
        print("ERROR: Encrypted data too short", file=sys.stderr)
        raise SystemExit(1)
    salt, iv, ciphertext = payload[:16], payload[16:32], payload[32:]
    derived = derive_key(key, salt)
    padded = decrypt_cbc_like(ciphertext, derived, iv)
    pad = padded[-1]
    if pad <= 0 or pad > 16:
        print("ERROR: Invalid padding (wrong key or corrupted data)", file=sys.stderr)
        raise SystemExit(1)
    plaintext = padded[:-pad].decode("utf-8")
    if output_path is not None:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        output_path.write_text(plaintext, encoding="utf-8")
        print(f"✅ Decrypted {input_path} → {output_path}", file=sys.stderr)
    return plaintext


def main() -> None:
    parser = argparse.ArgumentParser(description="Decrypt env.rc.enc backup")
    parser.add_argument("--input", default=str(DEFAULT_INPUT), help="Input encrypted file")
    parser.add_argument("--output", default=None, help="Output plaintext file (default: stdout)")
    parser.add_argument("--key", default=None, help="Decryption key (default: SYNC_ENV_KEY env var)")
    args = parser.parse_args()

    key = args.key or os.environ.get("SYNC_ENV_KEY")
    if not key:
        print("ERROR: SYNC_ENV_KEY not set and --key not provided", file=sys.stderr)
        raise SystemExit(1)
    if len(key) < 16:
        print("ERROR: Decryption key must be at least 16 characters", file=sys.stderr)
        raise SystemExit(1)

    input_path = Path(args.input).expanduser()
    if not input_path.exists():
        print(f"ERROR: Input file not found: {input_path}", file=sys.stderr)
        raise SystemExit(1)

    output_path = Path(args.output).expanduser() if args.output else None
    plaintext = decrypt_file(input_path, output_path, key)
    if output_path is None:
        print(plaintext)


if __name__ == "__main__":
    main()
