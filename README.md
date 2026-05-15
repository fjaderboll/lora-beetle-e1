# LoRa environment sensor

* LoRaWAN implementation
* Measures:
	* Temperature
	* Humidity
	* Pressure
	* Light
* Rechargable battery (via USB)
* Weather proof case

# Hardware components
* [CubeCell HTCC-AB01](https://docs.heltec.cn/en/node/asr650x/htcc_ab01/) with antenna
* BME280 (temperature, humidity, pressure sensor)
* BH1750 (light sensor)
* Lithium-ion battery 3.7V
* Battery holder
* Circuit board
* Case

# Software setup
1. Create your own set of keys:
	```shell
	cp keys.h.default keys.h
	```
2. Setup *Arduino IDE*: https://docs.heltec.org/en/node/asr650x/asr650x_general_docs/quick_start/index.html
3. Open this project and select board `CubeCell-Board (HTCC-AB01)` (use V2 if your CubeCell has a USB-C)
4. Install the following libraries via the Arduino *Library Manager*:
	* `Adafruit BME280 Library` (pulls in `Adafruit Unified Sensor`)
	* `BH1750` by Christopher Laws
5. In the *Tools* menu, configure:
	* `LORAWAN_REGION`     : your region (e.g. `REGION_EU868`)
	* `LORAWAN_CLASS`      : `CLASS_A`
	* `LORAWAN_NETMODE`    : `OTAA`
	* `LORAWAN_ADR`        : `ON`
	* `LORAWAN_UPLINKMODE` : `UNCONFIRMED`
	* `LORAWAN_NET_RESERVE`: `ON` (keep network state across deep sleep)
6. Fill in your `DevEUI`, `AppEUI` (a.k.a. `JoinEUI`) and `AppKey` in `keys.h`,
   then flash the board.

# Uplink payload

Sent on `port 2`, 11 bytes, big-endian:

| Bytes | Field        | Encoding              | Example          |
|-------|--------------|-----------------------|------------------|
| 0..1  | Temperature  | `int16`,  value × 100 | `2345`  → 23.45 °C |
| 2..3  | Humidity     | `uint16`, value × 100 | `5012`  → 50.12 % |
| 4..5  | Pressure     | `uint16`, value × 10  | `10132` → 1013.2 hPa |
| 6..9  | Light (lux)  | `uint32`, value × 100 | `12345` → 123.45 lx |
| 10    | Battery      | `uint8`, CubeCell `BoardGetBatteryLevel` (0..254) |   |
