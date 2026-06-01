#pragma once

// Copy this file to include/config.local.h and fill local-only values.
// Do not commit config.local.h.

static constexpr const char* WIFI_SSID_PREFIX = "YOUR_WIFI_PREFIX";
static constexpr const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Optional. Leave empty to let the firmware use the last successful SSID first,
// then the strongest SSID matching WIFI_SSID_PREFIX.
static constexpr const char* WIFI_PREFERRED_SSID = "";
