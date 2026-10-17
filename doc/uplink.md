# Uplink payload

Sent on `port 2`, 11 bytes, big-endian:

| Bytes | Field        | Encoding              | Example          |
|-------|--------------|-----------------------|------------------|
| 0..1  | Temperature  | `int16`,  value × 100 | `2345`  → 23.45 °C |
| 2..3  | Humidity     | `uint16`, value × 100 | `5012`  → 50.12 % |
| 4..5  | Pressure     | `uint16`, value × 10  | `10132` → 1013.2 hPa |
| 6..9  | Light        | `uint32`, value × 100 | `12345` → 123.45 lux |
| 10    | BatteryLevel | `uint8`, value x 1    | `0` = external power, `1..254` = 0-100%, `255` = N/A  |

## Decoding
If your're using TTN, use content from [ttn-uplink-formatter.js](../ttn-uplink-formatter.js) for the
*Custom Javscript formatter*.
