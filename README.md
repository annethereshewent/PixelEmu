# PixelEmu

## Getting Started

This is a mobile emulator that supports several emulator cores, including NDS, GBA, and GBC.

To get the project up and running locally, you'll need to go through the following steps:

1. install Rust toolchains for iOS: `rustup target add x86_64-apple-darwin aarch64-apple-darwin aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim
`
2. Install swift-bridge cli: `cargo install -f swift-bridge-cli`
3. Change directory to `external/nds-plus-emulator/mobile`
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
8. Change directory to `external/gba-plus/mobile`
9. run `./build-rust.sh`
10. run the following command with swift-bridge:
  ```
    swift-bridge-cli create-package \
  --bridges-dir ./generated \
  --out-dir GBAEmulatorMobile \
  --ios target/aarch64-apple-ios/release/libgba_emulator_mobile.a \
  --simulator target/universal-ios/release/libgba_emulator_mobile.a \
  --macos target/universal-macos/release/libgba_emulator_mobile.a \
  --name GBAEmulatorMobile
  ```
11. Run `./gba-emu.sh`
12. Install Cocoapods if it's not already installed, then in the root directory of this project, run `pod install`.
7. Open the generated workspace file from the above command, then go to `File -> Add Package Dependencies`
8. Select `Add Local` then select the `external/nds-plus-emulator/mobile/DSEmulatorMobile` directory.
9. Go to the project's general panel, and under `Frameworks, Libraries, and Embedded Content` and hit the `+` button.
10. Select the `DSEmulatorMobile` package from under `Workspace`.
11. Build/run the project like normal.

Supported features:

- Microphone support
- Audio support
- Supports gamepad controllers 
- Local and cloud saves
- Save states

Todo: 

- Debugging tools

## Screenshots

<img src="https://github.com/user-attachments/assets/9033e4d2-1be2-4210-922e-41cceeaefb0c" width="322" height="699">
<img src="https://github.com/user-attachments/assets/8723f63e-4876-4832-a005-d514c20672d8" width="322" height="699">

## Special Thanks

Thanks to Zedanov for helping out with the UX and designs of the app!


