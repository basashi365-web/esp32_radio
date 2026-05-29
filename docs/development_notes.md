# Development Notes

## 2026-05-30

- `esp32_radio` を `pi_radio` 派生の本格プロジェクトとして扱う方針になった。
- 実装前に `docs/esp32_i2s_radio_research.md` を作成した。
- 最小実験の第一候補は `schreibfaul1/ESP32-audioI2S`。
- PSRAM付きESP32-S3を前提にする。
- WNYCはMP3直ストリームとして最初に試す。
- BBC Radio 4 / ABC NewsRadio / NHK R1 はPC上の `ffprobe` でHLS/AAC音声として検出できたが、ESP32実機再生は未確認。
- Web設定画面は初期実験には入れず、再生安定後の追加候補にする。

## 次回作業入口

1. 実ボード型番とPSRAM容量を確認する。
2. PlatformIOプロジェクトを作る。
3. `include/config.example.h` とgit除外の `include/config.local.h` 方針を作る。
4. MAX98357A + WNYC の最小再生スケッチを作る。
5. Serialログと実機結果をこのdocsへ追記する。

## 記録ルール

- 実機で確認したことは、未確認仮説と分けて書く。
- Wi-Fiパスワード、トークン、APIキーは書かない。
- 放送局URLは変更される可能性があるため、確認日を書く。
- `pi_radio` から再利用した設計と、ESP32用に変えた設計を分ける。
