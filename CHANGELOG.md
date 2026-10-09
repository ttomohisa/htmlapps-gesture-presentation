# Changelog

## 1.3.4 - 2026-10-09

- Add the canonical favicon using the existing embedded icon without changing its design.
- Add Japanese and English screenshots for the app catalog and documentation.
- Regenerate the stale v1.3.0 root distribution from the already committed v1.3.3 source, including its existing Air Remote split-QR, scanner lifecycle, ICE diagnostics, and WebRTC CSP fixes.

## 1.3.3 - 2026-08-23

- Fixed the first split Answer QR being misclassified because its `AR1G.` prefix contains a dot.
- Split QR parsing now accepts the complete encoded payload alphabet while preserving checksum validation.

## 1.3.2 - 2026-08-23

- Split large phone Answer payloads into coarse QR parts automatically (typically 2–4).
- Enlarge the phone Answer QR and add Previous / Next part navigation.
- Let the PC scanner collect QR parts in any order, ignore duplicates, verify a whole-payload checksum, and apply the Answer automatically when complete.
- Increase QR scan analysis resolution and try both normal/inverted decoding while preserving the existing camera-stream reuse path.
- Keep the raw Answer code as a manual fallback and preserve legacy single-QR Answer compatibility.

## 1.3.1 - 2026-08-22

- Wait up to 15 seconds for ICE candidate gathering and reject empty candidate payloads.
- Add ICE candidate counts and connection diagnostics on both PC and smartphone.
- Pre-pool host candidates for more reliable serverless LAN pairing.
- Explicitly allow WebRTC in CSP-capable browsers while keeping runtime network fetch disabled.


## 1.3.0 - 2026-08-21

### Added

- Added complete two-QR Air Remote pairing with no signaling server, STUN, or TURN.
- Added PC offer QR generation using embedded `qrcode-generator` 2.0.4.
- Added a dedicated smartphone Remote screen that opens directly from the first QR on HTTP(S).
- Added phone answer QR generation and PC camera scanning using embedded `jsqr` 1.4.0.
- Added phone controls for Previous / Next, gesture lock, black / white screen, and timer actions.
- Added synchronized phone display for page number, timer, blank-screen mode, and gesture-lock state.
- Kept manual Offer/Answer text exchange as a fallback for camera-restricted environments.

### Changed

- Air Remote is now a usable local pairing flow instead of only a host-side transport foundation.
- The first QR uses a URL fragment when served over HTTP(S), so signaling data is not sent to the web server.

## 1.2.0 - 2026-08-21

### Added

- Added a presentation countdown timer with 5 / 10 / 15 minute presets, custom 1–180 minute duration, pause/resume, reset, and fullscreen HUD display.
- Added black-screen and white-screen presentation blanking with toolbar controls, fullscreen HUD controls, click-to-restore, and `B` / `W` shortcuts.
- Added `T` to start/pause the timer.
- Added `blackout`, `whiteout`, `clear-screen`, `timer-toggle`, and `timer-reset` actions to `AirRemoteBridge`.
- Added the PC-side fully local Air Remote foundation using `RTCPeerConnection({ iceServers: [] })` and an `air-remote` DataChannel.
- Added manual gzip/base64url Offer/Answer exchange UI as the transport layer that the next QR-pairing phase will encode and scan.
- Added compact state snapshots for future phone remotes: page, total pages, gesture state, blank-screen mode, and timer state.

### Changed

- The desktop side rail now groups Gesture Control and Presentation Tools.
- Privacy/help copy now distinguishes normal offline use from optional direct WebRTC Air Remote traffic.

## 1.1.0 - 2026-08-21

### Added

- Added three gesture sensitivity levels: Low, Standard, and High. The selected level is stored locally.
- Added gesture lock so hand recognition can keep running while gesture-driven page turns are temporarily disabled.
- Added lock controls to desktop, smartphone bottom navigation, and fullscreen presentation controls.
- Added a compact fullscreen presentation HUD with Previous / page count / Gesture / Lock / Next / Exit controls.
- Added a small fullscreen gesture status pill for stopped, active, and locked states.
- Added a camera-preview collapse control that does not stop recognition.
- Added `L` for gesture lock and `F` for fullscreen keyboard shortcuts.
- Added `gesture-lock` to `AirRemoteBridge` for future Air Remote transports.

### Changed

- Fullscreen PDF pages are re-rendered to fit the actual fullscreen stage.
- Smartphone bottom navigation now provides Previous / Gesture / Lock / Next.
- Gesture status feedback differentiates active and locked states.

## 1.0.2 - 2026-08-21

### Fixed

- Snapshot selected files before clearing the file input, fixing PDF loading where the live `FileList` became empty after the asynchronous PDF.js runtime initialization.
- Snapshot drag-and-drop files as well so asynchronous source replacement never depends on a live browser file list.

## 1.0.1 - 2026-08-21

### Fixed
- PDF loading now preloads the embedded PDF.js worker on the main thread, avoiding Blob Worker startup failures under `file://` and restrictive CSP.
- PDF.js evaluation shortcuts are disabled with `isEvalSupported: false` to remain compatible with the app CSP.
- ONNX Runtime now uses the bundled ESM runtime (`ort.wasm.bundle.min.mjs`) plus an embedded WASM binary, removing the fragile classic-script → secondary-MJS loading path.
- CSP now permits WebAssembly compilation via `'wasm-unsafe-eval'` without enabling general JavaScript `'unsafe-eval'`.

## 1.0.0 - 2026-08-21

- Initial Gesture Presentation / PDF Viewer implementation.
- Added local PDF and multi-image presentation viewing.
- Added common `AirRemoteBridge` action dispatch for manual, touch, keyboard, and gesture input.
- Added optional camera-based left/right hand motion recognition using a single embedded BlazePalm ONNX model.
- Added bilingual Japanese/English UI, fullscreen mode, responsive mobile bottom controls, help dialog, and local-only privacy behavior.
- Added fully embedded build pipeline with readable and gzip self-extracting single-HTML outputs.
