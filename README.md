# ESP32 Radio

`esp32_radio` は、完成済みの `pi_radio` を小型ESP32-S3機へ派生させるためのネットラジオ実験プロジェクトです。

目標は、ESP32-S3 + MAX98357A I2Sアンプで WNYC / BBC / ABC / NHK R1 などのニュース・トーク局を再生し、後段でOLED表示、KY-040ロータリー操作、Wi-Fi設定画面を追加できる設計にすることです。

## 現在の状態

- PlatformIO初期ファームウェア実装済み。COM24へ書き込み、ESP32-S3 / PSRAM / OLED / Wi-Fi / WNYC音出しまで実機確認済み。
- GitHub repository: https://github.com/basashi365-web/esp32_radio
- 第一候補ライブラリは `schreibfaul1/ESP32-audioI2S`。
- ESP32-S3はPSRAM付きボードを前提にする。今回使う実物基板は写真上で `ESP32-S3-WROOM-1 N16R8` と確認済み。
- スピーカーは購入済みの 2インチ級 / 53mm / 4Ω / 3W フルレンジスピーカーを使う。
- 表示器は `pi_radio` と同じ GM009606v4.3 OLED を使い、`SSD1306 128x64 / I2C 0x3C` として扱う方針。
- 基板・周辺部品の共有写真は `D:\data\codex\shared_assets\hardware\esp32_radio\20260601_board_photos` に保存済み。
- MAX98357AとのI2S接続、候補局URL、OLED/ロータリー追加方針、Wi-Fi設定方式を調査済み。
- MAX98357Aは `VIN=5V`、`SD/MODE=3.3V` で音出し確認済み。GAINはオープンのまま。
- OLEDはI2C `0x3C` で検出済み。FreeSans系フォントの局名/音量表示を採用済み。
- KY-040は回転で音量、短押しで選曲。未検証局は `not tested` 表示だけにして、自動接続しない。
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
3. 53mm / 4Ω / 3W フルレンジスピーカーを `SPK+` / `SPK-` に接続する。
4. `ESP32-audioI2S` の初期スケッチでWNYC MP3直ストリームを再生する。
5. OLEDへ大きい局名、中サイズの音量、小さい `stream ok` / `stream lost` / `not tested` を出す。
6. KY-040で音量変更と選曲を行う。
7. 友人配布向けには、Web設定画面またはUSB MSC TXT設定モードを後段で検討する。

## 参考元

- `pi_radio`: Raspberry Pi 3B+ + USB DAC/PAM8403で完成済みの親プロジェクト。
- `schreibfaul1/ESP32-audioI2S`: ESP32-S3 + I2S DAC/amp向けの第一候補ライブラリ。
- `Edzelf/ESP32Radio-V2`: 完成型ESP32ラジオUI/設定機能の参考。

## 注意

- Wi-Fi SSID/passwordなどの秘密情報はこのrepoに入れない。
- HLS/AAC局はPC上で音声検出できても、ESP32実機での再生は未確認。
- PSRAMなしESP32-S3での動作は前提にしない。
