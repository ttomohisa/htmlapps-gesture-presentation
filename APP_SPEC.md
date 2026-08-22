# APP_SPEC.md

## 1. Product identity

- **Name:** Gesture Presentation / ジェスチャー・プレゼンテーション
- **Repository:** `ttomohisa/htmlapps-gesture-presentation`
- **Version:** `1.3.3`
- **Purpose:** View PDFs or a sequence of images and move between pages with local hand-swipe recognition.
- **Long-term direction:** This is the first UI/runtime foundation for Browser Kitty “Air Remote”.
- **Release artifacts:** `dist/index.html` and `dist/index.self-extract.html`.

## 2. Problem and outcome

When presenting, cooking, demonstrating a device, or working with dirty/gloved hands, touching the screen to change pages is inconvenient. The app provides a local presentation viewer where the camera can recognize left/right hand motion and convert it into previous/next actions.

The first release uses a single embedded BlazePalm detector and tracks the highest-confidence palm center across a short time window. That gives the app full-frame palm detection inside the square camera preview without paying the extra cost of a 21-point landmark model. A later Air Remote release can add landmarks and richer static gestures without changing the presentation action interface.

## 3. Core user flow

1. Open the app directly or from GitHub Pages.
2. Select one PDF or one/more image files (PNG/JPEG/WebP).
3. Navigate manually with Previous/Next, arrow keys, swipe on the document, or page input.
4. Optionally press “Start gesture control” and grant camera permission.
5. Place one hand inside the camera guide and move it left/right deliberately.
6. Choose Low / Standard / High sensitivity if the default response does not match the environment.
7. Use Gesture Lock when page turns should be temporarily disabled without stopping the camera.
8. The recognized swipe is sent through the common `AirRemoteBridge` action path and changes the page.
9. Fullscreen presentation mode exposes a minimal HUD for page, gesture, lock, and exit controls.
10. Stop the camera at any time. Camera frames are never uploaded or saved.

## 4. Functional requirements

### Documents

- Accept one PDF up to 100 MiB.
- Accept one or more PNG, JPEG, or WebP images, up to 100 MiB total.
- Sort multiple images in file-selection order.
- Render PDF pages through embedded PDF.js.
- Render images with object-fit containment and no upload.
- Support Previous, Next, direct page number, keyboard ArrowLeft/ArrowRight, and touch horizontal swipe.
- Provide a Fullscreen action with a minimal in-stage presentation HUD.
- Cancel stale PDF render work when the source or page changes.

### Gesture control

- Camera starts only after an explicit user action.
- Use the front-facing camera when available.
- Load the embedded bundled ESM build of `onnxruntime-web`, its WASM binary, and the embedded BlazePalm ONNX model only when gesture control is first requested.
- Center-crop the mirrored front-camera frame to a square and resize it to the model's 128×128 RGB NCHW input.
- Normalize RGB values to -1..1, matching the upstream model preprocessing.
- Decode the BlazePalm 16×16/two-anchor and 8×8/six-anchor heads, select the highest-confidence palm, and track its center across a short time window.
- Require a confidence above 0.75 and reject motions with excessive vertical drift before page navigation.
- Trigger one `next` or `previous` action after a sufficiently fast and long horizontal movement, then apply a cooldown to prevent repeated page turns.
- Provide Low / Standard / High sensitivity presets that tune minimum movement, vertical drift tolerance, direction consistency, and cooldown.
- Persist the selected sensitivity locally.
- Provide Gesture Lock: keep camera inference and hand feedback running while suppressing gesture-originated page actions.
- Expose lock state consistently in desktop controls, smartphone controls, and fullscreen controls.
- Expose manual and gesture actions through a shared `window.AirRemoteBridge.dispatch(action, source)` interface so a future remote transport can reuse it, including the `gesture-lock` action.
- Initial release recognizes horizontal motion only; it does not classify open palm, OK, pointing, etc.

### Language and UX

- Japanese and English live in the same HTML.
- Light-only UI.
- Inline SVG icons; no emoji as primary controls.
- Desktop: document preview is primary; gesture panel is secondary.
- Smartphone: document preview and its navigation remain adjacent. A safe-area-aware bottom bar provides Previous / Gesture / Lock / Next.
- Help dialog must explain privacy, camera permission, sensitivity, gesture lock, fullscreen controls, the single-hand swipe limitation, and browser limitations.

## 5. Data and privacy

- Selected documents remain in browser memory only.
- Camera frames remain in browser memory only.
- No camera recording is created.
- No analytics, telemetry, cloud inference, login, API call, or runtime CDN request.
- The CSP keeps `connect-src 'none'`.
- Stopping gesture control stops all camera tracks.

## 6. State model

### Source phase

- `empty`
- `loading-document`
- `ready`
- `error`

Replacing the source increments a generation token, cancels in-flight PDF rendering, clears page state, releases image object URLs, and rejects stale async results.

### Gesture phase

- `idle`
- `loading-runtime`
- `requesting-camera`
- `running`
- `error`

Stopping or replacing the camera invalidates the inference loop and clears gesture history.

## 7. Non-goals for v1.3.3

- Controlling unrelated browser tabs or native applications.
- Multi-hand gestures.
- Static gesture classification such as OK, open palm, fist, or pointing.
- PowerPoint (`.pptx`) parsing.
- Cloud sharing or collaborative presentation.
- Presenter notes.

## 8. Performance expectations

- Viewer remains interactive while gesture inference runs.
- Gesture inference is throttled to roughly 8–12 runs/second depending on device speed rather than processing every camera frame.
- PDF rendering is resolution-capped to avoid oversized canvases on high-DPI phones.
- ONNX Runtime is configured to a single WASM thread so the app works without cross-origin isolation headers. Its runtime JavaScript, Emscripten `.mjs` factory, and WASM binary are all embedded; the `.mjs` factory is supplied as a Blob URL and the WASM bytes through `wasmBinary`, so initialization does not fetch runtime files.

## 9. Browser target and local opening

- Viewer: current stable Chromium, Firefox, and Safari desktop/mobile.
- Gesture control requires `getUserMedia`; GitHub Pages/HTTPS is the recommended mode.
- The generated HTML itself must still open through `file://`. If a browser blocks camera access on `file://`, manual document viewing remains available and `start-local.bat` provides a localhost option.

## 10. Acceptance criteria

- Build outputs both single-file variants.
- No unresolved build placeholders.
- Runtime CSP includes `connect-src 'none'`.
- Embedded dependency bytes are Base64 encoded once; gzip assets use async accessors.
- PDF and multi-image navigation work without network access after build.
- Changing the source cannot allow an old PDF render to overwrite the new source.
- Previous/Next disable correctly at first/last page.
- Keyboard and touch navigation share the same action dispatcher.
- Gesture control can be started/stopped repeatedly without leaving camera tracks active.
- A recognized rightward motion maps to Next; leftward motion maps to Previous.
- Gesture actions are debounced/cooldown-protected.
- Low / Standard / High sensitivity materially changes swipe thresholds and the selection persists across reloads.
- Gesture Lock prevents gesture-originated page turns while keeping recognition running.
- Fullscreen presentation controls remain usable without leaving fullscreen.
- Fullscreen PDF rendering uses the fullscreen stage dimensions.
- Japanese/English switch updates visible UI without reload.
- 360 px smartphone layout keeps preview and navigation close together.
- Help content contains no starter-template copy.


## 10.5 Presentation tools (v1.2)

- Countdown timer with 5 / 10 / 15 minute presets and 1–180 minute custom duration.
- Timer remains visible and controllable from the fullscreen HUD.
- `B` toggles a black presentation screen; `W` toggles a white presentation screen. Clicking the blanked stage restores the document.
- Blank-screen and timer actions are exposed through `AirRemoteBridge` for future phone control.

## 10.6 Fully local Air Remote host foundation (v1.2)

- The PC creates an `RTCPeerConnection` with `iceServers: []`; no signaling server, STUN, or TURN is configured.
- The complete local offer is gzip-compressed when supported and encoded into a compact base64url payload after ICE gathering finishes.
- The v1.2 verification UI let the user copy the offer and paste/apply a phone answer; v1.3 reuses the same transport payload for two QR scans.
- The `air-remote` DataChannel accepts only actions listed by `AirRemoteBridge.actions`.
- When connected, the PC sends compact presentation state snapshots (page, total, gesture state, blank mode, and timer state).
- Intended first target: devices on the same Wi-Fi / LAN. Browser network/privacy policies can still affect host-candidate reachability.

## 10.7 Two-step QR Air Remote pairing (v1.3.3)

- PC renders its completed WebRTC offer as a QR code.
- On HTTP(S), the first QR contains the current app URL plus the offer in the URL fragment so the phone camera opens the same HTML directly in Remote mode.
- On `file://`, the QR contains an Air Remote payload; the same HTML must already be open on the phone and its built-in QR scanner is used.
- The phone creates a local answer, renders it as the second QR, and exposes a compact touch-first Remote UI.
- Phone Answer payloads are adaptively split into coarse QR parts (targeting about 2–4 parts for normal SDP sizes). Each part carries the transfer kind, whole-payload checksum, part index, and total count.
- PC decodes Answer QR parts on-device with the embedded jsQR runtime, accepts them in any order, ignores duplicates, verifies the checksum after assembly, and applies the reconstructed Answer as the remote description.
- Legacy single-QR Answer payloads and manual copy/paste remain supported.
- Manual copy/paste remains available only as a fallback when camera access is unavailable.
- The phone Remote controls Previous / Next, gesture lock, black/white screen, and timer actions; page/timer/blank/lock state is synchronized from the PC.
- No signaling server, STUN, TURN, CDN, document upload, or camera-frame transfer is used.

## 11. Future Air Remote path

The app deliberately separates “recognition/transport” from “actions”. Future milestones can add:

1. Hand-landmark ONNX plus static gesture classification for pause/fullscreen/pointer modes.
2. Pointer/cursor mode driven by fingertip position.
3. Video and teleprompter targets.
4. Optional pointer/laser mode and richer remote controls on top of the existing two-QR DataChannel transport.
