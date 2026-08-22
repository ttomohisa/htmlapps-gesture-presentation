# Security and privacy

Gesture Presentation is designed as a local-first browser application.

- Documents are read locally and are not uploaded.
- Camera frames are processed locally and are not recorded or transmitted.
- The release HTML uses a restrictive Content Security Policy with `connect-src 'none'` to block runtime HTTP/fetch/WebSocket connections.
- Third-party JavaScript, WASM, PDF worker code, and the ONNX model are pinned at build time and embedded into the generated HTML.
- Camera access is requested only after the user presses the gesture-control button.
- Stopping gesture control stops every MediaStream track obtained by the app.
- Air Remote transmits only small action/state messages over a user-initiated peer connection; incoming action names are restricted to `AirRemoteBridge.actions`.

## Trust boundary

The build machine downloads pinned npm packages. Review `dependencies.json`, `dist/dependency-manifest.json`, and the third-party notices before release. Normal viewer and gesture operation requires no runtime network access. Optional Air Remote opens only a directly negotiated WebRTC DataChannel to the paired device; no signaling server, STUN, or TURN is configured, and documents/camera frames are never sent through it.
