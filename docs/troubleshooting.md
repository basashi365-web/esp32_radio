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

## WNYCがstream okなのに無音になる

確認:

- OLED下段が `stream ok` のままなら、ストリーム取得より後段のI2S/アンプ/電源側を疑う。
- OLED下段が `stream lost`、`tuning...`、再接続表示へ変わるなら、Wi-Fi、DNS、局側ストリーム、`audio.connecttohost()` のブロックを疑う。
- Serialログで codec / bitrate / slow stream / reconnect の有無を見る。
- MAX98357Aの `SD/MODE` が3.3Vへ接続されているか確認する。オープンは無音原因になり得る。
- `GAIN` はオープンでよい。まずはソフト音量、5V/GND配線、電源容量、スピーカー固定を確認する。

## 音質がpi_radioより少し悪く感じる

確認:

- 現時点では決定的な差とは判断しない。
- 同じスピーカーを使っているため、差分要因は MAX98357A、ESP32側の負荷、5V/GND配線、電源安定性、筐体/スピーカー固定を優先して見る。
- `PCM5102A + PAM8403` は音質改善候補だが、今回は部品と配線とコストが増えるため保留する。
- まずはMAX98357A構成のまま、筐体、固定、配線、電源で改善余地を見る。

## OLED追加後に音が途切れる

原因候補:

- 描画更新が頻繁すぎる。
- I2C処理が音声loopを邪魔している。
- Serialログや画面更新が多すぎる。

対策:

- OLED更新を1秒に1回程度へ制限する。
- 音声処理loopを止めない。
- 表示内容を最小限にする。
