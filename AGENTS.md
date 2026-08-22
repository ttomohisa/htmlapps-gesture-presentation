# AGENTS.md — Gesture Presentation

Read this file first, then `APP_SPEC.md`, before editing the repository.

## Non-negotiable constraints

- Release two one-file variants: `dist/index.html` and `dist/index.self-extract.html`.
- Edit `src/index.template.html`; never hand-edit generated files in `dist/`.
- The viewer must open directly through `file://`; camera gesture control may require HTTPS or localhost depending on browser policy.
- No runtime CDN, API request, analytics, telemetry, external font, or hidden network dependency.
- Keep runtime CSP restrictive with `connect-src 'none'`.
- Selected documents and camera frames stay in the browser.
- Desktop and smartphone layouts are both first-class.
- Keep Japanese and English in the same HTML.
- Prefer inline SVG icons over emoji.
- Preserve keyboard focus, labels, contrast, and reduced-motion behavior.
- Dependencies must be exact-version assets declared in `dependencies.json` and embedded at build time.
- Large assets should use `compression: auto` or `gzip` and the async `StandaloneAssets` API.
- Keep each build placeholder exactly once: `__APP_CONFIG_JSON__`, `__BUILD_MANIFEST_JSON__`, `__EMBEDDED_ASSET_BUNDLE_JSON__`.

## Application architecture

All presentation actions go through `window.AirRemoteBridge.dispatch(action, source)`. Do not make gesture recognition call page rendering directly. This separation is intentional so future Air Remote transports can inject the same actions.

Source replacement is a generation boundary. Increment the source generation, cancel stale PDF rendering, release obsolete Blob URLs, and reject late results from the previous source.

Gesture start/stop is another generation boundary. Stopping must stop all MediaStream tracks and make stale inference-loop callbacks harmless.

The v1 ONNX model is BlazePalm only. It detects one palm in the square camera preview and uses palm-center motion for left/right swipes. Keep the documented single-hand limitation unless the recognition pipeline is upgraded with landmarks or gesture classification.

## Required checks

Before release on Windows:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-repository.ps1
.\build-standalone.bat
```

Then review `dist/build-size-report.json` and test both generated HTML variants with the network disabled. Test PDF, multiple images, Japanese/English, keyboard, touch, camera permission denial, repeated camera start/stop, and first/last page boundaries.

## Documentation

Keep `APP_SPEC.md`, README files, `CHANGELOG.md`, `SECURITY.md`, `THIRD_PARTY_NOTICES.md`, and the in-app `APP:HELP` section synchronized with user-visible changes.
