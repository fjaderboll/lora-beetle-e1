# Downlink commands

Sent on `port 2`, big-endian. The first byte is the command, followed by its parameters:

| Bytes | Field      | Encoding                         |
|-------|------------|----------------------------------|
| 0     | Command    | `uint8`, see table below         |
| 1..   | Parameters | depends on the command           |

| Command | Name                                        | Parameter bytes |
|---------|---------------------------------------------|-----------------|
| `0x01`  | [Set uplink interval](#0x01-set-uplink-interval) | 2          |

One command per downlink. A downlink on another port, with an unknown command, the wrong
number of parameter bytes or an out-of-range value is ignored (the reason is printed on the
serial output).

The device is LoRaWAN class A, so it can only receive right after one of its own uplinks. A
scheduled downlink is therefore delivered with the next uplink. To deliver it right away,
press the USER button to send an uplink.

## `0x01` Set uplink interval

| Bytes | Field    | Encoding                      | Example                 |
|-------|----------|-------------------------------|-------------------------|
| 0     | Command  | `0x01`                        |                         |
| 1..2  | Interval | `uint16`, minutes, `1..1440`  | `003C` → 60 min (1 h)   |

The new interval applies right away, the next uplink is sent one new interval after the
uplink that received the downlink. It is kept in RAM only, a reset or power loss reverts to
the default of 15 minutes.

The range is limited to 1 minute .. 24 hours. The minimum prevents flooding the network
(and draining the battery), the maximum stays clear of the CubeCell RTC alarm, which
can't be set more than ~36 hours ahead.

| Interval         | Payload (hex) |
|------------------|---------------|
| 1 min            | `01 00 01`    |
| 5 min            | `01 00 05`    |
| 15 min (default) | `01 00 0F`    |
| 1 h              | `01 00 3C`    |
| 6 h              | `01 01 68`    |
| 24 h             | `01 05 A0`    |

## Sending
If you're using TTN, go to the end device, *Messaging* -> *Schedule downlink*, set
*FPort* to `2` and enter the payload as hex, e.g. `01003C`.
