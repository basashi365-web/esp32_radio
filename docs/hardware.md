# Hardware Notes

## 目的

`esp32_radio` の初期実験では、Raspberry Piを使わずにESP32-S3単体でネットラジオを鳴らせるかを確認する。

## 初期候補

| 部品 | 用途 | 状態 |
|---|---|---|
| ESP32-S3 PSRAM付き開発ボード | Wi-Fi受信、デコード、I2S出力 | 必須候補 |
| MAX98357A I2S Class-D mono amp | I2S DAC内蔵アンプ | 初期音声出力 |
| 4Ωまたは8Ω小型スピーカー | 音声出力 | 初期実験用 |
| 5V USB電源 | ESP32-S3とアンプ給電 | 電流余裕を確認 |
| GM009606v4.3 OLED | 状態表示 | Phase 2以降。`pi_radio` と同じ表示器 |
| KY-040ロータリーエンコーダ | 音量/局切替 | Phase 3以降 |

## ESP32-S3

`ESP32-audioI2S` はPSRAMを必要とするため、PSRAM付きESP32-S3を前提にする。

推奨:

- ESP32-S3-N8R8
- ESP32-S3-N16R8
- ESP32-S3-WROOM-1-N16R8

次回確認すること:

- 実ボードの型番。
- PSRAM容量。
- Flash容量。
- USB/JTAGや起動ストラップと競合しないGPIO。
- ネイティブUSB Deviceを使える配線/USBポートか。

## MAX98357A

MAX98357AはI2S入力を受けるモノラルClass-Dアンプ。初期実験では1個だけ使い、左右mixまたは片ch出力で小型スピーカーを鳴らす。

注意:

- `SPK+` / `SPK-` はBTL出力で、どちらもGNDへ接続しない。
- 大音量では電流不足によるリセットや音割れが起きやすい。
- GAINとSD/MODEはまずモジュール既定で試す。

## pi_radioから引き継ぐ考え方

- 局候補は WNYC / BBC Radio 4 / ABC NewsRadio / NHK R1 を継承する。
- OLEDには局名、状態、IP、音量を出す。
- OLEDは `pi_radio` と同じ GM009606v4.3 を使い、`SSD1306 128x64 / I2C 0x3C` として扱う。
- ロータリーは回転で音量、短押しで局切替を基本にする。

移植しないもの:

- Linux systemd。
- NetworkManager。
- `shutdown -h now` による安全停止。
- USB DAC / PAM8403 構成。
