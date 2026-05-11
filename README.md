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
