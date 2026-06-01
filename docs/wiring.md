# Wiring Notes

## 初期方針

ESP32-S3、MAX98357A、OLED、ロータリーエンコーダを接続済みとして扱う。
初期スケッチでは、OLEDへ状態/IP/音量を出し、KY-040で音量変更と局送りを行う。

## MAX98357A I2S

| MAX98357A | ESP32-S3 GPIO案 | 役割 |
|---|---:|---|
| VIN | 5V | 電源 |
| GND | GND | 共通GND |
| DIN | GPIO4 | I2S data out |
| BCLK | GPIO5 | I2S bit clock |
| LRC / LRCLK / WS | GPIO6 | I2S left/right clock |
| GAIN | 未接続 | まず既定gain |
| SD / MODE | 3.3V | 初期音出しでは強制ON。オープンだと基板によって無音になり得る |
| SPK+ / SPK- | 53mm / 4Ω / 3W speaker | GNDへ接続しない |

このGPIO案は仮。実ボードのピン表確認後に確定する。

2026-06-01に今回使うESP32-S3-WROOM-1 N16R8基板とMAX98357Aの表裏写真を共有資産として保存した。
配線を確定するときは `D:\data\codex\shared_assets\hardware\esp32_radio\20260601_board_photos` の表裏写真でシルク印字を確認する。

## OLED

`pi_radio` と同じ GM009606v4.3 OLED を使う。`pi_radio` では `SSD1306 128x64 / I2C 0x3C` として点灯確認済み。

| OLED | ESP32-S3 GPIO案 | 備考 |
|---|---:|---|
| SDA | GPIO8 | 初期実装 |
| SCL | GPIO9 | 初期実装 |
| VCC | 3.3V | モジュール仕様確認 |
| GND | GND | 共通GND |

`SCK` 表記の端子がある場合はI2Cの `SCL` として扱う。

## KY-040候補

| KY-040 | ESP32-S3 GPIO案 | 備考 |
|---|---:|---|
| CLK / A | GPIO10 | 初期実装。内部pull-up |
| DT / B | GPIO11 | 初期実装。内部pull-up |
| SW | GPIO12 | 初期実装。内部pull-up |
| + | 3.3V | モジュール仕様確認 |
| GND | GND | 共通GND |

## 配線時の注意

- I2S線は短めにする。
- アンプとESP32のGNDは必ず共通にする。
- スピーカー出力は53mm / 4Ω / 3Wフルレンジスピーカーへつなぐ。
- スピーカー出力をGNDやイヤホン入力へつながない。
- 音が割れる場合はソフト音量を下げ、GAIN設定と電源容量を見直す。
- GAINオープンはデフォルト9dBなので初期実験ではそのままでよい。
- SD/MODEはシャットダウン兼チャンネル選択。最初の音出しでは3.3Vへ接続してアンプを確実にONにする。
- SD/MODEをGNDへ落とすとシャットダウンになる。オープンはモジュール実装によって不安定なので、無音時はまずSD/MODEを疑う。

## 音質と電源まわり

- `pi_radio` と同じスピーカーを流用しているため、音質差の主因はスピーカーそのものより MAX98357A、5V/GND配線、電源安定性、ESP32側の負荷と見る。
- MAX98357Aの `VIN` は5V、`GND` はESP32と共通、`SD/MODE` は3.3Vで強制ONにする。`SD/MODE` オープンは無音原因になり得る。
- `GAIN` はオープンのままでよい。音量不足や音割れが明確になった場合にだけ変更を検討する。
- 最初の音質改善は、スピーカー固定、筐体、5V/GNDの短く太い配線、USB電源の余裕、I2S配線の取り回しから確認する。
- `PCM5102A + PAM8403` は音質改善候補だが、部品点数、配線、電源、コストが増えるため現時点では保留し、MAX98357A構成を継続する。
