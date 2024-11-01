//
//  ControllerMappingsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/1/24.
//

import SwiftUI
import DSEmulatorMobile

enum ButtonMapping {
    case A
    case B
    case X
    case Y
    case Menu
    case Options
    case Home
    case LeftShoulder
    case RightShoulder
    case RightTrigger
    case LeftThumbstick
    case RightThumbstick
    case Up
    case Down
    case Left
    case Right
    case Thumbstick
    case Load
    case Save
}

struct ControllerMappingsView: View {
    @Binding var themeColor: Color
    @Binding var isPresented: Bool
    @Binding var gameController: GameController?
    @Binding var buttonMappings: [ButtonEvent:String]

    @State private var awaitingInput: [String:Bool] = [:]

    private func detectButtonPressed() -> String? {
        if let gamepad = gameController?.controller?.extendedGamepad {
            if gamepad.buttonA.isPressed {
                return "A"
            } else if gamepad.buttonB.isPressed {
                return "B"
            } else if gamepad.buttonX.isPressed {
                return "X"
            } else if gamepad.buttonY.isPressed {
                return "Y"
            } else if gamepad.buttonMenu.isPressed {
                return "Menu"
            } else if gamepad.buttonOptions?.isPressed ?? false {
                return "Options"
            } else if gamepad.buttonHome?.isPressed ?? false {
                return "Home"
            } else if gamepad.leftShoulder.isPressed {
                return "Left shoulder"
            } else if gamepad.rightShoulder.isPressed {
                return "Right shoulder"
            } else if gamepad.leftTrigger.isPressed {
                return "Left trigger"
            } else if gamepad.rightTrigger.isPressed {
                return "Right trigger"
            } else if gamepad.leftThumbstickButton?.isPressed ?? false {
                return "Left thumbstick"
            } else if gamepad.rightThumbstickButton?.isPressed ?? false {
                return "Right thumbstick"
            } else if gamepad.dpad.up.isPressed {
                return "Up"
            } else if gamepad.dpad.down.isPressed {
                return "Down"
            } else if gamepad.dpad.left.isPressed {
                return "Left"
            } else if gamepad.dpad.right.isPressed {
                return "Right"
            }

            return nil
        } else {
            return "Default"
        }
    }

    var body: some View {
        VStack {
            List {
                Section(header: Text("Joypad mappings").foregroundColor(Colors.primaryColor)) {
                    Button {
                        awaitingInput["Up"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["Up"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.Up] = button
                                    }
                                    awaitingInput["Up"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Up")
                            if awaitingInput["Up"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.Up] ?? "Up")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput["Down"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["Down"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.Down] = button
                                    }
                                    awaitingInput["Down"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Down")
                            if awaitingInput["Down"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.Down] ?? "Down")
                                    .foregroundColor(Colors.primaryColor)

                            }

                        }
                    }
                    Button {
                        awaitingInput["Left"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["Left"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.Left] = button
                                    }
                                    awaitingInput["Left"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Left")
                            if awaitingInput["Left"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.Left] ?? "Left")
                                    .foregroundColor(Colors.primaryColor)
                            }


                        }
                    }
                    Button {
                        awaitingInput["Right"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["Right"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.Right] = button
                                    }
                                    awaitingInput["Right"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Right")
                            if awaitingInput["Right"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.Right] ?? "Right")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput["A"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["A"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.ButtonA] = button
                                    }
                                    awaitingInput["A"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("A button")
                            if awaitingInput["A"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.ButtonA] ?? "A")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput["A"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["A"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.ButtonA] = button
                                    }
                                    awaitingInput["A"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("B button")
                            if awaitingInput["B"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.ButtonB] ?? "B")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button{
                        awaitingInput["Y"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["Y"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.ButtonY] = button
                                    }
                                    awaitingInput["Y"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Y button")
                            if awaitingInput["Y"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.ButtonY] ?? "X")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput["X"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["X"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.ButtonX] = button
                                    }
                                    awaitingInput["X"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("X button")
                            if awaitingInput["X"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.ButtonX] ?? "Y")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {
                        awaitingInput["L"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["L"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.ButtonL] = button
                                    }
                                    awaitingInput["L"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("L button")
                            if awaitingInput["L"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.ButtonL] ?? "Left shoulder")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput["R"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["R"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.ButtonR] = button
                                    }
                                    awaitingInput["R"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("R button")
                            if awaitingInput["R"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.ButtonR] ?? "Right shoulder")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {
                        awaitingInput["Start"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["Start"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.Start] = button
                                    }
                                    awaitingInput["Start"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Start")
                            if awaitingInput["Start"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.Start] ?? "Menu")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {
                        awaitingInput["Select"] = true
                        DispatchQueue.global().async {
                            while awaitingInput["Select"] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != "Default" {
                                        buttonMappings[ButtonEvent.Select] = button
                                    }
                                    awaitingInput["Select"] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Select")
                            if awaitingInput["Select"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.Select] ?? "Options")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                }
                Section(header: Text("Hotkey mappings").foregroundColor(Colors.primaryColor)) {
                    Button {
                        
                    } label: {
                        HStack {
                            Text("Control stick mode (SM64 DS only)")
                            if awaitingInput["Stick"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.ControlStick] ?? "L2")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button() {

                    } label: {
                        HStack {
                            Text("Quick load")
                            if awaitingInput["Load"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.QuickLoad] ?? "L3")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {

                    } label: {
                        HStack {
                            Text("Quick save")
                            if awaitingInput["Save"] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[ButtonEvent.QuickSave] ?? "R3")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                }

            }
            Button("Dismiss") {
                isPresented = false
            }
        }
        .font(.custom("Departure Mono", size: 18))
        .foregroundColor(themeColor)
    }
}
