function decodeUplink(input) {
  const warnings = [];
  const errors = [];
  const { bytes, fPort } = input;

  if (fPort !== 2) {
    warnings.push(`Unexpected port ${fPort}; payload decoding is defined for port 2`);
    return {
      data: {},
      warnings,
      errors
    };
  }

  if (!Array.isArray(bytes) || bytes.length !== 11) {
    errors.push(`Invalid payload length ${bytes ? bytes.length : 0}; expected 11 bytes`);
    return {
      data: {},
      warnings,
      errors
    };
  }

  const readUint8 = (offset) => bytes[offset] & 0xff;
  const readUint16BE = (offset) => ((bytes[offset] & 0xff) << 8) | (bytes[offset + 1] & 0xff);
  const readUint32BE = (offset) =>
    ((bytes[offset] & 0xff) << 24) |
    ((bytes[offset + 1] & 0xff) << 16) |
    ((bytes[offset + 2] & 0xff) << 8) |
    (bytes[offset + 3] & 0xff);

  const tempRaw = readUint16BE(0);
  const temperature = tempRaw & 0x8000 ? tempRaw - 0x10000 : tempRaw;
  const humidityRaw = readUint16BE(2);
  const pressureRaw = readUint16BE(4);
  const lightRaw = readUint32BE(6);
  const battery = readUint8(10);

  return {
    data: {
      temperature: temperature / 100.0, // °C
      humidity: humidityRaw / 100.0, // %RH
      pressure: pressureRaw / 10.0, // hPa
      light: lightRaw / 100.0, // lux
      batteryLevel: battery // 0=external power, 1-254=0-100%, 255=N/A
    },
    warnings,
    errors
  };
}

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { decodeUplink };
}