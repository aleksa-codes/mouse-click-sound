# Mouse Click Sound

Native Swift 6.2 macOS 14+ menu-bar app. Uses AppKit, SwiftUI, AVFoundation, and CoreGraphics. No external dependencies.

`make run` builds and opens the app.
`make check` compiles Swift and validates shell/plist files.
`make package` builds an ad-hoc-signed DMG and ZIP in `dist/`.

The app bundle is assembled by `scripts/build.sh`. Static icons and WAV assets live in `Sources/MouseClickSound/Resources` and are copied into the app bundle.
No tests or linter are configured. Don't commit `.build/` or `dist/` outputs.
