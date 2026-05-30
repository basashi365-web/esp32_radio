# ESP32 Radio

`esp32_radio` は、完成済みの `pi_radio` を小型ESP32-S3機へ派生させるためのネットラジオ実験プロジェクトです。

目標は、ESP32-S3 + MAX98357A I2Sアンプで WNYC / BBC / ABC / NHK R1 などのニュース・トーク局を再生し、後段でOLED表示、KY-040ロータリー操作、Wi-Fi設定画面を追加できる設計にすることです。

## 現在の状態

- 実装前の調査・設計段階。
- GitHub repository: https://github.com/basashi365-web/esp32_radio
- 第一候補ライブラリは `schreibfaul1/ESP32-audioI2S`。
- ESP32-S3はPSRAM付きボードを前提にする。
- スピーカーは購入済みの 2インチ / 50mm / 4Ω / 3W フルレンジスピーカーを使う。
- 表示器は `pi_radio` と同じ GM009606v4.3 OLED を使い、`SSD1306 128x64 / I2C 0x3C` として扱う方針。
- MAX98357AとのI2S接続、候補局URL、OLED/ロータリー追加方針、Wi-Fi設定方式を調査済み。
- 友人へ渡す将来構想として、ESP32-S3のUSB MSC設定モードで `WIFI.TXT` / `STATIONS.TXT` をPCから編集できる方式を後段候補にする。
- `pi_radio` との差分は、Linux/mpv/systemd/NetworkManagerではなく、ESP32ファームウェア単体で再生・操作・設定保存を行う点。

## 主要ドキュメント

- `docs/esp32_i2s_radio_research.md`: ESP32-S3 + MAX98357Aネットラジオの前例調査、リスク、最小実験手順。
- `docs/hardware.md`: 想定ハードウェアと部品選定。
- `docs/wiring.md`: 初期配線案。
- `docs/setup.md`: 次回の最小実験セットアップ入口。
- `docs/troubleshooting.md`: 実装前に想定している失敗パターン。
- `docs/development_notes.md`: 継続作業メモ。
- `docs/usb_msc_config_plan.md`: USB接続でTXT設定を編集する将来構想。

## 最小実験方針

1. PSRAM付きESP32-S3ボードを確認する。
2. MAX98357AをI2S 3線で接続する。
3. 50mm / 4Ω / 3W フルレンジスピーカーを `SPK+` / `SPK-` に接続する。
4. `ESP32-audioI2S` の最小スケッチでWNYC MP3直ストリームを再生する。
5. 音が出た後に、BBC / NHK / ABC のHLS/AAC局を個別に試す。
6. 再生が安定してからOLED、KY-040、Wi-Fi設定の順で追加する。
7. 友人配布向けには、Web設定画面またはUSB MSC TXT設定モードを後段で検討する。

## 参考元

- `pi_radio`: Raspberry Pi 3B+ + USB DAC/PAM8403で完成済みの親プロジェクト。
- `schreibfaul1/ESP32-audioI2S`: ESP32-S3 + I2S DAC/amp向けの第一候補ライブラリ。
- `Edzelf/ESP32Radio-V2`: 完成型ESP32ラジオUI/設定機能の参考。

## 注意

- Wi-Fi SSID/passwordなどの秘密情報はこのrepoに入れない。
- HLS/AAC局はPC上で音声検出できても、ESP32実機での再生は未確認。
- PSRAMなしESP32-S3での動作は前提にしない。
