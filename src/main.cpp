#include <Arduino.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <Audio.h>
#include <Fonts/FreeSans12pt7b.h>
#include <Fonts/FreeSans9pt7b.h>
#include <Fonts/FreeSansBold12pt7b.h>
#include <Preferences.h>
#include <WiFi.h>
#include <Wire.h>

#if __has_include("config.local.h")
#include "config.local.h"
#else
#include "config.example.h"
#endif

namespace {

constexpr int I2S_DOUT_PIN = 4;
constexpr int I2S_BCLK_PIN = 5;
constexpr int I2S_LRC_PIN = 6;

constexpr int OLED_SDA_PIN = 8;
constexpr int OLED_SCL_PIN = 9;
constexpr uint8_t OLED_ADDR = 0x3C;
constexpr int OLED_WIDTH = 128;
constexpr int OLED_HEIGHT = 64;

constexpr int ROTARY_CLK_PIN = 10;
constexpr int ROTARY_DT_PIN = 11;
constexpr int ROTARY_SW_PIN = 12;

constexpr uint8_t AUDIO_VOLUME_MIN = 0;
constexpr uint8_t AUDIO_VOLUME_MAX = 21;
constexpr uint8_t AUDIO_VOLUME_INITIAL = 3;
constexpr unsigned long WIFI_CONNECT_TIMEOUT_MS = 15000;
constexpr unsigned long DISPLAY_UPDATE_MS = 750;
constexpr unsigned long BUTTON_DEBOUNCE_MS = 250;
constexpr unsigned long BUTTON_LONG_PRESS_MS = 1500;
constexpr unsigned long AUDIO_RETRY_MS = 15000;
constexpr unsigned long AUDIO_RUNNING_GRACE_MS = 10000;

struct Station {
  const char* name;
  const char* url;
  bool enabled;
};

Station stations[] = {
    {"WNYC FM", "https://fm939.wnyc.org/wnycfm", true},
    {"BBC R4", "https://a.files.bbci.co.uk/ms6/live/3441A116-B12E-4D2F-ACA8-C1984642FA4B/audio/simulcast/hls/nonuk/audio_syndication_low_sbr_v1/cfs/bbc_radio_fourfm.m3u8", true},
    {"ABC", "https://mediaserviceslive.akamaized.net/hls/live/2038310/newsradio/master.m3u8", false},
    {"NHK R1", "https://radio-stream.nhk.jp/hls/live/2023229/nhkradiruakr1/master.m3u8", false},
};

Audio audio;
Preferences wifiPrefs;
Adafruit_SSD1306 display(OLED_WIDTH, OLED_HEIGHT, &Wire, -1);

uint8_t currentVolume = AUDIO_VOLUME_INITIAL;
int currentStation = 0;
bool oledReady = false;
String statusLine = "boot";
String audioLine = "idle";
String wifiSsid = "";
String wifiIp = "";
int lastRotaryClk = HIGH;
unsigned long lastDisplayUpdate = 0;
unsigned long lastButtonAt = 0;
unsigned long lastAudioRetryAt = 0;
unsigned long lastStreamOkAt = 0;
bool streamWasRunning = false;
bool stoppedMode = false;
bool buttonWasPressed = false;
bool longPressHandled = false;
unsigned long buttonPressedAt = 0;

struct WifiCandidate {
  String ssid;
  int32_t rssi = -127;
};

void setStatus(const String& line) {
  statusLine = line;
  Serial.printf("[status] %s\n", statusLine.c_str());
}

void setAudioLine(const String& line) {
  audioLine = line;
  Serial.printf("[audio] %s\n", audioLine.c_str());
}

String readLastSsid() {
  wifiPrefs.begin("wifi", true);
  String ssid = wifiPrefs.getString("last_ssid", "");
  wifiPrefs.end();
  return ssid;
}

void saveLastSsid(const String& ssid) {
  wifiPrefs.begin("wifi", false);
  wifiPrefs.putString("last_ssid", ssid);
  wifiPrefs.end();
}

bool appendUnique(WifiCandidate* candidates, int& count, const String& ssid, int32_t rssi) {
  if (ssid.isEmpty()) {
    return false;
  }

  for (int i = 0; i < count; ++i) {
    if (candidates[i].ssid == ssid) {
      if (rssi > candidates[i].rssi) {
        candidates[i].rssi = rssi;
      }
      return false;
    }
  }

  candidates[count++] = {ssid, rssi};
  return true;
}

void sortByRssiDesc(WifiCandidate* candidates, int count) {
  for (int i = 0; i < count - 1; ++i) {
    for (int j = i + 1; j < count; ++j) {
      if (candidates[j].rssi > candidates[i].rssi) {
        WifiCandidate tmp = candidates[i];
        candidates[i] = candidates[j];
        candidates[j] = tmp;
      }
    }
  }
}

void drawDisplay(bool force = false) {
  if (!oledReady) {
    return;
  }
  if (!force && millis() - lastDisplayUpdate < DISPLAY_UPDATE_MS) {
    return;
  }
  lastDisplayUpdate = millis();

  display.clearDisplay();
  display.setTextColor(SSD1306_WHITE);

  display.setFont(&FreeSansBold12pt7b);
  display.setCursor(0, 22);
  display.print(stations[currentStation].name);

  display.setFont(&FreeSans12pt7b);
  display.setCursor(0, 45);
  if (stoppedMode) {
    display.print("stopped");
  } else {
    display.print("Vol ");
    display.print(currentVolume);
  }

  display.setFont(nullptr);
  display.setTextSize(1);
  display.setCursor(0, 52);
  String stream = audioLine.isEmpty() ? statusLine : audioLine;
  display.print(stream.substring(0, 21));
  display.display();
}

void scanI2c() {
  Serial.println("[i2c] scanning");
  for (uint8_t address = 1; address < 127; ++address) {
    Wire.beginTransmission(address);
    if (Wire.endTransmission() == 0) {
      Serial.printf("[i2c] found 0x%02X\n", address);
    }
  }
}

void setupOled() {
  Wire.begin(OLED_SDA_PIN, OLED_SCL_PIN);
  scanI2c();
  oledReady = display.begin(SSD1306_SWITCHCAPVCC, OLED_ADDR);
  if (!oledReady) {
    Serial.printf("[oled] not found at 0x%02X\n", OLED_ADDR);
    return;
  }
  Serial.printf("[oled] ready at 0x%02X SDA=%d SCL=%d\n", OLED_ADDR, OLED_SDA_PIN, OLED_SCL_PIN);
  display.clearDisplay();
  display.display();
  drawDisplay(true);
}

int buildCandidateOrder(WifiCandidate* ordered, int maxCount) {
  String lastSsid = readLastSsid();
  String preferredSsid = WIFI_PREFERRED_SSID;
  WifiCandidate scanned[32];
  int scannedCount = 0;

  setStatus("wifi scan");
  Serial.printf("[wifi] scanning for SSIDs matching prefix '%s'\n", WIFI_SSID_PREFIX);
  int networkCount = WiFi.scanNetworks();
  Serial.printf("[wifi] scan result: %d networks\n", networkCount);

  for (int i = 0; i < networkCount && scannedCount < 32; ++i) {
    String ssid = WiFi.SSID(i);
    if (!ssid.startsWith(WIFI_SSID_PREFIX)) {
      continue;
    }
    appendUnique(scanned, scannedCount, ssid, WiFi.RSSI(i));
    Serial.printf("[wifi] candidate: %s RSSI=%d\n", ssid.c_str(), WiFi.RSSI(i));
  }

  if (scannedCount == 0) {
    Serial.println("[wifi] no matching SSID found");
    WiFi.scanDelete();
    return 0;
  }

  int orderedCount = 0;

  for (int i = 0; i < scannedCount && orderedCount < maxCount; ++i) {
    if (!lastSsid.isEmpty() && scanned[i].ssid == lastSsid) {
      appendUnique(ordered, orderedCount, scanned[i].ssid, scanned[i].rssi);
      Serial.printf("[wifi] priority last_ssid: %s\n", scanned[i].ssid.c_str());
    }
  }

  for (int i = 0; i < scannedCount && orderedCount < maxCount; ++i) {
    if (!preferredSsid.isEmpty() && scanned[i].ssid == preferredSsid) {
      appendUnique(ordered, orderedCount, scanned[i].ssid, scanned[i].rssi);
      Serial.printf("[wifi] priority preferred: %s\n", scanned[i].ssid.c_str());
    }
  }

  sortByRssiDesc(scanned, scannedCount);
  for (int i = 0; i < scannedCount && orderedCount < maxCount; ++i) {
    appendUnique(ordered, orderedCount, scanned[i].ssid, scanned[i].rssi);
  }

  WiFi.scanDelete();
  return orderedCount;
}

bool connectToSsid(const String& ssid) {
  setStatus("wifi connect");
  Serial.printf("[wifi] connecting to %s\n", ssid.c_str());
  WiFi.begin(ssid.c_str(), WIFI_PASSWORD);

  unsigned long startedAt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startedAt < WIFI_CONNECT_TIMEOUT_MS) {
    delay(250);
    Serial.print('.');
    drawDisplay();
  }
  Serial.println();

  if (WiFi.status() != WL_CONNECTED) {
    Serial.printf("[wifi] failed: %s\n", ssid.c_str());
    WiFi.disconnect(true, true);
    delay(500);
    return false;
  }

  wifiSsid = ssid;
  wifiIp = WiFi.localIP().toString();
  Serial.printf("[wifi] connected: %s IP=%s RSSI=%d\n", ssid.c_str(), wifiIp.c_str(), WiFi.RSSI());
  saveLastSsid(ssid);
  setStatus("wifi ok");
  drawDisplay(true);
  return true;
}

bool connectWifi() {
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);
  WiFi.disconnect(true, true);
  delay(500);

  WifiCandidate ordered[32];
  int orderedCount = buildCandidateOrder(ordered, 32);
  for (int i = 0; i < orderedCount; ++i) {
    if (connectToSsid(ordered[i].ssid)) {
      return true;
    }
  }

  return false;
}

void printBoardInfo() {
  Serial.println();
  Serial.println("=== esp32_radio playback test ===");
  Serial.printf("[board] chip model: %s rev %d\n", ESP.getChipModel(), ESP.getChipRevision());
  Serial.printf("[board] CPU freq: %u MHz\n", ESP.getCpuFreqMHz());
  Serial.printf("[board] flash size: %u bytes\n", ESP.getFlashChipSize());
  Serial.printf("[board] PSRAM size: %u bytes free=%u\n", ESP.getPsramSize(), ESP.getFreePsram());
  Serial.printf("[i2s] DOUT=%d BCLK=%d LRC=%d\n", I2S_DOUT_PIN, I2S_BCLK_PIN, I2S_LRC_PIN);
  Serial.printf("[oled] SDA=%d SCL=%d addr=0x%02X\n", OLED_SDA_PIN, OLED_SCL_PIN, OLED_ADDR);
  Serial.printf("[rotary] CLK=%d DT=%d SW=%d\n", ROTARY_CLK_PIN, ROTARY_DT_PIN, ROTARY_SW_PIN);
}

void startAudio() {
  if (stoppedMode) {
    setStatus("stopped");
    setAudioLine("wifi off");
    drawDisplay(true);
    return;
  }
  Station& station = stations[currentStation];
  if (!station.enabled) {
    setStatus("select only");
    setAudioLine("not tested");
    Serial.printf("[audio] station disabled for now: %s\n", station.name);
    drawDisplay(true);
    return;
  }
  setStatus("audio start");
  setAudioLine("tuning...");
  Serial.printf("[audio] station: %s\n", station.name);
  Serial.printf("[audio] url: %s\n", station.url);
  audio.setVolume(currentVolume);
  bool started = audio.connecttohost(station.url);
  Serial.printf("[audio] connecttohost result=%s\n", started ? "true" : "false");
  lastAudioRetryAt = millis();
  lastStreamOkAt = started ? millis() : 0;
  streamWasRunning = false;
  drawDisplay(true);
}

void changeStation(int direction) {
  int stationCount = static_cast<int>(sizeof(stations) / sizeof(stations[0]));
  currentStation = (currentStation + direction + stationCount) % stationCount;
  Serial.printf("[station] selected %d: %s\n", currentStation, stations[currentStation].name);
  if (stoppedMode) {
    setStatus("stopped");
    setAudioLine("wifi off");
    drawDisplay(true);
    return;
  }
  if (audio.isRunning()) {
    audio.stopSong();
  }
  startAudio();
}

void enterStoppedMode() {
  if (stoppedMode) {
    return;
  }
  Serial.println("[control] entering stopped mode");
  if (audio.isRunning()) {
    audio.stopSong();
  } else {
    audio.stopSong();
  }
  WiFi.disconnect(false);
  WiFi.mode(WIFI_OFF);
  stoppedMode = true;
  streamWasRunning = false;
  lastStreamOkAt = 0;
  setStatus("stopped");
  setAudioLine("wifi off");
  drawDisplay(true);
}

void exitStoppedMode() {
  if (!stoppedMode) {
    return;
  }
  Serial.println("[control] leaving stopped mode");
  stoppedMode = false;
  setStatus("wifi resume");
  setAudioLine("wake...");
  drawDisplay(true);
  if (!connectWifi()) {
    stoppedMode = true;
    setStatus("stopped");
    setAudioLine("wifi failed");
    drawDisplay(true);
    return;
  }
  startAudio();
}

bool wakeIfStopped() {
  if (!stoppedMode) {
    return false;
  }
  exitStoppedMode();
  return true;
}

void setVolume(uint8_t volume) {
  currentVolume = constrain(volume, AUDIO_VOLUME_MIN, AUDIO_VOLUME_MAX);
  if (!stoppedMode) {
    audio.setVolume(currentVolume);
  }
  Serial.printf("[volume] %u\n", currentVolume);
  drawDisplay(true);
}

void pollRotary() {
  int clk = digitalRead(ROTARY_CLK_PIN);
  if (clk != lastRotaryClk && clk == LOW) {
    if (wakeIfStopped()) {
      lastRotaryClk = clk;
      return;
    }
    int dt = digitalRead(ROTARY_DT_PIN);
    if (dt != clk && currentVolume < AUDIO_VOLUME_MAX) {
      setVolume(currentVolume + 1);
    } else if (dt == clk && currentVolume > AUDIO_VOLUME_MIN) {
      setVolume(currentVolume - 1);
    }
  }
  lastRotaryClk = clk;

  bool buttonPressed = digitalRead(ROTARY_SW_PIN) == LOW;
  unsigned long now = millis();

  if (buttonPressed && !buttonWasPressed) {
    buttonWasPressed = true;
    longPressHandled = false;
    buttonPressedAt = now;
  }

  if (buttonPressed && !longPressHandled && now - buttonPressedAt >= BUTTON_LONG_PRESS_MS) {
    longPressHandled = true;
    lastButtonAt = now;
    if (stoppedMode) {
      exitStoppedMode();
    } else {
      enterStoppedMode();
    }
  }

  if (!buttonPressed && buttonWasPressed) {
    buttonWasPressed = false;
    if (!longPressHandled && now - lastButtonAt > BUTTON_DEBOUNCE_MS) {
      lastButtonAt = now;
      if (wakeIfStopped()) {
        return;
      }
      changeStation(1);
    }
  }
}

void maybeRetryAudio() {
  if (stoppedMode || !stations[currentStation].enabled) {
    return;
  }
  if (audio.isRunning()) {
    if (!streamWasRunning) {
      setAudioLine("stream ok");
      streamWasRunning = true;
    }
    lastStreamOkAt = millis();
    return;
  }
  if (streamWasRunning && millis() - lastStreamOkAt > AUDIO_RUNNING_GRACE_MS) {
    setAudioLine("stream lost");
    streamWasRunning = false;
  }
  if (millis() - lastAudioRetryAt < AUDIO_RETRY_MS) {
    return;
  }
  setStatus("audio retry");
  startAudio();
}

void myAudioInfo(Audio::msg_t msg) {
  Serial.printf("[%s] %s\n", msg.s, msg.msg);
  if (strcmp(msg.s, "info") == 0 && strstr(msg.msg, "stream ready") != nullptr) {
    audioLine = "stream ok";
    lastStreamOkAt = millis();
    streamWasRunning = true;
  } else if (strcmp(msg.s, "station_name") == 0 || strcmp(msg.s, "streamtitle") == 0) {
    audioLine = "stream ok";
    lastStreamOkAt = millis();
  }
}

}  // namespace

void setup() {
  Serial.begin(115200);
  delay(1000);

  Audio::audio_info_callback = myAudioInfo;
  pinMode(ROTARY_CLK_PIN, INPUT_PULLUP);
  pinMode(ROTARY_DT_PIN, INPUT_PULLUP);
  pinMode(ROTARY_SW_PIN, INPUT_PULLUP);
  lastRotaryClk = digitalRead(ROTARY_CLK_PIN);

  printBoardInfo();
  setupOled();
  audio.setPinout(I2S_BCLK_PIN, I2S_LRC_PIN, I2S_DOUT_PIN);
  audio.setVolume(currentVolume);

  if (!connectWifi()) {
    setStatus("wifi failed");
    drawDisplay(true);
    Serial.println("[wifi] no connection; restarting in 10 seconds");
    delay(10000);
    ESP.restart();
  }

  startAudio();
}

void loop() {
  if (!stoppedMode) {
    audio.loop();
  }
  pollRotary();
  maybeRetryAudio();
  drawDisplay();
}
