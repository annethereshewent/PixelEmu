# NDS Plus Mobile

## Getting Started

This is a mobile emulator that uses https://github.com/annethereshewent/nds-plus as its core. It is currently a work in progress.

To get the project up and running locally, you'll need to go through the following steps:

1. install Rust toolchains for iOS: `rustup target add x86_64-apple-darwin aarch64-apple-darwin aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
`
2. Install swift-bridge cli: `cargo install -f swift-bridge-cli`
3. Change directories to external/nds-plus-emulator/mobile.
4. run `./build-rust.sh`
5. run the following command with swift-bridge:
  ```
    swift-bridge-cli create-package \
  --bridges-dir ./generated \
  --out-dir DSEmulatorMobile \
  --ios target/aarch64-apple-ios/release/libds_emulator_mobile.a \
  --simulator target/universal-ios/release/libds_emulator_mobile.a \
  --macos target/universal-macos/release/libds_emulator_mobile.a \
  --name DSEmulatorMobile
  ```
7. Open NDS Plus.xcworkspace, then go to `File -> Add Package Dependencies`
8. Select `Add Local` then select the `external/nds-plus-emulator/mobile/DSEmulatorMobile` directory.
9. Go to the project's general panel, and under `Frameworks, Libraries, and Embedded Content` and hit the `+` button.
10. Select the DSEmulatorMobile package from under `Workspace`.
11. Lastly you will need to have cocoapods installed, then in the root directory of this project, run `pod install`.
12. Build/run the project like normal.

This is still very much a work-in-progress and needs a lot of overhaul in its design in particular, but it should work for most games.

Supported features:

- Microphone support
- Audio support
- Supports gamepad controllers (need to overhaul interface for this)
- Local and cloud saves

Todo: 

- Save states
- Debugging tools
- Design overhaul

## Screenshots

TODO
