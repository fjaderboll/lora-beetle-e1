# Software
I'm assuming the use of *Arduino IDE* for below.

## Setup
1. Create a local copy of the key file:
	```shell
	cp keys.h.default keys.h
	```
	Updating this file is optional, but recommended, see [Keys](#keys) section below.
2. Setup *Arduino IDE*: https://docs.heltec.org/en/node/asr650x/asr650x_general_docs/quick_start/index.html
	1. Go to *File* -> *Preferences* -> *Additional boards manager URLs* and add this link:
	```
	https://github.com/HelTecAutomation/CubeCell-Arduino/releases/download/V1.7.1/package_CubeCell_index.json
	```
	2. In *Board manager*, install *CubeCell Development Framework*
3. Open this project and select board `CubeCell-Board (HTCC-AB01-V2)`
4. Install the following libraries via the Arduino *Library Manager*:
	* `Adafruit BME280 Library` (pulls in `Adafruit Unified Sensor`)
	* `BH1750` by Christopher Laws
5. In the *Tools* menu, configure:
	* `LORAWAN_ADR`        : `ON`
	* `LORAWAN_CLASS`      : `CLASS_A`
	* `LORAWAN_DEVEUI`     : `CUSTOM`
	* `LORAWAN_Net_Reservation`: `ON` (keep network state across deep sleep)
	* `LORAWAN_NETMODE`    : `OTAA`
	* `LORAWAN_REGION`     : `REGION_EU868` (or your region)
	* `LORAWAN_RGB`        : `DEACTIVE` (to preserve battery)
	* `LORAWAN_UPLINKMODE` : `UNCONFIRMED`
6. Compile and flash this to your device.
7. Take note of the `ChipID`, `DevEUI`, `AppEUI` and `AppKey` in the serial output and register the device in your LNS (use LoRaWAN v1.0.2 with Regional Parameters v1.0.2 rev B).

## Keys
For best security and LoRaWAN practise, you should configure your own *AppEUI*
and individual *AppKey* per device.

In the Serial Output after flashing the *CubeCell*, you'll see the *ChipID*,
use this as unique identifier in the `keyMap` in `keys.h`:

| Field          | Per-device `keyMap` entry | Fallback                   |
| -------------- | ------------------------- | -------------------------- |
| DevEUI         | `devEui`                  | generated from the chip ID |
| AppEUI/JoinEUI | `appEui`                  | `DEFAULT_APP_EUI`          |
| AppKey         | `appKey`                  | `DEFAULT_APP_KEY`          |

Omitted or all-zero fields in a `keyMap` entry fall back to the right column.
Typical setups:
* **Shared key:** set `DEFAULT_APP_KEY` and leave `keyMap` empty.
* **Unique key per device (recommended):** add a `keyMap` entry per `ChipID` with only `appKey` set.
* **Fully custom:** set `devEui`, `appEui` and `appKey` in the entry.

## Send and receive data
Once the device has joined the network, the [uplink](uplink.md) will contain
the sensor data.

Use a [downlink](downlink.md) to modify the sending interval.
