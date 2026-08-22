# Gesture Presentation

**PDFや画像を、手を左右に振ってページ送りできるローカル処理のプレゼンテーションビューアーです。**  
Browser Kitty の将来機能 **Air Remote** につながる最初の実装として、表示側の操作APIと手ジェスチャー入力を分離しています。

## 特徴

- **PDF / 画像に対応** — PDF 1ファイル、または PNG / JPEG / WebP を複数選択
- **手を右へ振る → 次へ / 左へ振る → 前へ**
- **ONNXをブラウザー内で実行** — BlazePalmで手のひらを検出し、その移動を認識
- **資料もカメラ映像もアップロードしない** — Air Remote以外は実行時の外部通信なし
- ボタン、キーボード `←` `→`、タッチスワイプでも操作可能
- **プレゼン向け全画面表示** — 資料を画面いっぱいにし、最小HUDだけを表示
- **ジェスチャー感度：低 / 標準 / 高** — 選択は端末内に保存
- **ジェスチャーロック** — カメラを止めずにページ送りだけ一時停止
- **プレゼンタイマー** — 5 / 10 / 15分プリセット＋自由入力、全画面HUDからも操作
- **黒画面 / 白画面** — ボタンまたは `B` / `W` で資料を一時的に隠す
- **2段階QRのAir Remote** — サーバー/STUN/TURNなしでPCとスマホをWebRTC DataChannel接続
- カメラプレビューは認識を止めずに折りたたみ可能
- 日本語 / English 切り替え
- スマートフォンでは「前へ / ジェスチャー / ロック / 次へ」を固定下部に配置
- 配布物は `dist/index.html` 1ファイル（自己展開版も生成）

## 使い方

1. `dist/index.html` を開きます。カメラ操作まで使う場合は GitHub Pages（HTTPS）または `start-local.bat` の localhost を推奨します。
2. PDF、または複数の画像を選択します。
3. 通常のページ送りは画面のボタン・左右キー・タッチスワイプで行えます。
4. **「ジェスチャー操作を開始」**を押してカメラを許可します。
5. カメラ中央のガイド内に片手を大きめに映します。
6. 必要なら感度を **低 / 標準 / 高** から調整します。
7. **手を右へ振ると次へ、左へ振ると前へ**移動します。
8. 誤操作させたくない場面では **ロック** を押します。手認識は続きますが、ジェスチャーによるページ送りだけ止まります。

## ジェスチャー方式

初版は **BlazePalm ONNX（約3.9MB）だけ**を使い、カメラ映像を中央で正方形に切り出して128×128へ縮小し、手のひら中心を追跡します。21点のHand Landmarkモデルはまだ読み込まないため、Air Remoteへ発展させやすさを保ちつつ初版を軽くしています。

手のひらの左右移動は短い履歴から移動量・時間・方向の一貫性・上下のブレを判定し、ページが連続で飛ばないようクールダウンを入れています。ガイドは認識範囲そのものではなく、安定して操作するための目安です。

### 感度とロック

- **低** — 大きく明確なスワイプだけに反応。誤操作を抑えたいとき向け。
- **標準** — 従来の認識感に近いバランス設定。
- **高** — 小さめの動きでも反応しやすい設定。

ロック中もカメラとONNX推論は継続するため、解除後すぐ操作へ戻れます。ロック中の手の動きはページ送りに使いません。

## Air Remoteへの拡張

ページ操作はすべて次の共通インターフェースに集約しています。

```js
window.AirRemoteBridge.dispatch('next', 'remote');
window.AirRemoteBridge.dispatch('previous', 'remote');
window.AirRemoteBridge.dispatch('fullscreen', 'remote');
window.AirRemoteBridge.dispatch('gesture-lock', 'remote');
window.AirRemoteBridge.dispatch('blackout', 'remote');
window.AirRemoteBridge.dispatch('whiteout', 'remote');
window.AirRemoteBridge.dispatch('timer-toggle', 'remote');
```

v1.3.2では `RTCPeerConnection({ iceServers: [] })` を使い、**PCのOffer QR → スマホ → スマホのAnswer QR → PC** の2段階で `air-remote` DataChannelを直接接続します。シグナリングサーバー、STUN、TURNは使いません。Answerは長さに応じて読みやすい複数QRへ自動分割されます。スマホ側には専用Remote画面が開き、前後移動・ジェスチャーロック・黒/白画面・タイマーを操作できます。

将来、Hand Landmarkや `✋ / ☝️ / OK` などの静的ジェスチャー、別端末からのWebRTC等を追加しても、表示側はこの操作APIをそのまま利用できます。

## プライバシー

- 選択したPDF・画像はブラウザー内で読み込みます。
- カメラフレームはONNX推論用に一時的にCanvasへ描画するだけで、録画・保存・送信しません。
- Content Security Policyで `connect-src 'none'` を設定し、HTTP / fetch / WebSocketによる実行時通信を禁止しています。Air Remoteは接続した端末とのWebRTC DataChannelだけを任意で使用します。
- PDF.js、ONNX Runtime Web、Emscriptenモジュール、WASM、ONNXモデルはビルド時にHTMLへ内包します。
- ジェスチャー操作を停止すると、取得したカメラトラックを停止します。

## 対応・制限

- 現行のChromium / Firefox / Safariを対象にしています。
- カメラ利用はブラウザーの権限とSecure Contextの制約を受けます。GitHub Pages（HTTPS）またはlocalhostを推奨します。
- `file://` でもビューアー本体は開けますが、ブラウザーによってはカメラが制限されます。
- 片手・左右移動のみ。複数手や静的ハンドサイン分類は未対応です。
- 入力は100MiBまでです。
- `.pptx` は現時点では直接読み込みません。PowerPointはPDFへ書き出して利用してください。

## 単一HTML / オフライン

`build-standalone.bat` は依存ファイルを固定バージョンで取得し、HTMLへ埋め込みます。

生成物:

- `dist/index.html` — 読みやすい完全内包HTML
- `dist/index.self-extract.html` — HTML全体をgzip圧縮して内包した自己展開版
- `dist/dependency-manifest.json` — 依存・SHA-256情報
- `dist/build-size-report.json` — ファイルサイズ情報

実行時にCDNへアクセスしません。

## 開発 / ビルド

Windows 10/11 + PowerShell を想定しています。Pythonは不要です。

```bat
build-standalone.bat
```

ローカルでカメラも含めて確認する場合:

```bat
start-local.bat
```

リポジトリチェック:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File .\scripts\check-repository.ps1
```

アプリ本体は `src/index.template.html` を編集してください。`dist/` の生成HTMLは直接編集しません。

## 主な依存

| 依存 | バージョン | 用途 | ライセンス |
|---|---:|---|---|
| `pdfjs-dist` | 3.11.174 | PDF表示 | Apache-2.0 |
| `onnxruntime-web` | 1.27.0 | ONNX推論 | MIT |
| `jp.keijiro.mediapipe.blazepalm` | 2.1.1 | BlazePalm ONNX | Apache-2.0 |
| `qrcode-generator` | 2.0.4 | Air Remote QR生成 | MIT |
| `jsqr` | 1.4.0 | Air Remote QR読取 | Apache-2.0 |

詳細は `THIRD_PARTY_NOTICES.md` を参照してください。

## License

MIT License

### 2段階QRの完全ローカル Air Remote

PCで接続QRを表示 → スマホで読み取り → スマホの回答QRをPCで読み取り、の2段階でWebRTC DataChannelを直接接続します。シグナリングサーバー、STUN、TURNは使いません。回答データが長い場合はQRを自動で複数枚（通常2〜4枚程度）に分割し、PC側は順不同で収集・重複無視・チェックサム検証したうえで自動結合します。低性能なPCインカメラでも読みやすいよう、1枚あたりの情報量を抑えています。接続後はスマホから前後移動、ジェスチャーロック、黒/白画面、タイマーを操作でき、ページ番号と状態も同期します。

HTTP(S)で公開している場合（`localhost` を除く）、1回目のQRは同じHTMLのスマホRemote画面を直接開きます。`file://` / `localhost` の場合はスマホ側でも同じHTMLを先に開き、Remote画面のQRスキャナーを使います。
