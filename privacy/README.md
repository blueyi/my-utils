# Privacy vault

Password-encrypted backups of machine-local secrets. Ciphertext (`*.enc`) is safe to commit to this repo; the password (`SYNC_ENV_KEY`) is **never** stored here.

## Workflow

**Old machine (backup → git → GitHub):**

```bash
./myu vault backup          # prompts for SYNC_ENV_KEY (≥8 chars)
git add privacy/*.enc privacy/manifest
git commit -m "Update privacy vault"
git push
```

**Single file:**

```bash
./myu vault encrypt -i ~/path/to/secret -o privacy/name.enc
./myu vault decrypt -i privacy/name.enc -o ~/path/to/secret
./myu vault decrypt -i privacy/name.enc    # print to terminal
```

**New machine (clone → restore):**

```bash
./myu setup --new-mac --yes   # includes vault restore at the end
# or only secrets:
./myu vault restore
./myu vault restore --force   # overwrite existing files
```

## Manifest

Edit [`manifest`](manifest) to add/remove files. Each line is `name|mode|path`.

Crypto: OpenSSL AES-256-CBC + PBKDF2 (same as `env_sync encrypt` / Hermes sync-config).
