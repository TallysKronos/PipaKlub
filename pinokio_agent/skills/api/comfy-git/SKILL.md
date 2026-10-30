---
name: comfy-h3-local-api
description: Execute and review locally installed MiniMax H3 reference-to-video workflows through ComfyUI's HTTP API.
---

# ComfyUI H3 API

## Operations

Inspect `/queue` before submitting and preserve unrelated jobs. Inspect `/object_info` for the installed schemas and loader enum values. Upload each image with multipart POST `/upload/image`; use the returned subfolder/name in LoadImage. Submit an API graph with POST `/prompt`; retain the returned prompt ID and `node_errors`. Poll `/history/<prompt_id>`; success requires completed status and output files. Fetch output via `/view` using filename, subfolder and type from the actual history.

## Runtime inputs

Use the Pinokio-discovered ready API URL as a runtime argument. The selected H3 model filenames must match the live loader enums. A reference sheet supplies identity only; a cinematic frame supplies layout and can condition frame zero through MiniMaxH3AddGuide. Never execute partner/API nodes when local generation was requested.

## Outputs

Preserve the original native MP4, graph, seed, prompt and history. Inspect sampled frames before integrating. Transcoding to an HD preview does not make the generation native HD. The Godot runtime uses Ogg Theora/Vorbis; retain MP4 for review.

## Notes

MiniMaxH3ReferenceToVideo creates video/audio latent data; pass its latent to the sampler and decode video and audio with their matching VAEs. Length is measured in frames at 24 fps. Do not claim that reference conditioning guarantees anatomical or geometric consistency.
