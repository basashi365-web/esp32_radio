# ESP32-S3 + MAX98357A I2S Radio Research

作成日: 2026-05-30

このメモは、`pi_radio` の派生版として ESP32-S3 + MAX98357A による小型ネットラジオ `esp_radio` を設計するための事前調査である。まだ実装は始めない。前例、部品構成、リスク、最小実験手順を整理する。

## 結論

- 最小実験の第一候補は `schreibfaul1/ESP32-audioI2S`。
- ESP32-S3は PSRAM付きボードを前提にする。特に `ESP32-S3-N16R8` や `N8R8` のような PSRAM搭載品が安全。
- MAX98357Aは I2S 3線 `BCLK` / `LRC` / `DIN` と電源/GNDだけで音が出せる。モノラルアンプなので、まずは1個で十分。
- `WNYC` はMP3直ストリームなので最も実験向き。
- `BBC Radio 4`、`ABC NewsRadio`、`NHK R1` はHLS/AACとしてPC上では音声検出できたが、ESP32実機では `m3u8` リダイレクト、TLS、バッファ、地域/配信URL変更のリスクがある。
- Web設定画面は最初から本格実装しない。最初は固定SSID + 固定局URLで音を出し、次に簡易AP/設定保存、最後にWeb UIを検討する。
- `Edzelf/ESP32Radio-V2` は完成度の高いラジオアプリの参考にはなるが、最小実験の土台としては大きい。`esp_radio` では `ESP32-audioI2S` を使った薄い実装から始める方が `pi_radio` の派生として管理しやすい。

## 調査対象

### schreibfaul1/ESP32-audioI2S

リポジトリ:

- https://github.com/schreibfaul1/ESP32-audioI2S
- Wiki: https://github.com/schreibfaul1/ESP32-audioI2S/wiki

確認した内容:

- ESP32、ESP32-S3、ESP32-P4対応。
- PSRAM最小2MBが必要と明記されている。
- 外部DACが必要で、MAX98357Aがテスト済みDACに含まれる。
- 対応codecは MP3、AAC、AAC+、WAV、FLAC、Vorbis、M4A、Opus。
- `pls`、`m3u`、`asx`、`m3u8` プレイリストを認識するとされる。
- Wi-Fi、SD、SD_MMC、SPIFFS、FFatが音源に使える。
- サンプルは `audio.setPinout(I2S_BCLK, I2S_LRC, I2S_DOUT)` でI2Sピンを指定し、`audio.connecttohost(url)` でストリームへ接続する。

評価:

- `esp_radio` の最小実験に向く。
- MAX98357Aと直接組み合わせやすい。
- HLS/AACまで試せる可能性がある。
- PSRAM必須なので、手元ボードの型番確認が最初の関門。

### Edzelf/ESP32Radio-V2

リポジトリ:

- https://github.com/Edzelf/ESP32Radio-V2

確認した内容:

- 旧 `ESP32-Radio` の新バージョン。
- I2S出力と SP/DIF 出力に対応。
- `config.h` でコンパイル時設定を行う。
- `data` ディレクトリのアップロードが必要。
- SDカード対応は experimental。
- 2024-10-17にESP32-S3実験対応が入っている。
- `DEC_HELIX` 系を選ぶとMP3/AACのソフトウェアデコード + I2S出力構成になる。
- OLED、TFT、Nextion、ロータリーエンコーダ、MQTT、Web設定など、完成品ラジオ寄りの機能を多く持つ。

評価:

- 完成形のUI、設定、Web画面、ロータリー入力、プリセット管理の参考にする価値が高い。
- 一方で、最初の `音が出るか` 実験には大きすぎる。
- `esp_radio` の第一段階では採用せず、第二段階以降の設計参考にする。

### Edzelf/ESP32-Radio

リポジトリ:

- https://github.com/Edzelf/ESP32-Radio

確認した内容:

- README上でV2の利用が推奨されている。
- 古い版はVS1053 + TFT中心の構成。
- MP3/Ogg、`.m3u`、最大320kbps、Web設定、内蔵Webサーバ、MQTT、シリアル、IR、ロータリー、タッチ入力などの機能がある。

評価:

- 旧版は設計思想と機能一覧の参考に留める。
- 新規派生の直接ベースにはしない。

## PSRAM付きESP32-S3が必要か

必要と考える。

理由:

- `ESP32-audioI2S` は現行README/Wikiで PSRAM必須を明記している。
- WebラジオではWi-Fi受信、HTTP/HLS処理、codec decode、I2S出力を同時に行うため、バッファ不足が音切れやクラッシュに直結する。
- `pi_radio` と違い、ESP32側ではLinux/mpvの大きな余裕がない。

推奨:

- 最小: ESP32-S3 + PSRAM 2MB以上。
- 推奨: ESP32-S3 + PSRAM 8MB以上。
- 候補表記: `ESP32-S3-N8R8`、`ESP32-S3-N16R8`、`ESP32-S3-WROOM-1-N16R8` など。

確認方法:

- 購入ページや基板シルクで PSRAM有無を確認する。
- PlatformIO/Arduinoの起動ログで `PSRAM` 検出を確認する。
- 実験スケッチで `ESP.getPsramSize()` を表示する。

## MAX98357AとのI2S配線

MAX98357A側の主要ピン:

| MAX98357A | 役割 | ESP32-S3側 |
|---|---|---|
| VIN | 電源 | 5V推奨。小音量実験なら3.3Vでも動く場合がある |
| GND | GND | GND共通 |
| BCLK | I2S bit clock | 任意の出力可能GPIO |
| LRC / LRCLK / WS | I2S left/right clock | 任意の出力可能GPIO |
| DIN | I2S audio data in | 任意の出力可能GPIO |
| SD / MODE | shutdown / L/R/mono選択 | まずはモジュール既定。必要なら抵抗でmono平均を確認 |
| GAIN | gain設定 | まずは未接続またはモジュール既定 |
| SPK+ / SPK- | スピーカー出力 | 4Ω以上の小型スピーカー。GNDへ接続しない |

初期配線案:

| 信号 | ESP32-S3 GPIO案 | 備考 |
|---|---:|---|
| I2S_DOUT -> DIN | GPIO4 | `ESP32-audioI2S` Wiki例に合わせた案 |
| I2S_BCLK -> BCLK | GPIO5 | 同上 |
| I2S_LRC -> LRC | GPIO6 | 同上 |
| OLED SDA | GPIO8 | 仮。実ボードの空きピンに合わせて変更 |
| OLED SCL | GPIO9 | 仮。実ボードの空きピンに合わせて変更 |
| Rotary A | GPIO10 | 仮。割り込み入力に使いやすいピン |
| Rotary B | GPIO11 | 仮 |
| Rotary SW | GPIO12 | 仮。内部pull-up利用想定 |

注意:

- ESP32-S3は基板ごとに使えないピンやUSB/JTAG/PSRAM/Flashに近い注意ピンがある。実ボード型番確定後にピン表で再確認する。
- MAX98357Aのスピーカー出力はBTL出力なので、`SPK-` をGNDへ落とさない。
- 大音量では電流が増えるため、スピーカー駆動は5V電源に余裕を持たせる。
- 音割れやノイズが出る場合、GAINを下げる、音量初期値を下げる、BCLK/LRC/DINの配線を短くする。

## 対応ストリーム形式

`ESP32-audioI2S` ベースで期待できる形式:

| 形式 | 期待度 | 備考 |
|---|---|---|
| MP3直ストリーム | 高 | 最小実験の第一候補 |
| AAC直ストリーム | 高 | ESP32-S3ではAAC+ SBR/Parametric Stereoも対応表に入る |
| PLS / M3U | 中-高 | ライブラリが認識対応。ただしURL解決の癖は実機確認が必要 |
| M3U8 / HLS | 中 | ライブラリ上は認識対象。放送局側のTLS/リダイレクト/セグメント条件で失敗する可能性 |
| Ogg/Vorbis | 中 | 対応表にはあるが、Vorbisはビットレート条件あり |
| FLAC | 低-中 | 対応するが、ネットラジオ用途では負荷・帯域が重い |
| Opus | 中 | 対応表にはあるが、局候補では優先しない |

## 局URLの再生可能性

`pi_radio/config/stations.json` の候補URLをPC上の `ffprobe 8.1.1` で確認した。これは `ESP32で再生できる保証` ではなく、2026-05-30時点でURLが音声ストリームとして見えるかの確認である。

| 局 | URL | PC上の検出結果 | ESP32-S3見込み |
|---|---|---|---|
| WNYC FM | `https://fm939.wnyc.org/wnycfm` | MP3 / 32000Hz / stereo | 最有力。最初に試す |
| BBC Radio 4 | `https://a.files.bbci.co.uk/ms6/live/3441A116-B12E-4D2F-ACA8-C1984642FA4B/audio/simulcast/hls/nonuk/audio_syndication_low_sbr_v1/cfs/bbc_radio_fourfm.m3u8` | HLS / AAC / 48000Hz / stereo | 要実機確認。HLS/TLS/地域条件に注意 |
| ABC NewsRadio | `https://mediaserviceslive.akamaized.net/hls/live/2038311/newsradio/index.m3u8` | HLS / AAC。複数variantあり | 要実機確認。variant選択とHLS処理に注意 |
| NHK R1 | `https://simul.drdi.st.nhk/live/3/joined/master.m3u8` | HLS / AAC / 48000Hz / stereo | 要実機確認。URL変更リスクあり |

最小実験の順番:

1. WNYC MP3直ストリーム。
2. BBC Radio 4 HLS/AAC。
3. NHK R1 HLS/AAC。
4. ABC NewsRadio HLS/AAC。

理由:

- WNYCは `pi_radio` でmpv/systemd再生確認済みで、ESP32側でもMP3直ストリームとして最も単純。
- HLS局は `ESP32-audioI2S` が `m3u8` を認識するとされるが、実機のメモリ、TLS、セグメント取得、リダイレクトの影響を受けやすい。

## OLED表示とロータリーエンコーダ構成

`pi_radio` ではSSD1306 128x64 OLEDとKY-040ロータリーエンコーダで、局名、音量、状態表示、短押し局切替、長押しシャットダウンを扱った。

`esp_radio` での段階案:

### Phase 1: 音だけ

- OLEDなし。
- ロータリーなし。
- 固定SSID、固定URL、Serialログのみ。
- 目的は `ESP32-S3 + MAX98357A + WNYC` で音が出ること。

### Phase 2: 表示

- SSD1306/SH1106 128x64 OLEDをI2C接続。
- 表示項目:
  - 接続中/再生中/エラー
  - SSIDまたはIPアドレス
  - 局名
  - codec名
  - 音量
  - バッファ状態または再接続回数

### Phase 3: 操作

- KY-040ロータリーエンコーダ追加。
- 回転: 音量。
- 短押し: 次の局。
- 長押し: Wi-Fi設定モード、または停止/再接続。
- ESP32にはOSシャットダウンがないため、`pi_radio` の安全シャットダウン操作はそのまま移植しない。

## Wi-Fi設定方法

候補:

| 方法 | 長所 | 短所 | 推奨段階 |
|---|---|---|---|
| 固定SSID/passwordをビルド時指定 | 最小で確実 | 書き換えに再ビルドが必要。秘密情報をgitに入れない注意が必要 | Phase 1 |
| `WiFiMulti` で複数SSID | 複数環境に少し強い | まだビルド時秘密情報が残る | Phase 1.5 |
| Serial経由で初回設定 | Web UI不要 | 現地運用では不便 | Phase 2候補 |
| SoftAP + Captive Portal / WiFiManager系 | スマホから設定できる | 依存と状態管理が増える | Phase 3候補 |
| 独自Web設定画面 + NVS/LittleFS保存 | `pi_radio` の操作感に近づく | 実装量が増え、音声再生とのリソース競合が出る | Phase 4候補 |

推奨:

- 最初は固定SSIDで実験する。
- 秘密情報は `secrets.h` や `config.local.h` に分離し、`.gitignore` 対象にする。
- 実用化段階で SoftAP + Web設定を入れる。

## Web設定画面を入れるべきか

最初からは入れない。

理由:

- まず確認すべきリスクは、ESP32-S3がHLS/AAC局を安定再生できるか、MAX98357Aでノイズなく音が出るか。
- Webサーバ、DNS、設定保存、HTML配信を同時に入れると、失敗時に原因が分かりにくい。
- `pi_radio` はLinux/NetworkManager/mpvの余裕があったが、ESP32ではメモリとタスク設計が制約になる。

入れるなら:

- 音声再生が安定した後。
- 設定項目は最小限:
  - Wi-Fi SSID/password
  - 局一覧URL
  - 音量初期値
  - 再起動ボタン
  - 現在のIP/再生状態/エラー表示
- 放送局URL編集を入れる場合は、長いURLやHLS URL変更に対応できるテキスト保存方式にする。

## 既存 pi_radio との違い

| 項目 | pi_radio | esp_radio案 |
|---|---|---|
| 本体 | Raspberry Pi 3B+ | ESP32-S3 PSRAM付き |
| 再生 | `mpv` + Linux ALSA | `ESP32-audioI2S` + I2S |
| 音声出力 | USB DAC -> PAM8403/外部アンプ | MAX98357A I2S DAC内蔵アンプ |
| OS | Linux | ベアメタル/Arduino/FreeRTOS |
| サービス化 | systemd | ファームウェア常時起動 |
| Wi-Fi | NetworkManager、既知Wi-Fi保存 | NVS/LittleFS/独自設定が必要 |
| UI | OLED + KY-040確認済み | OLED + KY-040を段階追加 |
| 安全停止 | 長押しで `shutdown -h now` | 原則不要。リセット/省電力/停止操作に置換 |
| 局再生の安定性 | mpvが強い | ライブラリ・PSRAM・HLS次第 |
| 保守 | SSHでログ確認しやすい | Serialログ/OTA/Webログ設計が必要 |
| 消費電力/サイズ | 大きめ | 小型・低消費電力化しやすい |

派生方針:

- `pi_radio` の局リスト、OLED表示項目、ロータリー操作思想を再利用する。
- Linux依存の systemd、NetworkManager、安全シャットダウンは移植しない。
- `esp_radio` では「小型・単機能・ファームウェア完結」を優先する。

## リスク

- PSRAMなしボードではライブラリ要件を満たさない可能性が高い。
- HLS/AAC局はPCやPiで再生できてもESP32で安定するとは限らない。
- 放送局URLは変更される可能性がある。特にNHKとABCは直接URLの寿命に注意。
- TLS証明書、HTTPSリダイレクト、SNI、User-Agent差で失敗する可能性がある。
- MAX98357AのGAIN/SD/MODE設定によって音量、左右ch、mono mix、ノイズが変わる。
- スピーカー電源電流が足りないとリセット、音割れ、ノイズが出る。
- OLEDとロータリーを追加すると、I2C/割り込み/描画更新が音声再生ループを邪魔する可能性がある。
- Web設定画面を入れるとメモリとタスク競合が増える。

## 最小実験手順

まだ実装しないが、次回作業の入口として以下を想定する。

1. 使用するESP32-S3ボード型番を確認する。
2. PSRAM有無、Flash容量、使用不可ピンを確認する。
3. MAX98357Aを `BCLK` / `LRC` / `DIN` / `VIN` / `GND` だけで接続する。
4. PlatformIO または Arduino IDE で `ESP32-audioI2S` の最小スケッチを作る。
5. `ESP.getPsramSize()`、Wi-Fi接続、IPアドレスをSerialに出す。
6. WNYC `https://fm939.wnyc.org/wnycfm` だけを再生する。
7. 音が出たら、音量初期値を低めから上げる。
8. BBC/NHK/ABCのHLS URLを1つずつ試す。
9. 成功/失敗時のSerialログ、codec名、最後に接続したURLを記録する。
10. その後にOLED、ロータリー、Wi-Fi設定、Web設定画面の順で足す。

## 採用候補構成

初期:

- ESP32-S3 PSRAM付き開発ボード。
- MAX98357A I2S Class-D mono amp。
- 4Ωまたは8Ω小型スピーカー。
- 5V USB電源。
- `ESP32-audioI2S`。
- 固定SSID + WNYC固定URL。

次段階:

- SSD1306/SH1106 128x64 I2C OLED。
- KY-040ロータリーエンコーダ。
- 複数局テーブル。
- NVS/LittleFS設定保存。
- SoftAP設定モード。

後回し:

- Web設定画面。
- OTA。
- MQTT。
- SDカード局リスト。
- 起動音/効果音。

## 参考リンク

- `schreibfaul1/ESP32-audioI2S`: https://github.com/schreibfaul1/ESP32-audioI2S
- `ESP32-audioI2S` Wiki: https://github.com/schreibfaul1/ESP32-audioI2S/wiki
- `Edzelf/ESP32Radio-V2`: https://github.com/Edzelf/ESP32Radio-V2
- `Edzelf/ESP32-Radio`: https://github.com/Edzelf/ESP32-Radio
- Adafruit MAX98357A pinouts: https://learn.adafruit.com/adafruit-max98357-i2s-class-d-mono-amp/pinouts
- Espressif Arduino I2S API: https://docs.espressif.com/projects/arduino-esp32/en/latest/api/i2s.html
- `pi_radio` local reference: `D:\data\codex\pi_radio`

## 完了条件

- `docs/esp32_i2s_radio_research.md` に、前例、PSRAM要否、I2S配線、対応形式、局URL見込み、OLED/ロータリー構成、Wi-Fi設定、Web設定画面の要否、`pi_radio`との差分、リスク、最小実験手順が整理されている。
- 実装コードやPlatformIOプロジェクトはまだ作成しない。

## 作業後チェック

- 実装開始を示すファイルが増えていない。
- 秘密情報、Wi-Fiパスワード、APIキーが含まれていない。
- 局URLの確認結果が `PC上のffprobe確認` と `ESP32実機再生確認` で混ざっていない。
- `pi_radio` で確認済みの事実と、`esp_radio` の未確認仮説が区別されている。

## 失敗条件

- PSRAMなしESP32-S3でも確実に動くと断定している。
- HLS/AAC局を実機未確認なのに再生可能と断定している。
- Web設定画面を最小実験の必須要件にしている。
- `pi_radio` のLinux/systemd/NetworkManager前提をESP32へそのまま移植する前提になっている。

## 報告してほしい内容

- どの前例を第一候補にしたか。
- PSRAM付きESP32-S3を推奨する理由。
- 最初に試す局URL。
- 実装前に残っている主なリスク。
- 次回実装に入る場合の最初の作業入口。
