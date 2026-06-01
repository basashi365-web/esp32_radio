# Setup Notes

## 現在の段階

PlatformIO初期ファームウェア作成済み。COM24への書き込み、OLED表示、KY-040操作、WNYC音出しまで実機確認済み。

## 開発環境候補

- PlatformIO
- Arduino IDE
- Arduino framework for ESP32
- `schreibfaul1/ESP32-audioI2S`

PlatformIOで始める場合、秘密情報は `include/config.local.h` などgit対象外ファイルへ分離する。

このrepoでは `platformio.ini` の `esp32_s3_n16r8` 環境を初期実験用にする。

- Board base: `esp32-s3-devkitc-1`
- Flash: 16MB想定
- PSRAM: N16R8相当として `qio_opi` / `BOARD_HAS_PSRAM`
- Upload/monitor port: `COM24`
- Upload speed: `115200`。USB接続の安定確認を優先し、初期実験では高速化しない。
- Audio library: `schreibfaul1/ESP32-audioI2S`
- Display library: `Adafruit SSD1306` / `Adafruit GFX Library`
- Platform: `pioarduino/platform-espressif32` stable package。`ESP32-audioI2S` 3.x がC++20系のヘッダを使うため、標準のPlatformIO `espressif32` より新しいArduino-ESP32 3系相当を使う。
- Build workaround: `ESP32-audioI2S` 3.4.6 の `<optional>` include漏れを避けるため `-I include` と `-include optional` を指定する。Cファイルにもflagが当たるため、`include/optional` のshimでC++時だけ標準 `<optional>` へ渡す。

## 最小実験の入口

1. Windowsでは現在 `COM24` として見えている。接続前に毎回COMポートは再確認する。
2. MAX98357Aを `GPIO4/5/6` 仮配線で接続する。
3. 53mm / 4Ω / 3W フルレンジスピーカーをMAX98357Aの `SPK+` / `SPK-` へ接続する。
4. `pio run -t upload` で最小スケッチを書き込む。
5. `pio device monitor -p COM24 -b 115200` でSerialログを見る。
6. OLEDに `esp32_radio`、局名、音量、状態、IPが出るか確認する。
7. KY-040の回転で音量、短押しで局送りが動くか確認する。
8. `ESP.getPsramSize()` / Flash size / Wi-Fi接続先 / codec / エラー / 再接続状況をSerialで確認する。
9. WNYC `https://fm939.wnyc.org/wnycfm` の音が出るか確認する。SD/MODEを3.3Vへ接続した状態で音出し確認済み。
10. 音量は低めから開始する。

## 2026-06-02 実機ログメモ

- COM24への書き込みは、USBケーブル交換後に成功した。
- ESP32-S3 rev 2、Flash 16MB、PSRAM 8MBをSerialで確認済み。
- OLEDはI2C scanで `0x3C` を検出し、SSD1306として初期化成功。
- WNYCはSSL接続、MP3デコード初期化、`stream ready` まで確認。
- BBC Radio 4の旧HLS URLは `410 Gone` になったため、局URLを差し替えた。
- NHK R1はDNS失敗が一度出たため再確認する。
- ABC News / NHK R1 などのHLS局は、接続中に操作が長く止まることがあるため、初期音出しが終わるまではWNYCだけを局送り対象にする。
- MAX98357AのGAINはオープンでよい。SD/MODEはオープンにせず、初期確認では3.3Vへ接続してアンプをONにする。
- OLED表示は、上半分を局名の大きい表示、中央を中サイズの音量表示、最下段を小さいストリーム/IP状態表示にする。
- OLEDの局名/音量はFreeSans系フォントを使う。最下段は小さいデフォルトフォントのまま、`stream ok` など短い状態だけを出す。
- WNYCが無音になる場合、OLED下段が `stream ok` のままならI2S/アンプ/電源側、`stream lost` や再接続表示ならネットワーク/ストリーム側を疑う。
- KY-040クリックは選曲。未検証局は `not tested` と表示し、WNYC以外のHLS局は音出し安定まで自動接続しない。
- BBC Radio 4は、WNYCの次に有効化した実機テストで音出しOK。
- ABC NewsRadioは `stream ok` まで到達したが無音。深夜帯の局側状態もあり得るため、別時間帯で再確認する。
- ABC/NHKを有効化すると選局時に長時間停止または完全フリーズすることがある。常用確認版ではWNYC/BBCのみ有効化し、ABC/NHKは `not tested` 表示だけにする。
- KY-040長押しで通信停止/待機へ入る。停止中はOLEDの音量表示位置に `stopped`、下段に `wifi off` を出し、Wi-FiをOFFにする。KY-040を回す、または押すと復帰する。実機確認済み。

## Wi-Fi設定

初期実験では、SSIDを固定文字列で決め打ちしない。
同じ家・同じ用途で複数SSIDがあるため、ローカル設定に入れたSSID prefixだけを候補にし、ESP32 Arduinoの `Preferences` で前回接続に成功したSSIDをNVSへ保存する。

推奨:

- `include/config.local.h` にローカルSSID prefix/passwordを置く。
- `include/config.example.h` にはダミー値だけ置く。
- `.gitignore` で `config.local.h` を除外する。
- 接続成功したSSIDは `Preferences` namespace `wifi` の `last_ssid` に保存する。

接続候補の優先順位:

1. 周囲のSSIDを `WiFi.scanNetworks()` で走査する。
2. 設定したprefixで始まるSSIDだけを候補にする。
3. NVSに保存された前回成功SSIDが見つかれば最優先する。
4. 見つからなければ、設定済みの優先SSIDを見る。
5. それもなければ、prefix一致SSIDのうちRSSIが一番強いものを選ぶ。
6. 接続に成功したSSIDを再び `last_ssid` として保存する。

実装時の要点:

```cpp
Preferences wifiPrefs;

wifiPrefs.begin("wifi", true);
String lastSsid = wifiPrefs.getString("last_ssid", "");
wifiPrefs.end();

int networkCount = WiFi.scanNetworks();
```

```cpp
wifiPrefs.begin("wifi", false);
wifiPrefs.putString("last_ssid", connectedSsid);
wifiPrefs.end();
```

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
