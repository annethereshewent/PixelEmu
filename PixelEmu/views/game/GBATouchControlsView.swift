//
//  GBATouchControlsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/29/24.
//

import SwiftUI
import GBAEmulatorMobile

struct GBATouchControlsView: View {

    @Environment(\.presentationMode) var presentationMode

    @Binding var emulator: GBAEmulator?
    @Binding var emulatorCopy: GBAEmulator?
    @Binding var audioManager: AudioManager?
    @Binding var workItem: DispatchWorkItem?
    @Binding var isRunning: Bool
    @Binding var buttonStarted: [GBAButtonEvent:Bool]
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var isHoldButtonsPresented: Bool
    @Binding var heldButtons: Set<GBAButtonEvent>
    @Binding var isPaused: Bool

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    @State private var buttons: [GBAButtonEvent:CGRect] = [GBAButtonEvent:CGRect]()
    @State private var controlPad: [GBAButtonEvent:CGRect] = [GBAButtonEvent:CGRect]()
    @State private var buttonsMisc: [GBAButtonEvent:CGRect] = [GBAButtonEvent:CGRect]()

    @EnvironmentObject var orientationInfo: OrientationInfo

    // for resizing images proportionately
    private let buttonImage = UIImage(named: "GBA Buttons")
    private let controlPadImage = UIImage(named: "Control Pad")
    private let miscButtons = UIImage(named: "Buttons Misc")
    private let redButton = UIImage(named: "Red Button")

    private let allButtons: Set<GBAButtonEvent> = [
        .ButtonA,
        .ButtonB,
        .ButtonL,
        .ButtonR,
        .Down,
        .Left,
        .Right,
        .Down,
        .Select,
        .Start
    ]

    private var buttonScale: CGFloat {
        if orientationInfo.orientation == .landscape {
            return 1.0
        }

        let rect = UIScreen.main.bounds

        if rect.height > 852.0 {
            return 1.6
        } else {
            return 1.3
        }
    }

    private func releaseHapticFeedback() {
        buttonStarted[GBAButtonEvent.ButtonA] = false
        buttonStarted[GBAButtonEvent.ButtonB] = false
    }

    private func checkForHapticFeedback(point: CGPoint, entries: [GBAButtonEvent:CGRect]) {
        for entry in entries {
            if entry.value.contains(point) && !buttonStarted[entry.key]! {
                feedbackGenerator.impactOccurred()
                buttonStarted[entry.key] = true
                break
            }
        }
    }

    private func initButtonState() {
        self.buttonStarted[GBAButtonEvent.Up] = false
        self.buttonStarted[GBAButtonEvent.Down] = false
        self.buttonStarted[GBAButtonEvent.Left] = false
        self.buttonStarted[GBAButtonEvent.Right] = false

        self.buttonStarted[GBAButtonEvent.ButtonA] = false
        self.buttonStarted[GBAButtonEvent.ButtonB] = false

        self.buttonStarted[GBAButtonEvent.ButtonL] = false
        self.buttonStarted[GBAButtonEvent.ButtonR] = false

        self.buttonStarted[GBAButtonEvent.Start] = false
        self.buttonStarted[GBAButtonEvent.Select] = false

        self.buttonStarted[GBAButtonEvent.ButtonHome] = false
    }

    private func handleControlPad(point: CGPoint) {
        self.handleInput(point: point, entries: controlPad)
    }

    private func handleInput(point: CGPoint, entries: [GBAButtonEvent:CGRect]) {
        if let emu = emulator {
            for entry in entries {
                if entry.value.contains(point) {
                    if isHoldButtonsPresented {
                        if heldButtons.contains(entry.key) {
                            heldButtons.remove(entry.key)
                        } else {
                            heldButtons.insert(entry.key)
                        }
                    } else {
                        if heldButtons.contains(entry.key) {
                            emu.updateInput(entry.key, false)
                            // exactly one frame delay
                            Timer.scheduledTimer(withTimeInterval: 1 / 60, repeats: false) { _ in
                                emu.updateInput(entry.key, true)
                            }
                        } else {
                            emu.updateInput(entry.key, true)
                        }
                    }
                } else if !heldButtons.contains(entry.key) {
                    emu.updateInput(entry.key, false)
                }
            }
        }
    }

    private func releaseControlPad() {
        if let emu = emulator {
            emu.updateInput(GBAButtonEvent.Up, false)
            emu.updateInput(GBAButtonEvent.Left, false)
            emu.updateInput(GBAButtonEvent.Right, false)
            emu.updateInput(GBAButtonEvent.Down, false)
        }
    }

    private func handleButtons(point: CGPoint) {
        self.handleInput(point: point, entries: buttons)
    }

    private func releaseButtons() {
        let buttons = [GBAButtonEvent.ButtonA, GBAButtonEvent.ButtonB]
        if let emu = emulator {
            for button in buttons {
                if !heldButtons.contains(button) {
                    emu.updateInput(button, false)
                }
            }
        }
    }

    private func goHome() {
        isPaused = true

        // this isn't working
        // emulator?.setPaused(true)
        audioManager?.muteAudio()

        workItem?.cancel()
        workItem = nil

        // this is a hack, otherwise when resuming game nothing seems to work for some reason
        // seems like it's related to rust in some way and how it handles things.
        // TODO: dig into this further
        emulatorCopy = emulator
        emulator = nil

        presentationMode.wrappedValue.dismiss()
    }

    private func handleMiscButtons(point: CGPoint) {
        for entry in buttonsMisc {
            if entry.value.contains(point) {
                if entry.key == .ButtonHome {
                    goHome()
                } else if let emu = emulator {
                    emu.updateInput(entry.key, true)
                }
            } else {
                if let emu = emulator {
                    emu.updateInput(entry.key, false)
                }
            }
        }
    }

    private func releaseMiscButtons() {
        if let emu = emulator {
            emu.updateInput(GBAButtonEvent.Start, false)
            emu.updateInput(GBAButtonEvent.Select, false)
        }
    }

    private func recalculateButtonCoordinates() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            recalculateControlPad()
            recalculateButtons()
        }
    }

    private func recalculateControlPad() {

        let width = controlPadImage!.size.width * buttonScale
        let height = controlPadImage!.size.height * buttonScale

        let up = CGRect(x: 0, y: 0, width: width, height: height / 3)
        let down = CGRect(x: 0, y: (height / 3) * 2, width: width, height: height / 3)
        let right = CGRect(x: (width / 3) * 2, y: 0, width: width / 3, height: height)
        let left = CGRect(x: 0, y: 0, width: width / 3, height: height)

        controlPad[GBAButtonEvent.Up] = up
        controlPad[GBAButtonEvent.Down] = down
        controlPad[GBAButtonEvent.Left] = left
        controlPad[GBAButtonEvent.Right] = right
    }

    private func calculateMiscButtons() {
        let frameWidth = miscButtons!.size.width
        let frameHeight = miscButtons!.size.height

        // below numbers were gotten by dividing the heights of
        // buttons with the height of the entire button's image
        let divisor: CGFloat = 214.0 / 3.0

        let width = frameWidth
        let height = frameHeight * (16.0 / divisor)

        let selectY = frameHeight * (28.0 / divisor)
        let homeY = frameHeight * (54.0 / divisor)

        let startButton = CGRect(x: 0, y: 0, width: width, height: height)
        let selectButton = CGRect(x: 0, y: selectY, width: width, height: height)
        let homeButton = CGRect(x:0, y: homeY, width: width, height: height)

        buttonsMisc[GBAButtonEvent.Start] = startButton
        buttonsMisc[GBAButtonEvent.Select] = selectButton
        buttonsMisc[GBAButtonEvent.ButtonHome] = homeButton

    }

    private func recalculateButtons() {
        let imageWidth = buttonImage!.size.width * buttonScale
        let imageHeight = buttonImage!.size.height * buttonScale
        let width = imageHeight * 0.61
        let height = imageHeight * 0.61

        let aButton = CGRect(x: imageWidth * 0.55, y: 0, width: width, height: height)
        let bButton = CGRect(x: 0, y: imageHeight * 0.37, width: width, height: height)

        buttons[GBAButtonEvent.ButtonA] = aButton
        buttons[GBAButtonEvent.ButtonB] = bButton
    }

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image("Control Pad")
                    .resizable()
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    let frame = geometry.frame(in: .local)
                                    let up = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height / 3)
                                    let down = CGRect(x: frame.minX, y: (frame.maxY / 3) * 2, width: frame.width, height: frame.height / 3)
                                    let right = CGRect(x: (frame.maxX / 3) * 2, y: frame.minY, width: frame.width / 3, height: frame.height)
                                    let left = CGRect(x: frame.minX, y: frame.minY, width: frame.width / 3, height: frame.height)

                                    controlPad[GBAButtonEvent.Up] = up
                                    controlPad[GBAButtonEvent.Down] = down
                                    controlPad[GBAButtonEvent.Left] = left
                                    controlPad[GBAButtonEvent.Right] = right
                                }
                        }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { result in
                                // you can use any of the control pad buttons here and it'll work ok
                                // the choice to use up is arbitrary
                                if !buttonStarted[GBAButtonEvent.Up]! {
                                    feedbackGenerator.impactOccurred()
                                    buttonStarted[GBAButtonEvent.Up] = true
                                }
                                handleControlPad(point: result.location)
                            }
                            .onEnded() { result in
                                buttonStarted[GBAButtonEvent.Up] = false
                                releaseControlPad()
                            }
                    )
                    .frame(width: controlPadImage!.size.width * buttonScale, height: controlPadImage!.size.height * buttonScale)
                Spacer()
                VStack {
                    Image("Buttons Misc")
                        .padding(.bottom, 10)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged() { result in
                                    checkForHapticFeedback(point: result.location, entries: buttonsMisc)
                                    handleMiscButtons(point: result.location)
                                }
                                .onEnded() { result in
                                    buttonStarted[GBAButtonEvent.Start] = false
                                    buttonStarted[GBAButtonEvent.Select] = false

                                    releaseMiscButtons()
                                }
                        )
                    Button() {
                        isMenuPresented = !isMenuPresented
                        if let emu = emulator {
                            emu.setPaused(isMenuPresented)
                        }
                    } label: {
                        Image("Red Button")
                            .resizable()
                            .frame(width: redButton!.size.width, height: redButton!.size.height)
                    }
                }
                Spacer()
                Image("GBA Buttons")
                    .resizable()
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { result in
                                checkForHapticFeedback(point: result.location, entries: buttons)
                                handleButtons(point: result.location)
                            }
                            .onEnded() { result in
                                releaseButtons()
                                releaseHapticFeedback()
                            }
                    )
                    .frame(width: buttonImage!.size.width * buttonScale, height: buttonImage!.size.height * buttonScale)
                Spacer()
            }
            Spacer()
        }
        .onChange(of: heldButtons) {
            if let emu = emulator {
                for button in heldButtons {
                    emu.updateInput(button, true)
                }

                let difference = allButtons.subtracting(heldButtons)

                for button in difference {
                    emu.updateInput(button, false)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            recalculateButtonCoordinates()
        }
        .onAppear {
            calculateMiscButtons()
            recalculateButtonCoordinates()
            initButtonState()
        }
    }
}
