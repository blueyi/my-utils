#!/usr/bin/env python3
"""Generate Cursor BYOK chatLanguageModels.json from Hermes config.yaml."""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

import yaml

DEFAULT_HERMES_CONFIG = Path.home() / ".hermes" / "config.yaml"
DEFAULT_OUTPUT = (
    Path.home() / "workspace" / "my-utils" / "cursor_bak" / "User" / "chatLanguageModels.json"
)

YUNWU_CHAT_COMPLETIONS_URL = "https://yunwu.ai/v1/chat/completions"
DEFAULT_MAX_INPUT = 256_000
DEFAULT_MAX_OUTPUT = 16_384

PROVIDER_LABELS = {
    "yunwu-claude": "Yunwu Claude",
    "yunwu-codex": "Yunwu Codex",
    "yunwu-gemini": "Yunwu Gemini",
    "yunwu-all": "Yunwu All",
}

PROVIDER_SECRET_SUFFIX = {
    "yunwu-claude": "yunwu-claude",
    "yunwu-codex": "yunwu-codex",
    "yunwu-gemini": "yunwu-gemini",
    "yunwu-all": "yunwu-all",
}


def _is_thinking_model(model_id: str) -> bool:
    lowered = model_id.lower()
    return (
        "thinking" in lowered
        or lowered.endswith("-xhigh")
        or lowered.endswith("-high")
        or lowered.endswith("-medium")
        or "reasoning" in lowered
    )


def _supports_vision(model_id: str, provider: str) -> bool:
    lowered = model_id.lower()
    if provider == "yunwu-gemini":
        return "image" in lowered or "flash" in lowered or "pro" in lowered
    if provider == "yunwu-claude":
        return True
    if provider == "yunwu-all":
        return lowered.startswith("gemini") or "image" in lowered
    return False


def _supports_tools(model_id: str) -> bool:
    lowered = model_id.lower()
    blocked = ("image", "speech", "tts", "veo")
    return not any(token in lowered for token in blocked)


def _display_name(provider: str, model_id: str) -> str:
    label = PROVIDER_LABELS.get(provider, provider)
    return f"{label} / {model_id}"


def _build_provider_entry(provider: str, provider_cfg: dict[str, Any]) -> dict[str, Any]:
    models = provider_cfg.get("models") or []
    if not models:
        default_model = provider_cfg.get("default_model") or provider_cfg.get("model")
        if default_model:
            models = [default_model]

    secret_suffix = PROVIDER_SECRET_SUFFIX.get(provider, provider.replace("_", "-"))
    entry: dict[str, Any] = {
        "name": PROVIDER_LABELS.get(provider, provider),
        "vendor": "customendpoint",
        "apiType": "chat-completions",
        "apiKey": f"${{input:chat.lm.secret.{secret_suffix}}}",
        "models": [],
    }

    for model_id in models:
        model_entry: dict[str, Any] = {
            "id": model_id,
            "name": _display_name(provider, model_id),
            "url": YUNWU_CHAT_COMPLETIONS_URL,
            "apiType": "chat-completions",
            "toolCalling": _supports_tools(model_id),
            "vision": _supports_vision(model_id, provider),
            "maxInputTokens": DEFAULT_MAX_INPUT,
            "maxOutputTokens": DEFAULT_MAX_OUTPUT,
        }
        if _is_thinking_model(model_id):
            model_entry["thinking"] = True
        entry["models"].append(model_entry)

    return entry


def generate(config_path: Path) -> list[dict[str, Any]]:
    with config_path.open(encoding="utf-8") as handle:
        config = yaml.safe_load(handle) or {}

    providers = config.get("providers") or {}
    entries: list[dict[str, Any]] = []
    for provider_name in ("yunwu-claude", "yunwu-codex", "yunwu-gemini", "yunwu-all"):
        provider_cfg = providers.get(provider_name)
        if not provider_cfg:
            continue
        entries.append(_build_provider_entry(provider_name, provider_cfg))
    return entries


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_HERMES_CONFIG,
        help=f"Hermes config path (default: {DEFAULT_HERMES_CONFIG})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT,
        help=f"Cursor chatLanguageModels.json path (default: {DEFAULT_OUTPUT})",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print JSON to stdout instead of writing a file",
    )
    args = parser.parse_args()

    payload = generate(args.config)
    rendered = json.dumps(payload, indent=2, ensure_ascii=False) + "\n"

    if args.stdout:
        print(rendered, end="")
        return

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8")
    model_count = sum(len(entry.get("models", [])) for entry in payload)
    print(f"Wrote {len(payload)} providers / {model_count} models to {args.output}")


if __name__ == "__main__":
    main()
