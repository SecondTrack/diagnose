# Diagnostics

**Device check in seven tests**

Display and pixels, touchscreen, sensors with spirit level, CPU & RAM, storage with speed test, speaker and microphone. Ideal before buying or selling.

## Features

- Display / pixels
- Touch – dead zones and multitouch
- Sensors with spirit level
- CPU & RAM with benchmark
- Storage with speed test
- Speaker and microphone

## Runs on

iOS 6.1.6 · jailbroken iPod touch

## Install

The easiest way is the **[Reboot App Store](https://github.com/SecondTrack/reboot)** right on the iPod.
By hand: download the `.deb` from the [latest release](https://github.com/SecondTrack/diagnose/releases/latest), install it with `dpkg -i`, then run `uicache`.

## Build it yourself

With [Theos](https://theos.dev) (iOS SDK with armv7):

```sh
make package
```

## Part of Reboot

This app is part of **Reboot** by **Second Track** – new apps for old iPods.
All apps: [SecondTrack](https://github.com/SecondTrack).

## License

GPL-3.0 – see [LICENSE](LICENSE). Bundled libraries under `vendor/` keep their own licenses.
Not affiliated with Apple. iPod is a trademark of Apple Inc.
