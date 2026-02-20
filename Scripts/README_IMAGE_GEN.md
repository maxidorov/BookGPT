# OpenRouter Image Asset Generator

## Setup
1. Copy `Scripts/.openrouter.env.example` to `Scripts/.openrouter.env`.
2. Put your real `OPENROUTER_API_KEY` into `Scripts/.openrouter.env`.

## Generate asset
```bash
python3 Scripts/generate_openrouter_asset.py \
  --prompt "Cinematic portrait of Sherlock Holmes in Victorian London" \
  --asset-name SherlockPortrait \
  --model openai/gpt-5-image
```

Default output location is `BookGPT/Assets.xcassets/<AssetName>.imageset`.

## Use in SwiftUI
```swift
Image("SherlockPortrait")
```

## Notes
- Default endpoint is `https://openrouter.ai/api/v1/chat/completions`.
- Use an image-capable model (for example `openai/gpt-5-image`).
- You can override model/endpoint via flags.

## Discover available models
```bash
python3 Scripts/generate_openrouter_asset.py --list-image-models --prompt x --asset-name x
```
(`--prompt` and `--asset-name` are currently required by CLI parser.)
