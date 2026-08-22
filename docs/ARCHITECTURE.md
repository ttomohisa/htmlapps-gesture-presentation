# Architecture

## Goal

Gesture Presentation is the first target implementation for the future **Air Remote** family. The key design rule is that document rendering, gesture recognition, and remote transport are separate layers.

## Current flow

```text
PDF / images
    ↓
Viewer state ──────────────┐
    ↓                      │
renderPage()               │
                           │
Buttons / keyboard / touch │
          ↓                │
window.AirRemoteBridge.dispatch(action, source)
          ↑
BlazePalm ONNX
          ↑
128×128 mirrored camera crop
```

### Viewer layer

- PDF.js renders PDF pages from in-memory bytes.
- Image files use temporary Blob URLs.
- A source-generation token prevents late PDF work from overwriting a newly selected source.

### Action layer

`window.AirRemoteBridge` is the only public control surface:

```js
window.AirRemoteBridge.dispatch('previous', 'remote');
window.AirRemoteBridge.dispatch('next', 'remote');
window.AirRemoteBridge.dispatch('fullscreen', 'remote');
window.AirRemoteBridge.dispatch('blackout', 'remote');
window.AirRemoteBridge.dispatch('timer-toggle', 'remote');
```

Manual buttons, keyboard, touch, and ONNX gesture recognition all converge on the same action path.

### Gesture layer

- The front-camera image is mirrored to match the preview.
- The visible square preview is center-cropped and resized to 128×128.
- RGB is normalized to `-1..1` and passed to BlazePalm through ONNX Runtime Web/WASM.
- BlazePalm produces 896 palm candidates: 16×16×2 plus 8×8×6 anchors.
- The highest-confidence valid palm is tracked over a short history.
- Horizontal displacement, duration, direction consistency, vertical drift, and cooldown determine whether to emit `next` or `previous`.
- v1 intentionally tracks one palm and does not classify static hand signs.

## Runtime privacy boundary

All dependencies are embedded into the generated HTML. The CSP sets `connect-src 'none'`, so the app cannot use runtime HTTP/fetch/WebSocket connections. Document bytes, camera frames, and palm detections stay in the browser. Optional Air Remote uses only a directly negotiated WebRTC DataChannel for small control/state messages; it does not upload documents or camera frames.

## Air Remote expansion path

The action layer should remain stable while inputs expand:

```text
Hand Landmark / static signs ─┐
Phone A via pairing/WebRTC ───┼─→ AirRemoteBridge ─→ target
Keyboard / touch ─────────────┘

Targets:
Presentation / PDF → Video → Teleprompter → other Browser Kitty tools
```

A future two-device mode should transmit only small action messages such as `{ action: "next" }`, not camera frames.


## v1.1 interaction layer

Gesture sensitivity is local recognition configuration and is not part of the remote transport. Gesture Lock is an action-level state and is exposed through `AirRemoteBridge` as `gesture-lock`, allowing a future phone remote to lock/unlock the presentation target without changing the camera pipeline.

Fullscreen controls live inside `viewerStage` because that element itself enters the Fullscreen API. This keeps Previous / Next / Gesture / Lock / Exit available after the surrounding application chrome leaves the fullscreen tree.


## v1.2 presentation tools

The action layer also owns presentation-only state:

```text
Black / white screen ─┐
Countdown timer ──────┼─→ AirRemoteBridge / presentation state
Page navigation ──────┘
```

The blank screen is an overlay inside `viewerStage`, so the fullscreen HUD remains above it. Timer timekeeping uses an absolute end timestamp rather than decrementing a counter, which avoids drift when the tab is briefly delayed.

## v1.2 fully local Air Remote host foundation (historical)

The PC side now has a real WebRTC host transport:

```text
PC Gesture Presentation
  RTCPeerConnection({ iceServers: [] })
          ↓ createOffer + local ICE gathering
  gzip/base64url offer payload
          ↓ direct/manual transfer (v1.2 verification path)
Phone responder
          ↓ base64url answer payload
PC setRemoteDescription(answer)
          ↓
  air-remote DataChannel
          ↓
AirRemoteBridge.dispatch(action, 'remote')
```

No signaling server, STUN, or TURN is configured. v1.2 exposed the offer/answer payload as text to validate the transport. v1.3 reuses exactly this payload format for the two QR exchanges.

`window.AirRemoteTransport` exposes the host lifecycle used by the QR pairing flow: `createOffer()`, `applyAnswer(code)`, `close()`, and `status`.


## Air Remote two-step QR pairing (v1.3.2)

```text
PC Gesture Presentation
  │  1. create WebRTC offer + local ICE candidates
  │  2. gzip/Base64URL → offer QR
  ▼
Phone camera / Remote mode
  │  3. setRemoteDescription(offer)
  │  4. create answer + local ICE candidates
  │  5. gzip/Base64URL → adaptive split answer QR parts
  │     (part index + total + whole-payload checksum)
  ▼
PC camera scanner (jsQR)
  │  6. setRemoteDescription(answer)
  ▼
WebRTC DataChannel: air-remote
```

No signaling server, STUN server, or TURN server is configured. The two QR codes are the signaling transport. When the app is served over HTTP(S) on a phone-reachable host (not `localhost`), the first QR contains the current app URL plus the offer in the URL fragment, so the phone's normal camera can open Remote mode directly. With `file://` or `localhost`, the QR carries only the Air Remote payload and the same HTML must already be open on the phone.

The DataChannel carries only small JSON action/state messages. PDF/image data and camera frames are never sent through Air Remote.
