# Battery
A Lithium-ion battery 3.7V (18650) is used.

## Battery life
There are many variables that affect this, like
battery capacity, temperature and radio conditions.
I've so far done limited real-life testing, so take
below with a grain of salt.

Static assumptions:
* Battery capacity: `3000 mAh`, of which `85 %` is usable
  (cutoff voltage, cold, ageing)
* Self-discharge: `2 %` per month (typical for Li-ion is 1-3 %)
* Sleep consumption: `10 µA` (CubeCell spec is `3.5 µA`,
  plus margin for real-world variation and that my multimeter doesn't go single digit µA)
* Data length: `24 bytes` (LoRaWAN headers `13 bytes` + uplink [payload](uplink.md) `11 bytes`)
* Transmit power: `14 dBm` (EU868)

Every uplink wakes the device up, reads the sensors,
transmits and then opens two short receive windows for
a possible [downlink](downlink.md). The first window
uses the same spreading factor as the uplink, the
second one SF12 (set in TTN, its default for EU868 is
SF9).

| Phase             | Current | SF7 time   | SF12 time   |
| ----------------- | ------- | ---------- | ----------- |
| Wake-up, sensors  | 10 mA   | 500 ms     | 500 ms      |
| Transmit          | 90 mA   | 62 ms      | 1483 ms     |
| Receive window 1  | 10 mA   | 30 ms      | 200 ms      |
| Receive window 2  | 10 mA   | 200 ms     | 200 ms      |
| **Per uplink**    |         | **13 mAs** | **142 mAs** |

The things that affects most are the sending interval
and the radio conditions. Best case scenario is Data
Rate 5 (Spreading Factor 7) and worst case scenario
Data Rate 0 (Spreading Factor 12), which will prolong
the airtime.

Duty cycle is the share of time spent transmitting. In
EU868 it must be kept below `1 %`.

| Interval | DR | SF | Airtime per day | Duty cycle | Avg. current | Battery life |
| -------- | -- | -- | --------------- | ---------- | ------------ | ------------ |
| 5 min    | 5  | 7  | 17.8 s          | 0.021 %    | 53 µA        | 26 months    |
| 15 min   | 5  | 7  | 5.9 s           | 0.0069 %   | 24 µA        | 33 months    |
| 1 h      | 5  | 7  | 1.5 s           | 0.0017 %   | 14 µA        | 36 months    |
| 24 h     | 5  | 7  | 0.06 s          | 0.00007 %  | 10 µA        | 38 months    |
| 5 min    | 0  | 12 | 427 s [^1]      | 0.49 %     | 485 µA       | 6 months     |
| 15 min   | 0  | 12 | 142 s [^1]      | 0.16 %     | 168 µA       | 14 months    |
| 1 h      | 0  | 12 | 35.6 s [^1]     | 0.041 %    | 50 µA        | 27 months    |
| 24 h     | 0  | 12 | 1.5 s           | 0.0017 %   | 12 µA        | 37 months    |

With good radio conditions the device itself draws
less than the battery loses to self-discharge (`2 %` of
`3000 mAh` per month is about `80 µA`), so the battery
lasts around 3 years whatever the interval. With bad
radio conditions, the interval matters a lot more.

[^1]: Above the 30 s per day allowed by the TTN
    [fair use policy](https://www.thethingsnetwork.org/docs/lorawan/duty-cycle/#fair-use-policy).
    At SF12, keep the interval above ~72 minutes.

If using a `4000 mAh` battery (instead of `3000 mAh`), you can add about 1-3
months of battery life to above. Self-discharge grows
with the capacity, so a bigger battery helps less than
you might expect.
