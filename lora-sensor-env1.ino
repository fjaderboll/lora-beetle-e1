/*
 * LoRa environment sensor (CubeCell HTCC-AB01)
 *
 * Sensors:
 *   - BME280 (I2C): temperature, humidity, pressure
 *   - BH1750 (I2C): ambient light (lux)
 *
 * Behaviour:
 *   - OTAA join on power-up
 *   - Every APP_TX_DUTYCYCLE (15 min) wake up, read sensors,
 *     transmit an uplink, then go back to deep sleep.
 *
 * Region / sub-band must be selected in the Arduino IDE
 *   "Tools" menu (LoRaWAN Region, Class, etc.).
 *
 * Uplink payload (11 bytes, big-endian, port 2):
 *   [0..1] temperature * 100   (int16)   -- e.g. 2345 = 23.45 C
 *   [2..3] humidity    * 100   (uint16)  -- e.g. 5012 = 50.12 %
 *   [4..5] pressure    * 10    (uint16)  -- hPa * 10, e.g. 10132 = 1013.2 hPa
 *   [6..9] light (lux) * 100   (uint32)  -- e.g. 12345 = 123.45 lx
 *   [10]   battery level       (uint8)   -- CubeCell BoardGetBatteryLevel (0..254)
 */

#include "LoRaWan_APP.h"
#include "Arduino.h"
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>
#include <BH1750.h>
#include "keys.h"

// Fallbacks for keys.h files predating the defaults
#ifndef DEFAULT_APP_EUI
#define DEFAULT_APP_EUI { 0 }
#endif
#ifndef DEFAULT_APP_KEY
#define DEFAULT_APP_KEY { 0 }
#endif

/* ------------------------------------------------------------------ */
/* LoRaWAN keys                                                       */
/* ------------------------------------------------------------------ */
// OTAA credentials (don't modify here, go to keys.h)
uint8_t devEui[8] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
uint8_t appEui[8] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
uint8_t appKey[16] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};

// ABP credentials (not used when overTheAirActivation=true, but kept for CubeCell compatibility)
uint8_t nwkSKey[] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};
uint8_t appSKey[] = {
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
};
uint32_t devAddr = 0x00000000;

/* ------------------------------------------------------------------ */
/* LoRaWAN configuration                                              */
/* ------------------------------------------------------------------ */

/* LoRaWAN region (override via Arduino IDE "Tools > LoRaWAN Region" menu).
 * The macro ACTIVE_REGION is supplied by the CubeCell board package. */
#ifndef ACTIVE_REGION
#define ACTIVE_REGION   LORAMAC_REGION_EU868
#endif
LoRaMacRegion_t loraWanRegion = ACTIVE_REGION;

/* Class A : end-device only opens RX windows after a TX. */
DeviceClass_t  loraWanClass    = CLASS_A;

/* Uplink interval: 15 minutes (in milliseconds). */
uint32_t appTxDutyCycle        = 15 * 60 * 1000;

/* OTAA activation. */
bool overTheAirActivation      = true;

/* Adaptive Data Rate. */
bool loraWanAdr                = true;

/* Keep network state between deep-sleep cycles
 * (so we don't have to re-join on every wake-up).
 * NOTE: temporarily set to false while debugging join failures so
 * the device always performs a fresh OTAA join. */
bool keepNet                   = true;

/* Unconfirmed uplinks (saves airtime / battery). */
bool isTxConfirmed             = false;

/* Application port. */
uint8_t appPort                = 2;

/* Confirmed-uplink retries (only relevant if isTxConfirmed = true). */
uint8_t confirmedNbTrials      = 4;

/* Sub-band selection for regions that need it (e.g. US915, AU915).
 * EU868 / AS923 / IN865 ignore this. The default mask enables the first
 * 8 channels; adjust if your network uses a different sub-band. */
uint16_t userChannelsMask[6]   = { 0x00FF, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000 };

/* ------------------------------------------------------------------ */
/* Sensor objects                                                     */
/* ------------------------------------------------------------------ */

static Adafruit_BME280 bme;
static BH1750          lightMeter;

static bool bmeReady   = false;
static bool lightReady = false;

/* ------------------------------------------------------------------ */
/* Helpers                                                            */
/* ------------------------------------------------------------------ */

static bool isAllZero(const uint8_t *buf, int len)
{
	for (int i = 0; i < len; i++) {
		if (buf[i] != 0) {
			return false;
		}
	}
	return true;
}

static void printHex(const char *label, const uint8_t *buf, int len)
{
	Serial.print(label);
	for (int i = 0; i < len; i++) {
		Serial.printf("%02X", buf[i]);
	}
	Serial.println();
}

/* Resolve credentials per field: keyMap entry -> default (see keys.h). */
static void setupKeys()
{
	uint64_t chipId = getID();
	Serial.printf("ChipID: %04X%08X\n", (uint16_t)(chipId>>32), (uint32_t)chipId);

	// Defaults
	static const uint8_t defaultAppEui[8] = DEFAULT_APP_EUI;
	static const uint8_t defaultAppKey[16] = DEFAULT_APP_KEY;
	LoRaWAN.generateDeveuiByChipID();
	memcpy(appEui, defaultAppEui, sizeof(appEui));
	memcpy(appKey, defaultAppKey, sizeof(appKey));

	// Per-device overrides, all-zero fields are left at their defaults
	for (int i = 0; i < keyMapSize; i++) {
		const KeyMapping *k = &keyMap[i];
		if (k->chipId != chipId) {
			continue;
		}
		Serial.println("Chip ID found in key map");
		if (!isAllZero(k->devEui, sizeof(k->devEui))) {
			memcpy(devEui, k->devEui, sizeof(devEui));
		}
		if (!isAllZero(k->appEui, sizeof(k->appEui))) {
			memcpy(appEui, k->appEui, sizeof(appEui));
		}
		if (!isAllZero(k->appKey, sizeof(k->appKey))) {
			memcpy(appKey, k->appKey, sizeof(appKey));
		}
		break;
	}

	printHex("DevEUI: ", devEui, sizeof(devEui));
	printHex("AppEUI: ", appEui, sizeof(appEui));
	printHex("AppKey: ", appKey, sizeof(appKey));

	if (isAllZero(appKey, sizeof(appKey))) {
		Serial.println("WARNING: AppKey is all zeros, set DEFAULT_APP_KEY or a per-device appKey in keys.h");
	}
}

static void turnSensorPowerOn() {
	/* CubeCell powers external 3V3 (sensors) via the Vext pin. */
	pinMode(Vext, OUTPUT);
	digitalWrite(Vext, LOW);   // LOW = Vext ON
	delay(50); // wait for sensors to wake up
	Serial.println("Vext is on");
}

static void turnSensorPowerOff() {
	/* Turn off Vext to save power until next cycle. */
	digitalWrite(Vext, HIGH);
	Serial.println("Vext is off");
}

static void initSensors()
{
	turnSensorPowerOn();
	Wire.begin();

	/* BME280 default I2C address is 0x76, fall back to 0x77. */
	bmeReady = bme.begin(0x76, &Wire);
	if (!bmeReady) {
		bmeReady = bme.begin(0x77, &Wire);
	}
	if (bmeReady) {
		/* Weather-station preset: 1x oversampling, forced mode, filter off. */
		bme.setSampling(Adafruit_BME280::MODE_FORCED,
		                Adafruit_BME280::SAMPLING_X1,   // temp
		                Adafruit_BME280::SAMPLING_X1,   // pressure
		                Adafruit_BME280::SAMPLING_X1,   // humidity
		                Adafruit_BME280::FILTER_OFF);
	} else {
		Serial.println(F("BME280 not found"));
	}

	lightReady = lightMeter.begin(BH1750::ONE_TIME_HIGH_RES_MODE);
	if (!lightReady) {
		Serial.println(F("BH1750 not found"));
	}
}

static void writeUint16BE(uint8_t *buf, uint16_t v)
{
	buf[0] = (uint8_t)(v >> 8);
	buf[1] = (uint8_t)(v & 0xFF);
}

static void writeUint32BE(uint8_t *buf, uint32_t v)
{
	buf[0] = (uint8_t)(v >> 24);
	buf[1] = (uint8_t)(v >> 16);
	buf[2] = (uint8_t)(v >> 8);
	buf[3] = (uint8_t)(v & 0xFF);
}

/* Build the uplink payload from a fresh sensor read. */
static void prepareTxFrame(uint8_t port)
{
	(void)port;

	initSensors();

	float tempC      = 0.0f;
	float humidity   = 0.0f;
	float pressureHp = 0.0f;
	float lux        = 0.0f;

	if (bmeReady) {
		/* Forced mode: trigger one measurement and read it back. */
		bme.takeForcedMeasurement();
		tempC      = bme.readTemperature();          // °C
		humidity   = bme.readHumidity();             // %
		pressureHp = bme.readPressure() / 100.0f;    // Pa -> hPa
	}

	if (lightReady) {
		/* ONE_TIME mode: re-arm and wait for a fresh sample.
		 * High-res measurement takes ~120 ms. */
		lightMeter.configure(BH1750::ONE_TIME_HIGH_RES_MODE);
		delay(180);
		lux = lightMeter.readLightLevel();
		if (lux < 0) {
			lux = 0;
		}
	}

	int16_t  tempScaled  = (int16_t)lroundf(tempC * 100.0f);
	uint16_t humScaled   = (uint16_t)lroundf(humidity * 100.0f);
	uint16_t pressScaled = (uint16_t)lroundf(pressureHp * 10.0f);
	uint32_t luxScaled   = (uint32_t)lroundf(lux * 100.0f);
	uint8_t  battery     = BoardGetBatteryLevel();

	appDataSize = 11;
	writeUint16BE(&appData[0], (uint16_t)tempScaled);
	writeUint16BE(&appData[2], humScaled);
	writeUint16BE(&appData[4], pressScaled);
	writeUint32BE(&appData[6], luxScaled);
	appData[10] = battery;

	Serial.printf("T=%.2f C  RH=%.2f %%  P=%.2f hPa  L=%.2f lx  bat=%u\n",
	              tempC, humidity, pressureHp, lux, battery);
	
	turnSensorPowerOff();
}

/* ------------------------------------------------------------------ */
/* Arduino entry points                                               */
/* ------------------------------------------------------------------ */

void setup()
{
	Serial.begin(115200);
	delay(10);

	setupKeys();

	deviceState = DEVICE_STATE_INIT;
	/* Skip-join check disabled while debugging — always re-join on boot. */
	// LoRaWAN.ifskipjoin();
}

void loop()
{
	switch (deviceState) {
		case DEVICE_STATE_INIT: {
			LoRaWAN.init(loraWanClass, loraWanRegion);
			break;
		}
		case DEVICE_STATE_JOIN: {
			Serial.printf("DevEui: %02X%02X%02X%02X%02X%02X%02X%02X\n",
				devEui[0],devEui[1],devEui[2],devEui[3],
				devEui[4],devEui[5],devEui[6],devEui[7]);
			LoRaWAN.join();
			break;
		}
		case DEVICE_STATE_SEND: {
			prepareTxFrame(appPort);
			LoRaWAN.send();
			deviceState = DEVICE_STATE_CYCLE;
			break;
		}
		case DEVICE_STATE_CYCLE: {
			/* Schedule next uplink, with a small random jitter (0..1 s). */
			txDutyCycleTime = appTxDutyCycle + randr(0, 1000);
			LoRaWAN.cycle(txDutyCycleTime);
			deviceState = DEVICE_STATE_SLEEP;
			break;
		}
		case DEVICE_STATE_SLEEP: {
			LoRaWAN.sleep();
			break;
		}
		default: {
			deviceState = DEVICE_STATE_INIT;
			break;
		}
	}
}
