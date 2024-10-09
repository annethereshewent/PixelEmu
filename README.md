# NDS Plus Mobile

## Getting Started

This is a mobile emulator that uses https://github.com/annethereshewent/nds-plus as its core. It is currently a work in progress.

To get the project up and running locally, you'll need to go through the following steps:

1. Open NDS Plus.xcworkspace, then go to `File -> Add Package Dependencies`
2. Select `Add Local` then select the `external/nds-plus-emulator/mobile/DSEmulatorMobile` directory.
3. Go to the project's general panel, and under `Frameworks, Libraries, and Embedded Content` and hit the `+` button.
4. Select the DSEmulatorMobile package from under `Workspace`.
5. Build/run the project like normal.

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
