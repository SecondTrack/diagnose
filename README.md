# Probe

**Check a used iPod in five minutes – screen, touch, sensors, CPU, storage, speaker and mic.**

Made for buying and selling used devices: seven quick tests that find the typical faults of old iPods.

## The seven tests

1. **Display** – full-screen red, green, blue, white, black and grey to spot dead or stuck pixels.
2. **Touch** – paint over a grid; cells that stay grey are dead zones. Shows every finger for multitouch.
3. **Sensors** – accelerometer and gyroscope live at 30 Hz, with a spirit level.
4. **CPU & RAM** – current load, memory use and a short benchmark.
5. **Storage** – free/total space and a real speed test (writes and reads 16 MB, reports MB/s).
6. **Speaker** – test tones from 100 Hz to 10 kHz plus a sweep from 20 Hz to 15 kHz, generated on the device.
7. **Microphone** – record, see the level in dB with peak hold, play it back.

## Runs on

iOS 6.1.6 · jailbroken iPod touch 4

## Install

Easiest via the **[Reboot App Store](https://github.com/SecondTrack/reboot)** right on the iPod. By hand: `.deb` from the [latest release](https://github.com/SecondTrack/probe/releases/latest), `dpkg -i`, then `uicache`.

Build it yourself with [Theos](https://theos.dev): `make package` (iOS 6.0+, armv7).

## License

GPL-3.0 – see [LICENSE](LICENSE).
Not affiliated with Apple. iPod is a trademark of Apple Inc.
