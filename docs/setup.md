# Setup Notes

## 現在の段階

実装前。次回は最小再生実験から始める。

## 開発環境候補

- PlatformIO
- Arduino IDE
- Arduino framework for ESP32
- `schreibfaul1/ESP32-audioI2S`

PlatformIOで始める場合、秘密情報は `include/config.local.h` などgit対象外ファイルへ分離する。

## 最小実験の入口

1. ESP32-S3ボードの型番とPSRAM容量を確認する。
2. `ESP.getPsramSize()` をSerialに出す最小スケッチを作る。
3. MAX98357Aを `GPIO4/5/6` 仮配線で接続する。
4. WNYC `https://fm939.wnyc.org/wnycfm` を `audio.connecttohost()` で再生する。
5. 音量は低めから開始する。
6. Serialログに接続先、codec、エラー、再接続状況を出す。

## Wi-Fi設定

初期実験では固定SSID/passwordを使う。ただし値はrepoへ入れない。

推奨:

- `include/config.local.h` にローカルSSID/passwordを置く。
- `include/config.example.h` にはダミー値だけ置く。
- `.gitignore` で `config.local.h` を除外する。

## 友人配布向けの設定構想

友人へ渡す段階では、コードを書き換えなくてもWi-Fiと局URLを変えられるようにしたい。

候補:

1. SoftAP + Web設定画面。
2. ESP32-S3のUSB MSC設定モードで、PCから `WIFI.TXT` / `STATIONS.TXT` を編集する。

現時点では、USB MSC方式を「最後に試す面白い構想」として残す。詳細は `docs/usb_msc_config_plan.md` を参照する。

## Web設定画面

初期実験では作らない。

理由:

- まず音声再生とHLS/AAC可否を切り分ける。
- Web設定、DNS、NVS保存を同時に入れると原因切り分けが難しくなる。

追加するなら、WNYC/BBC/NHK/ABCの再生確認後にSoftAP + Web設定、またはUSB MSC TXT設定モードとして設計する。
