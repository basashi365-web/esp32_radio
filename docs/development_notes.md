# Development Notes

## 2026-05-30

- `esp32_radio` を `pi_radio` 派生の本格プロジェクトとして扱う方針になった。
- 実装前に `docs/esp32_i2s_radio_research.md` を作成した。
- 最小実験の第一候補は `schreibfaul1/ESP32-audioI2S`。
- PSRAM付きESP32-S3を前提にする。
- WNYCはMP3直ストリームとして最初に試す。
- BBC Radio 4 / ABC NewsRadio / NHK R1 はPC上の `ffprobe` でHLS/AAC音声として検出できたが、ESP32実機再生は未確認。
- Web設定画面は初期実験には入れず、再生安定後の追加候補にする。
- 表示器は `pi_radio` と同じ GM009606v4.3 OLED を使う方針。`SSD1306 128x64 / I2C 0x3C` として扱う。
- 友人へ渡す将来構想として、ESP32-S3のUSB MSC設定モードでPCから `WIFI.TXT` / `STATIONS.TXT` を編集する方式を最後に試す候補へ追加した。
- スピーカーは購入済みの2インチ級 / 53mm / 4Ω / 3Wフルレンジスピーカーを使う。商品画像上の寸法は正面外形約52.6mm、直径53mm、高さ30mm。

## 次回作業入口

1. PlatformIO/Arduino側でPSRAM容量を確認する。
2. 53mm / 4Ω / 3WスピーカーをMAX98357Aへ接続する。
3. `platformio.ini` のボード/PSRAM設定が実機に合うか確認する。
4. MAX98357A + WNYC の最小再生スケッチをCOM24へ書き込む。
5. Serialログと実機結果をこのdocsへ追記する。
6. 再生とOLED/ロータリーが安定した後、USB MSC TXT設定モードを調査する。

## 2026-06-01 実機接続メモ

- ESP32-S3 N16R8 dev board はWindows上で `COM24` として見えている。COMポートは接続順で変わるため、実験前に再確認する。
- Wi-Fiは固定SSIDではなく、ローカル設定のSSID prefixで候補を絞る。
- 複数SSIDがある環境では、単純なRSSI最強ではなく、前回成功SSIDをESP32 Arduino `Preferences` に保存して次回起動時に優先する。
- 接続成功SSIDは `Preferences` namespace `wifi` / key `last_ssid` に保存する設計にする。
- 実パスワードは `include/config.local.h` のみに置き、repoやAI Docsへ入れない。
- PlatformIO最小プロジェクトを追加した。`src/main.cpp` はPSRAM/Flash情報をSerialへ出し、SSID prefix一致候補から前回成功SSIDを優先してWi-Fi接続し、WNYCをMAX98357AへI2S出力する初期スケッチ。
- 標準PlatformIO `espressif32` では `ESP32-audioI2S` 3.4.6 が `<span>` を要求してビルド失敗したため、`pioarduino/platform-espressif32` stableへ切り替えた。
- `ESP32-audioI2S` 3.4.6 の `Audio.h` が `std::optional` を使うが `<optional>` を直接includeしていないため、`platformio.ini` の `build_flags` で `-I include` と `-include optional` を追加した。Cファイルにも同じflagが当たるため、`include/optional` にC++時だけ本物の標準ヘッダへ渡す小さなshimを置いた。
- USBケーブル交換後、`pio run -t upload` がCOM24へ成功した。低速 `upload_speed = 115200` と `PYTHONIOENCODING=utf-8` / `PYTHONUTF8=1` を使うとPlatformIOの進捗文字によるcp932例外を避けやすい。
- SerialログでESP32-S3 rev 2、Flash 16MB、PSRAM 8MBを確認した。
- Wi-Fiはprefix一致候補を見つけ、`Preferences` の前回成功SSID優先で接続成功した。
- OLEDとKY-040が接続済みになったため、初期スケッチへSSD1306 OLED表示、I2C scan、KY-040音量変更、短押し局送りを追加した。
- 実機ログでOLEDはI2C `0x3C` として検出できた。
- WNYCはSSL接続、MP3Decoder初期化、`stream ready`、MPEG-1 Layer III / 32kHz / 96kbps まで確認できた。実音声はスピーカー側で要耳確認。
- KY-040の回転で音量変更ログを確認できた。短押し局送りもログ上は動いている。
- BBC Radio 4の旧HLS URLは実機で `HTTP/1.1 410 Gone`。2026-06-02時点で見つかるnon-UK向けHLS URLへ差し替えた。
- NHK R1は候補URLでDNS失敗が一度出た。再テストが必要。
- 2026-06-02: KY-040の音量表示は素直に反応。ABC Newsへ移動したところで長時間ブロックし、その後NHKへ移ったとの実機報告あり。音出しが終わるまでHLS局は局送り対象から外し、WNYCだけを有効化する。
- スピーカーから音が出ていない。GAINはオープンで問題なし。SD/MODEもオープンだったため、まずSD/MODEを3.3Vへ接続して強制ONで確認する。
- OLED表示は、局名を上半分の大きい文字、音量を中くらい、ストリーム/IP状態を最下段の小さい文字に変更した。
- OLEDの局名/音量表示をAdafruit GFXのFreeSans系フォントへ変更した。白黒OLEDなので本当のアンチエイリアスはないが、デフォルトフォントより読みやすい字形にする。
- 最下段は `bitrate...` などの内部イベント名を出さず、再生準備ができたら `stream ok` を出す。
- WNYCが時々無音になるとの報告。ログ上は `slow stream, dropouts are possible` が出ていたため、ストリーム停止/再接続とアンプ側無音を切り分ける必要がある。`audio.isRunning()` を監視し、停止が続く場合はOLED下段に `stream lost`、再接続時は `stream ok` を出す。
- OLEDフォントはFreeSans系で確定。最下段は内部イベント名を出さず、人間向けの `tuning...` / `stream ok` / `stream lost` / `not tested` だけにする。
- KY-040クリックは選曲操作にする。未検証局は局名表示だけ切り替え、再生は開始しないことでABC/NHKの長時間ブロックを避ける。
- BBC Radio 4はBBCだけ有効化した実機テストで音出しOK。WNYCのMP3直ストリームだけでなく、少なくともBBCのHLS入口はESP32-S3 + ESP32-audioI2S + MAX98357A構成で再生できる。
- 次は同じ手順でABC NewsRadioだけを追加有効化し、フリーズ/無音/`stream ok` を確認する。
- ABC NewsRadioは `stream ok` までは到達。ただし実音声は出なかった。深夜帯の無音、局側の番組状態、またはHLS/AACの音声処理差を疑い、後日別時間帯でも再確認する。
- 次はNHK R1を追加有効化し、同じく `stream ok` と実音声を切り分ける。
- ABC表示中にクリックすると、次局へ移るまで約10秒停止する。NHK R1は `tuning...` で止まり、その後クリック/音量操作も効かない完全フリーズへ進んだ。初期常用版ではABC/NHKを再び無効化し、WNYC/BBCだけを有効局にする。
- ABC/NHKは夜間の局側状態だけでなく、`audio.connecttohost()` またはHLS処理がブロックしてUIループを止めるリスクがある。再検証は別時間帯に、まずSerialログを取りながら1局ずつ行う。
- 2026-06-02朝にABC/NHKを再度有効化して実機確認した。ABCは音が出ず、10秒以上フリーズする。NHKも音が出ず、最終的に完全フリーズする。時間帯だけの問題ではなく、ESP32側の接続/デコード処理がUIループを巻き込む問題として扱う。
- 常用版はWNYC/BBCのみ有効、ABC/NHKは `not tested` 表示だけに戻す。ABC/NHKを再検証する場合は、同期的な `audio.connecttohost()` を直接UIループで呼ばない設計、またはタイムアウト/別タスク化を先に検討する。

## 音質検討メモ

- `pi_radio` と比べると `esp32_radio` は少し音が悪い気がしたが、現時点では決定的な差とは判断しない。
- 同じスピーカーを流用しているため、主な差分要因は MAX98357A、5V/GND配線、電源安定性、ESP32側のWi-Fi/デコード負荷、I2S処理まわりと考える。
- MAX98357Aの `SD/MODE` を3.3Vへ接続したら音が出た。`SD/MODE` オープンは今回の無音原因だった可能性が高い。
- `GAIN` はオープンでよい。音割れやノイズが出た場合だけ、GAIN設定、ソフト音量、電源容量を見直す。
- `PCM5102A + PAM8403` は音質改善候補。ただし部品、配線、電源、筐体内スペース、コストが増え、今回はチリツモになるため保留する。
- 現時点では MAX98357A 構成を採用継続する。
- 音質改善はまず、筐体、スピーカー固定、5V/GND配線の太さ/短さ、電源安定化、I2S配線の取り回しから見る。
- WNYCの無音化は、OLED下段表示とSerialログで `stream` 側か I2S/アンプ側かを切り分ける。`stream ok` のまま無音ならI2S/アンプ/電源側、`stream lost` や再接続表示ならネットワーク/ストリーム側を疑う。

## 通信停止/待機メモ

- スマホのテザリング利用時に消し忘れで通信し続けるのを避けるため、KY-040長押しでESP32向けの停止状態へ入る。
- 停止時は `audio.stopSong()`、`WiFi.disconnect(false)`、`WiFi.mode(WIFI_OFF)` を行い、OLEDの音量表示位置に `stopped`、下段に `wifi off` を表示する。
- 停止中は `audio.loop()` と自動リトライを止める。
- 停止中にKY-040を回す、または押すと復帰する。復帰操作そのものは音量変更や局送りには使わず、まずWi-Fi再接続と現在局の再生を試す。
- これは `pi_radio` のshutdownではなく、ESP32版の通信停止/待機機能として扱う。
- 実機で長押し停止と、KY-040を回す/押す操作による復帰が成功した。

## 記録ルール

- 実機で確認したことは、未確認仮説と分けて書く。
- Wi-Fiパスワード、トークン、APIキーは書かない。
- 放送局URLは変更される可能性があるため、確認日を書く。
- `pi_radio` から再利用した設計と、ESP32用に変えた設計を分ける。
