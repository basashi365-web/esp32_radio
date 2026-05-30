# USB MSC TXT Configuration Plan

作成日: 2026-05-30

## 目的

`esp32_radio` を友人へ渡したあと、PCとUSBケーブルで接続して `WIFI.TXT` や `STATIONS.TXT` を書き換えられる構成を将来候補にする。

初期実験ではWi-Fi SSID/passwordをコードまたはローカル専用設定ファイルに書く。再生確認ができた後、ESP32-S3のネイティブUSB Device機能を使い、設定モード時だけ小さなUSB Mass StorageとしてPCに見せる方式を検討する。

## 結論

- ESP32-S3 N16R8なら実験候補として現実的。
- ESP32-WROOM-32Eでは基本的に不可。USB端子はUSB-シリアル変換チップ経由で、PCからはCOMポートに見えるだけ。
- 最初から実装せず、音声再生、OLED表示、ロータリー操作が安定してから後段で試す。
- 安全のため、PCにUSBドライブとして見せるのは専用の設定モード中だけにする。

## 想定UX

```text
1. 電源OFF
2. 設定ボタンを押しながらUSB接続、またはロータリー長押しで設定モード起動
3. PCに `ESP_RADIO` のような小さいUSBドライブが表示される
4. `WIFI.TXT` と `STATIONS.TXT` を編集する
5. PC側で取り外し操作をする
6. ESP32-S3を再起動する
7. 起動時にTXTを読み、NVS/LittleFS側の運用設定へ反映する
```

## 設定ファイル案

### WIFI.TXT

```text
ssid=YOUR_WIFI_NAME
password: YOUR_WIFI_PASSWORD
hostname=esp-radio
```

注意:

- `WIFI.TXT` はローカル設定用で、GitHubへ入れない。
- 配布用repoには `WIFI.EXAMPLE.TXT` だけ置く。
- 実機上の設定ファイルは秘密情報なので、ログやOLEDにpasswordを出さない。

### STATIONS.TXT

```text
WNYC FM|https://fm939.wnyc.org/wnycfm
BBC Radio 4|https://example.invalid/bbc-radio-4.m3u8
NHK R1|https://example.invalid/nhk-r1.m3u8
```

注意:

- 実際の放送局URLは変わる可能性がある。
- HLS/AAC局はESP32実機で再生できるか確認してから配布候補にする。
- 1行1局、`局名|URL` の単純形式にすると、人間が編集しやすい。

## 実装方針

### Phase 1: 通常設定

- `include/config.local.h` など、git除外ファイルにWi-Fi情報を書く。
- WNYC固定URLで再生確認する。

### Phase 2: 内部保存

- NVSまたはLittleFSに設定を保存する。
- 起動時に設定がなければデフォルト局だけで起動する。

### Phase 3: USB MSC設定モード

- ESP32-S3のTinyUSB / USB MSC機能を調査する。
- FATの小さな設定領域をPCへ見せる。
- PCがマウントしている間は、ESP32側はその領域を同時に読み書きしない。
- 設定モードを抜けたあと、TXTを検証してNVS/LittleFSへ反映する。

## 競合・破損対策

USB Mass Storageは、PCがブロックデバイスとしてファイルシステムを触る。ESP32側も同時に同じ領域を読み書きすると破損リスクがある。

安全策:

- 設定モード中はラジオ再生しない。
- 設定モード中はESP32側から設定領域へ書かない。
- PC側の取り外し後、または再起動後に設定を読む。
- 読み込む前にTXT形式を検証する。
- 不正な設定なら前回の有効設定を維持する。

## OLED表示

設定モード時は、`pi_radio` と同じOLEDに状態を出す。

想定表示:

```text
USB CONFIG
EDIT TXT FILES
EJECT + RESET
```

通常起動時:

```text
ESP RADIO
WIFI...
```

設定読み込み失敗時:

```text
CONFIG ERROR
WIFI.TXT
```

## 参考

- ESP-IDF USB Device Stack / TinyUSB: https://docs.espressif.com/projects/esp-idf/en/stable/esp32s3/api-reference/peripherals/usb_device.html
- Espressif USB FAQ / USB MSC: https://documentation.espressif.com/projects/esp-faq/en/latest/software-framework/peripherals/usb.html

## 完了条件

- 初期実験では実装しない将来候補として明確に分離されている。
- WROOM-32EではなくESP32-S3 N16R8向けの案として書かれている。
- PC接続中の同時書き込みリスクと、設定モード限定の方針が明記されている。
- `WIFI.TXT` などの秘密情報をGitHubへ入れない方針が明記されている。
