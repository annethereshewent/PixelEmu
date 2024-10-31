//
//  TouchControlsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import SwiftUI
import DSEmulatorMobile

struct TouchControlsView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @Binding var emulator: MobileEmulator?
    @Binding var audioManager: AudioManager?
    @Binding var workItem: DispatchWorkItem?
    @Binding var isRunning: Bool
    @Binding var buttonStarted: [ButtonEvent:Bool]
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var isHoldButtonsPresented: Bool
    @Binding var heldButtons: Set<ButtonEvent>

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @State private var buttons: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()
    @State private var controlPad: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()    
    @State private var buttonsMisc: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()

    @EnvironmentObject var orientationInfo: OrientationInfo

    // for resizing images proportionately
    private let buttonImage = UIImage(named: "Buttons")
    private let controlPadImage = UIImage(named: "Control Pad")
    private let miscButtons = UIImage(named: "Buttons Misc")
    private let redButton = UIImage(named: "Red Button")

    private let allButtons: Set<ButtonEvent> = [
        ButtonEvent.ButtonA,
        ButtonEvent.ButtonB,
        ButtonEvent.ButtonL,
        ButtonEvent.ButtonR,
        ButtonEvent.ButtonX,
        ButtonEvent.ButtonY,
        ButtonEvent.Down,
        ButtonEvent.Left,
        ButtonEvent.Right,
        ButtonEvent.Down,
        ButtonEvent.Select,
        ButtonEvent.Start
    ]

    private var buttonScale: CGFloat {
        if orientationInfo.orientation == .landscape {
            return 0.90
        }
        
        let rect = UIScreen.main.bounds

        if rect.height > 852.0 {
            return 1.3
        } else {
            return 1.05
        }
    }

    private func releaseHapticFeedback() {
        buttonStarted[ButtonEvent.ButtonA] = false
        buttonStarted[ButtonEvent.ButtonB] = false
        buttonStarted[ButtonEvent.ButtonY] = false
        buttonStarted[ButtonEvent.ButtonX] = false
    }
    
    private func checkForHapticFeedback(point: CGPoint, entries: [ButtonEvent:CGRect]) {
        for entry in entries {
            if entry.value.contains(point) && !buttonStarted[entry.key]! {
                feedbackGenerator.impactOccurred()
                buttonStarted[entry.key] = true
                break
            }
        }
    }
    
    private func initButtonState() {
        self.buttonStarted[ButtonEvent.Up] = false
        self.buttonStarted[ButtonEvent.Down] = false
        self.buttonStarted[ButtonEvent.Left] = false
        self.buttonStarted[ButtonEvent.Right] = false
        
        self.buttonStarted[ButtonEvent.ButtonA] = false
        self.buttonStarted[ButtonEvent.ButtonB] = false
        self.buttonStarted[ButtonEvent.ButtonY] = false
        self.buttonStarted[ButtonEvent.ButtonX] = false
        
        self.buttonStarted[ButtonEvent.ButtonL] = false
        self.buttonStarted[ButtonEvent.ButtonR] = false
        
        self.buttonStarted[ButtonEvent.Start] = false
        self.buttonStarted[ButtonEvent.Select] = false
        
        self.buttonStarted[ButtonEvent.ButtonHome] = false
    }
    
    private func handleControlPad(point: CGPoint) {
        self.handleInput(point: point, entries: controlPad)
    }
    
    private func handleInput(point: CGPoint, entries: [ButtonEvent:CGRect]) {
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
            emu.updateInput(ButtonEvent.Up, false)
            emu.updateInput(ButtonEvent.Left, false)
            emu.updateInput(ButtonEvent.Right, false)
            emu.updateInput(ButtonEvent.Down, false)
        }
    }
    
    private func handleButtons(point: CGPoint) {
        self.handleInput(point: point, entries: buttons)
    }
    
    private func releaseButtons() {
        let buttons = [ButtonEvent.ButtonA, ButtonEvent.ButtonB, ButtonEvent.ButtonY, ButtonEvent.ButtonX]
        if let emu = emulator {
            for button in buttons {
                if !heldButtons.contains(button) {
                    emu.updateInput(button, false)
                }
            }
        }
    }
    
    private func goHome() {
        emulator?.setPause(true)
        audioManager?.muteAudio()
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func handleMiscButtons(point: CGPoint) {
        for entry in buttonsMisc {
            if entry.value.contains(point) {
                if entry.key != ButtonEvent.ButtonHome {
                    if let emu = emulator {
                        emu.updateInput(entry.key, true)
                    }
                } else {
                    goHome()
                    break
                }
            } else if entry.key != ButtonEvent.ButtonHome {
                if let emu = emulator {
                    emu.updateInput(entry.key, false)
                }
            }
        }
    }

    private func releaseMiscButtons() {
        if let emu = emulator {
            emu.updateInput(ButtonEvent.Start, false)
            emu.updateInput(ButtonEvent.Select, false)
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

        controlPad[ButtonEvent.Up] = up
        controlPad[ButtonEvent.Down] = down
        controlPad[ButtonEvent.Left] = left
        controlPad[ButtonEvent.Right] = right
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

        buttonsMisc[ButtonEvent.Start] = startButton
        buttonsMisc[ButtonEvent.Select] = selectButton
        buttonsMisc[ButtonEvent.ButtonHome] = homeButton

    }

    private func recalculateButtons() {
        let imageWidth = buttonImage!.size.width * buttonScale
        let imageHeight = buttonImage!.size.height * buttonScale
        let width = imageHeight * 0.35
        let height = imageHeight * 0.35

        let xButton = CGRect(x: imageWidth * 0.35, y: 0, width: width, height: height)
        let yButton  = CGRect(x: 0, y: imageHeight * 0.35, width: width, height: height)
        let aButton = CGRect(x: imageHeight * 0.69, y: imageHeight * 0.35, width: width, height: height)
        let bButton = CGRect(x: imageWidth * 0.35, y: imageHeight * 0.69, width: width, height: height)

        buttons[ButtonEvent.ButtonA] = aButton
        buttons[ButtonEvent.ButtonX] = xButton
        buttons[ButtonEvent.ButtonY] = yButton
        buttons[ButtonEvent.ButtonB] = bButton
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
                                    
                                    controlPad[ButtonEvent.Up] = up
                                    controlPad[ButtonEvent.Down] = down
                                    controlPad[ButtonEvent.Left] = left
                                    controlPad[ButtonEvent.Right] = right
                                }
                        }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { result in
                                // you can use any of the control pad buttons here and it'll work ok
                                // the choice to use up is arbitrary
                                if !buttonStarted[ButtonEvent.Up]! {
                                    feedbackGenerator.impactOccurred()
                                    buttonStarted[ButtonEvent.Up] = true
                                }
                                handleControlPad(point: result.location)
                            }
                            .onEnded() { result in
                                buttonStarted[ButtonEvent.Up] = false
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
                                    buttonStarted[ButtonEvent.Start] = false
                                    buttonStarted[ButtonEvent.Select] = false
                                    buttonStarted[ButtonEvent.ButtonHome] = false
                                    
                                    releaseMiscButtons()
                                }
                        )
                    Button() {
                        isMenuPresented = !isMenuPresented
                        if let emu = emulator {
                            emu.setPause(isMenuPresented)
                        }
                    } label: {
                        Image("Red Button")
                            .resizable()
                            .frame(width: redButton!.size.width, height: redButton!.size.height)
                    }
                }
                Spacer()
                Image("Buttons")
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
