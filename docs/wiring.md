# Wiring Notes

## 初期方針

まずはESP32-S3とMAX98357Aだけで音を出す。OLEDとロータリーエンコーダは、WNYC再生が安定してから追加する。

## MAX98357A I2S

| MAX98357A | ESP32-S3 GPIO案 | 役割 |
|---|---:|---|
| VIN | 5V | 電源 |
| GND | GND | 共通GND |
| DIN | GPIO4 | I2S data out |
| BCLK | GPIO5 | I2S bit clock |
| LRC / LRCLK / WS | GPIO6 | I2S left/right clock |
| GAIN | 未接続 | まず既定gain |
| SD / MODE | モジュール既定 | まず既定mode |
| SPK+ / SPK- | スピーカー | GNDへ接続しない |

このGPIO案は仮。実ボードのピン表確認後に確定する。

## OLED候補

| OLED | ESP32-S3 GPIO案 | 備考 |
|---|---:|---|
| SDA | GPIO8 | 仮 |
| SCL | GPIO9 | 仮 |
| VCC | 3.3V | モジュール仕様確認 |
| GND | GND | 共通GND |

`pi_radio` ではSSD1306 128x64 / I2C `0x3C` として点灯確認済み。`esp32_radio` では手元OLEDの型番を再確認する。

## KY-040候補

| KY-040 | ESP32-S3 GPIO案 | 備考 |
|---|---:|---|
| CLK / A | GPIO10 | 仮 |
| DT / B | GPIO11 | 仮 |
| SW | GPIO12 | 仮。pull-up想定 |
| + | 3.3V | モジュール仕様確認 |
| GND | GND | 共通GND |

## 配線時の注意

- I2S線は短めにする。
- アンプとESP32のGNDは必ず共通にする。
- スピーカー出力をGNDやイヤホン入力へつながない。
- 音が割れる場合はソフト音量を下げ、GAIN設定と電源容量を見直す。
