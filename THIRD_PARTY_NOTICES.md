# Third-party notices

The build embeds only the declared assets from these pinned npm packages.

## PDF.js (`pdfjs-dist` 3.11.174)

- Project: Mozilla PDF.js
- License: Apache License 2.0
- Homepage: https://mozilla.github.io/pdf.js/
- Embedded assets: `build/pdf.min.js`, `build/pdf.worker.min.js`

## ONNX Runtime Web (`onnxruntime-web` 1.27.0)

- Project: Microsoft ONNX Runtime
- License: MIT
- Homepage: https://onnxruntime.ai/
- Embedded assets: `ort.wasm.bundle.min.mjs` and `ort-wasm-simd-threaded.wasm`
- Embedded assets: WASM runtime JavaScript, Emscripten `.mjs` module, and SIMD WASM binary

## BlazePalmBarracuda (`jp.keijiro.mediapipe.blazepalm` 2.1.1)

- Project: BlazePalmBarracuda by Keijiro Takahashi
- License: Apache License 2.0
- Source: https://github.com/keijiro/BlazePalmBarracuda
- Embedded asset: `ONNX/palm_detection_barracuda.onnx`
- The package wraps a MediaPipe BlazePalm model converted to ONNX for local inference.

## QR Code Generator (`qrcode-generator` 2.0.4)

- Project: QR Code Generator by Kazuhiko Arase
- License: MIT
- Source: https://github.com/kazuhikoarase/qrcode-generator
- Embedded asset: `dist/qrcode.js`
- Used only to render the local Air Remote offer/answer QR codes.

## jsQR (`jsqr` 1.4.0)

- Project: jsQR
- License: Apache License 2.0
- Source: https://github.com/cozmo/jsQR
- Embedded asset: `dist/jsQR.js`
- Used only for on-device camera decoding of Air Remote QR codes.
