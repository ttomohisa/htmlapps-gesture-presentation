# Offline verification

1. Run `build-standalone.bat` on Windows.
2. Open `dist/index.html`, select multiple images, and confirm Previous / Next, `←` / `→`, touch swipe, direct page input, and fullscreen work.
3. Open a PDF and repeat page navigation.
4. Start gesture control once while online/localhost only to grant camera permission if the browser requires it, then disconnect the network.
5. Confirm palm detection and left/right page turns continue without network requests.
6. Stop gesture control and confirm the camera indicator disappears and the camera track is released.
7. Replace the source while a PDF page is rendering and confirm no stale page from the previous PDF appears.
8. Repeat with `dist/index.self-extract.html`.
9. With Air Remote closed, confirm in DevTools Network that there are no external HTTP/CDN/WebSocket requests after the HTML itself has loaded.
10. Open Air Remote and create PC connection data. Confirm no signaling/STUN/TURN server is configured; the generated offer contains only browser-gathered local ICE information.
11. Confirm the console has no CSP, worker, WASM, decompression, or WebRTC setup errors.

`file://` is a required viewer target, but some browsers restrict camera permission from local files. In that case, use `start-local.bat`; the application still performs inference entirely on-device.

Air Remote is the one optional runtime network feature: it uses a directly negotiated WebRTC DataChannel between paired devices. It does not send documents or camera frames and does not use a signaling server, STUN, or TURN.

### Two-QR Air Remote test

1. Put the PC and phone on the same Wi-Fi/LAN.
2. On the PC, open Air Remote and create the connection QR.
3. Scan the first QR with the phone camera. Confirm the phone opens Remote mode and displays an answer QR.
4. On the PC, choose **Scan answer QR**, allow the camera, and scan the phone's QR.
5. Confirm both sides report connected.
6. Verify Previous / Next, gesture lock, black / white screen, and timer controls from the phone.
7. In DevTools, confirm there is no signaling/STUN/TURN/CDN traffic. WebRTC peer traffic itself is expected.
8. Disconnect Wi-Fi from the Internet while leaving the local LAN active and confirm the established remote still works.
