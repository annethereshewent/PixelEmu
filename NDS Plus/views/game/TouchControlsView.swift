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
    
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    @State private var buttons: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()
    @State private var controlPad: [ButtonEvent:CGRect] = [ButtonEvent:CGRect]()    

    
    private func releaseHapticFeedback() {
        buttonStarted[ButtonEvent.ButtonA] = false
        buttonStarted[ButtonEvent.ButtonB] = false
        buttonStarted[ButtonEvent.ButtonY] = false
        buttonStarted[ButtonEvent.ButtonX] = false
    }
    
    private func checkForHapticFeedback(point: CGPoint) {
        for entry in buttons {
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
    }
    
    private func handleControlPad(point: CGPoint) {
        self.handleInput(point: point, entries: controlPad)
    }
    
    private func handleInput(point: CGPoint, entries: [ButtonEvent:CGRect]) {
        if let emu = emulator {
            for entry in entries {
                if entry.value.contains(point) {
                    emu.updateInput(entry.key, true)
                } else {
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
        if let emu = emulator {
            emu.updateInput(ButtonEvent.ButtonA, false)
            emu.updateInput(ButtonEvent.ButtonB, false)
            emu.updateInput(ButtonEvent.ButtonY, false)
            emu.updateInput(ButtonEvent.ButtonX, false)
        }
    }

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Image("Control Pad")
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
                                self.handleControlPad(point: result.location)
                            }
                            .onEnded() { result in
                                buttonStarted[ButtonEvent.Up] = false
                                self.releaseControlPad()
                            }
                    )
                Spacer()
                VStack {
                    Image("Buttons Misc")
                    Image("Red Button")
                }
                Spacer()
                Image("Buttons")
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .onAppear {
                                    let frame = geometry.frame(in: .local)

                                    let width = frame.maxY * 0.32
                                    let height = frame.maxY * 0.32
                                    
                                    let xButton = CGRect(x: frame.maxX * 0.35, y: frame.minY, width: width, height: height)
                                    let yButton  = CGRect(x: frame.minX, y: frame.maxY * 0.35, width: width, height: height)
                                    let aButton = CGRect(x: frame.maxY * 0.69, y: frame.maxY * 0.35, width: width, height: height)
                                    let bButton = CGRect(x: frame.maxX * 0.35, y: frame.maxY * 0.69, width: width, height: height)
                                    
                                    buttons[ButtonEvent.ButtonA] = aButton
                                    buttons[ButtonEvent.ButtonX] = xButton
                                    buttons[ButtonEvent.ButtonY] = yButton
                                    buttons[ButtonEvent.ButtonB] = bButton
                                }
                        }
                    )
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { result in
                                self.checkForHapticFeedback(point: result.location)
                                self.handleButtons(point: result.location)
                            }
                            .onEnded() { result in
                                self.releaseButtons()
                                self.releaseHapticFeedback()
                            }
                    )
                Spacer()
            }
            Spacer()
        }
        .onAppear {
            self.initButtonState()
        }
    }
}
