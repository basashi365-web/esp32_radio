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
2. Windowsでは現在 `COM24` として見えている。接続前に毎回COMポートは再確認する。
3. `ESP.getPsramSize()` をSerialに出す最小スケッチを作る。
4. MAX98357Aを `GPIO4/5/6` 仮配線で接続する。
5. 53mm / 4Ω / 3W フルレンジスピーカーをMAX98357Aの `SPK+` / `SPK-` へ接続する。
6. WNYC `https://fm939.wnyc.org/wnycfm` を `audio.connecttohost()` で再生する。
7. 音量は低めから開始する。
8. Serialログに接続先、codec、エラー、再接続状況を出す。

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
