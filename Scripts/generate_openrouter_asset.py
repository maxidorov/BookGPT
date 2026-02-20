#!/usr/bin/env python3
"""Generate image assets via OpenRouter and add them to Xcode asset catalog.

Usage example:
  python3 Scripts/generate_openrouter_asset.py \
    --prompt "Cinematic portrait of Sherlock Holmes in Victorian London" \
    --asset-name SherlockPortrait

The script reads `OPENROUTER_API_KEY` from `Scripts/.openrouter.env` by default.
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import pathlib
import sys
import re
import urllib.error
import urllib.request
from typing import Any, Dict


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate OpenRouter image and save as Xcode image set")
    parser.add_argument("--list-image-models", action="store_true", help="List image-capable model IDs from OpenRouter and exit")
    parser.add_argument("--prompt", required=True, help="Prompt for image generation")
    parser.add_argument("--asset-name", required=True, help="Name of .imageset in Assets.xcassets")
    parser.add_argument("--model", default="openai/gpt-5-image", help="OpenRouter model id")
    parser.add_argument("--aspect-ratio", default="1:1", help="Image aspect ratio (e.g. 1:1, 16:9)")
    parser.add_argument("--image-size", default="1K", help="Image size tier (1K, 2K, 4K)")
    parser.add_argument("--include-text", action="store_true", help="Request both image and text modalities")
    parser.add_argument("--config", default="Scripts/.openrouter.env", help="Path to env file with OPENROUTER_API_KEY")
    parser.add_argument("--catalog", default="BookGPT/Assets.xcassets", help="Path to asset catalog")
    parser.add_argument("--endpoint", default="https://openrouter.ai/api/v1/chat/completions", help="OpenRouter chat completions endpoint")
    parser.add_argument("--app-url", default="https://bookgpt.local", help="HTTP-Referer header value")
    parser.add_argument("--app-name", default="BookGPT", help="X-Title header value")
    return parser.parse_args()


def load_env_file(path: pathlib.Path) -> Dict[str, str]:
    values: Dict[str, str] = {}
    if not path.exists():
        return values

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def load_api_key(config_path: pathlib.Path) -> str:
    env_values = load_env_file(config_path)
    if "OPENROUTER_API_KEY" in env_values and env_values["OPENROUTER_API_KEY"]:
        return env_values["OPENROUTER_API_KEY"]

    if os.environ.get("OPENROUTER_API_KEY"):
        return os.environ["OPENROUTER_API_KEY"]

    raise RuntimeError(
        "OPENROUTER_API_KEY not found. Add it to %s or export as environment variable." % config_path
    )


def post_json(url: str, payload: Dict[str, Any], headers: Dict[str, str]) -> Dict[str, Any]:
    encoded = json.dumps(payload).encode("utf-8")
    request = urllib.request.Request(url=url, data=encoded, method="POST")
    for key, value in headers.items():
        request.add_header(key, value)

    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            body = response.read().decode("utf-8")
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"OpenRouter HTTP {error.code}: {detail}") from error
    except urllib.error.URLError as error:
        raise RuntimeError(f"OpenRouter request failed: {error}") from error

    try:
        return json.loads(body)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"Invalid JSON response from OpenRouter: {body[:500]}") from error


def download_binary(url: str) -> bytes:
    request = urllib.request.Request(url=url, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=120) as response:
            return response.read()
    except urllib.error.URLError as error:
        raise RuntimeError(f"Image download failed: {error}") from error


def get_image_models(api_key: str, app_url: str, app_name: str) -> list[str]:
    req = urllib.request.Request("https://openrouter.ai/api/v1/models", method="GET")
    req.add_header("Authorization", f"Bearer {api_key}")
    req.add_header("HTTP-Referer", app_url)
    req.add_header("X-Title", app_name)

    with urllib.request.urlopen(req, timeout=120) as response:
        payload = json.loads(response.read().decode("utf-8"))

    result: list[str] = []
    for item in payload.get("data", []):
        if not isinstance(item, dict):
            continue
        model_id = str(item.get("id", "")).strip()
        arch = item.get("architecture") if isinstance(item.get("architecture"), dict) else {}
        in_mods = arch.get("input_modalities") if isinstance(arch.get("input_modalities"), list) else []
        out_mods = arch.get("output_modalities") if isinstance(arch.get("output_modalities"), list) else []
        modalities = {str(x).lower() for x in (in_mods + out_mods)}
        if "image" in modalities:
            result.append(model_id)

    return sorted(set(result))


def generation_model_candidates(model_ids: list[str]) -> list[str]:
    preferred = []
    for model_id in model_ids:
        lowered = model_id.lower()
        if "gpt-5-image" in lowered or "flash-image" in lowered or "pro-image" in lowered:
            preferred.append(model_id)
    if preferred:
        return preferred
    return model_ids


def decode_data_url(data_url: str) -> bytes:
    match = re.match(r"^data:image/[^;]+;base64,(.+)$", data_url)
    if not match:
        raise RuntimeError("Unsupported image data URL format.")
    return base64.b64decode(match.group(1))


def extract_image_bytes(payload: Dict[str, Any]) -> bytes:
    choices = payload.get("choices")
    if not isinstance(choices, list) or not choices:
        raise RuntimeError(f"OpenRouter response missing choices: {payload}")

    message = choices[0].get("message") if isinstance(choices[0], dict) else None
    if not isinstance(message, dict):
        raise RuntimeError(f"OpenRouter response missing message payload: {payload}")

    images = message.get("images")
    if not isinstance(images, list) or not images:
        raise RuntimeError(f"OpenRouter response missing generated images: {payload}")

    first = images[0]
    if not isinstance(first, dict):
        raise RuntimeError(f"Unexpected image payload structure: {payload}")

    image_url_obj = first.get("image_url")
    if isinstance(image_url_obj, dict) and image_url_obj.get("url"):
        url_value = str(image_url_obj["url"])
        if url_value.startswith("data:image/"):
            return decode_data_url(url_value)
        return download_binary(url_value)

    if first.get("url"):
        return download_binary(str(first["url"]))

    raise RuntimeError(f"Could not extract image URL from response: {payload}")


def make_imageset(catalog_path: pathlib.Path, asset_name: str, image_bytes: bytes) -> pathlib.Path:
    asset_dir = catalog_path / f"{asset_name}.imageset"
    asset_dir.mkdir(parents=True, exist_ok=True)

    filenames = [f"{asset_name}@1x.png", f"{asset_name}@2x.png", f"{asset_name}@3x.png"]
    for filename in filenames:
        (asset_dir / filename).write_bytes(image_bytes)

    contents = {
        "images": [
            {"idiom": "universal", "filename": filenames[0], "scale": "1x"},
            {"idiom": "universal", "filename": filenames[1], "scale": "2x"},
            {"idiom": "universal", "filename": filenames[2], "scale": "3x"},
        ],
        "info": {"version": 1, "author": "xcode"},
    }

    (asset_dir / "Contents.json").write_text(json.dumps(contents, indent=2) + "\n", encoding="utf-8")
    return asset_dir


def main() -> int:
    args = parse_args()

    config_path = pathlib.Path(args.config)
    catalog_path = pathlib.Path(args.catalog)

    if not catalog_path.exists():
        print(f"Asset catalog not found: {catalog_path}", file=sys.stderr)
        return 1

    try:
        api_key = load_api_key(config_path)
    except RuntimeError as error:
        print(str(error), file=sys.stderr)
        return 1

    modalities = ["image", "text"] if args.include_text else ["image"]
    if args.list_image_models:
        try:
            models = get_image_models(api_key, args.app_url, args.app_name)
        except Exception as error:
            print(f"Failed to fetch models: {error}", file=sys.stderr)
            return 1
        if not models:
            print("No image-capable models found for this key.")
            return 0
        print("Image-capable models:")
        for model_id in generation_model_candidates(models):
            print(model_id)
        return 0

    payload = {
        "model": args.model,
        "messages": [{"role": "user", "content": args.prompt}],
        "modalities": modalities,
        "stream": False,
        "image_config": {
            "aspect_ratio": args.aspect_ratio,
            "image_size": args.image_size,
        },
    }

    headers = {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": args.app_url,
        "X-Title": args.app_name,
    }

    try:
        response = post_json(args.endpoint, payload, headers)
        image_bytes = extract_image_bytes(response)
        imageset_path = make_imageset(catalog_path, args.asset_name, image_bytes)
    except RuntimeError as error:
        message = str(error)
        if "not a valid model ID" in message:
            try:
                models = generation_model_candidates(get_image_models(api_key, args.app_url, args.app_name))
                suggested = ", ".join(models[:8])
                message += f"\\nTry one of these image models: {suggested}"
            except Exception:
                pass
        print(message, file=sys.stderr)
        return 1

    print(f"Created image set: {imageset_path}")
    print(f"Use in SwiftUI: Image(\"{args.asset_name}\")")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
