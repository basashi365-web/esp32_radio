# Troubleshooting Notes

## PSRAMが見えない

症状:

- 起動ログでPSRAM容量が0。
- `ESP32-audioI2S` の初期化や再生中にクラッシュする。

確認:

- ボード型番にPSRAMがあるか。
- PlatformIO/Arduinoのボード設定がPSRAM有効になっているか。
- `ESP.getPsramSize()` の値。

## WNYCが鳴らない

確認:

- Wi-Fi接続できているか。
- IPアドレスが出ているか。
- `https://fm939.wnyc.org/wnycfm` へ接続ログが出ているか。
- 音量が0ではないか。
- MAX98357Aの `DIN/BCLK/LRC` が逆になっていないか。
- スピーカーを `SPK+` / `SPK-` に接続しているか。

## BBC / ABC / NHK R1 が鳴らない

原因候補:

- HLS `.m3u8` の処理に失敗。
- HTTPS/TLSやリダイレクトで失敗。
- 放送局側URLが変わった。
- セグメント取得中にバッファ不足。

切り分け:

- WNYC MP3直ストリームが鳴る状態で1局ずつ試す。
- Serialログの最後のURL、HTTP status、codec表示を見る。
- 可能ならPCの `ffprobe` で同日URLを再確認する。

## ノイズ・音割れ

確認:

- ソフト音量を下げる。
- MAX98357AのGAIN設定を下げる。
- 5V電源の電流容量を確認する。
- I2S配線を短くする。
- GNDを共通化する。

## OLED追加後に音が途切れる

原因候補:

- 描画更新が頻繁すぎる。
- I2C処理が音声loopを邪魔している。
- Serialログや画面更新が多すぎる。

対策:

- OLED更新を1秒に1回程度へ制限する。
- 音声処理loopを止めない。
- 表示内容を最小限にする。
