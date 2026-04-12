#!/usr/bin/env python3
"""Encrypt ~/.env.rc to an external backup path.

Compatible with the sync-config env.rc.enc format:
- payload = base64(salt[16] + iv[16] + ciphertext)
- key derivation = PBKDF2-HMAC-SHA256, 100k iterations, 32-byte key
- cipher core = same stream-XOR scheme used by sync-config scripts

Default output is intentionally OUTSIDE the git repo:
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

DEFAULT_OUTPUT = Path.home() / ".local" / "state" / "my-utils" / "env.rc.enc"


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


def encrypt_file(input_path: Path, output_path: Path, key: str) -> None:
    plaintext = input_path.read_text(encoding="utf-8").encode("utf-8")
    salt = os.urandom(16)
    iv = os.urandom(16)
    derived = derive_key(key, salt)
    ciphertext = encrypt_cbc_like(plaintext, derived, iv)
    payload = base64.b64encode(salt + iv + ciphertext).decode("ascii")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(payload, encoding="utf-8")
    print(f"✅ Encrypted {input_path} → {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Encrypt ~/.env.rc to an external backup path")
    parser.add_argument("--input", default=str(Path.home() / ".env.rc"), help="Input env file")
    parser.add_argument("--output", default=str(DEFAULT_OUTPUT), help="Output encrypted file")
    parser.add_argument("--key", default=None, help="Encryption key (default: SYNC_ENV_KEY env var)")
    args = parser.parse_args()

    key = args.key or os.environ.get("SYNC_ENV_KEY")
    if not key:
        print("ERROR: SYNC_ENV_KEY not set and --key not provided", file=sys.stderr)
        raise SystemExit(1)
    if len(key) < 16:
        print("ERROR: Encryption key must be at least 16 characters", file=sys.stderr)
        raise SystemExit(1)

    input_path = Path(args.input).expanduser()
    output_path = Path(args.output).expanduser()
    if not input_path.exists():
        print(f"ERROR: Input file not found: {input_path}", file=sys.stderr)
        raise SystemExit(1)

    encrypt_file(input_path, output_path, key)


if __name__ == "__main__":
    main()
