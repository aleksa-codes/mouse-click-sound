# Mouse Click Sound

A small macOS menu-bar app for tactile mouse clicks, taps, holds, and drags. Requires macOS 14 or later.

## Install

Create the app ZIP:

```sh
make package
```

Open `dist/Mouse Click Sound-macOS.zip`, move the app to Applications, then open it. Because it is not notarized, Control-click the app and choose **Open** the first time. Allow it under System Settings → Privacy & Security → Input Monitoring, then reopen if macOS asks.

## Develop

Install Xcode Command Line Tools, then run `make run` to build and open the app. `make check` compiles the code and validates project metadata.

`make package` creates an ad-hoc-signed ZIP that can be attached to a GitHub Release. It does not require a paid Apple Developer account. Users approve the first launch and Input Monitoring permission in macOS.
