//
//  ControllerMappingsView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/1/24.
//

import SwiftUI
import DSEmulatorMobile

enum ButtonMapping: Codable {
    case a
    case b
    case x
    case y
    case menu
    case options
    case home
    case leftShoulder
    case rightShoulder
    case leftTrigger
    case rightTrigger
    case leftThumbstick
    case rightThumbstick
    case up
    case down
    case left
    case right
    case noButton

    var description: String {
        switch self {
        case .a: return "A"
        case .b: return "B"
        case .x: return "X"
        case .y: return "Y"
        case .menu: return "Menu"
        case .options: return "Options"
        case .home: return "Home"
        case .leftShoulder: return "Left shoulder"
        case .rightShoulder: return "Right shoulder"
        case .leftTrigger: return "Left trigger"
        case .rightTrigger: return "Right trigger"
        case .rightThumbstick: return "Right thumbstick"
        case .leftThumbstick: return "Left thumbstick"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        case .up: return "Up"
        case .noButton: return "Default"
        }
    }

    static func descriptionToEnum(_ description: String) -> Self {
        switch description {
        case "A": return .a
        case "B": return .b
        case "X": return .x
        case "Y": return .y
        case "Menu": return .menu
        case "Options": return .options
        case "Home": return .home
        case "Left shoulder": return .leftShoulder
        case "Right shoulder": return .rightShoulder
        case "Left trigger": return .leftTrigger
        case "Right trigger": return .rightTrigger
        case "Right thumbstick": return .rightThumbstick
        case "Left thumbstick": return .leftThumbstick
        case "Down": return .down
        case "Left": return .left
        case "Right": return .right
        case "Up": return .up
        case "Default": return .noButton
        default: return .noButton
        }
    }
}

extension ButtonEvent {
    var description: String {
        switch self {
        case .ButtonA: return "A"
        case .ButtonB: return "B"
        case .ButtonX: return "X"
        case .ButtonY: return "Y"
        case .ButtonHome: return "Home"
        case .ButtonL: return "L"
        case .ButtonR: return "R"
        case .Up: return "Up"
        case .Down: return "Down"
        case .Left: return "Left"
        case .Right: return "Right"
        case .QuickLoad: return "Load"
        case .QuickSave: return "Save"
        case .ControlStick: return "Control stick"
        case .Select: return "Select"
        case .Start: return "Start"
        case .MainMenu: return "Main menu"
        }
    }

    static func descriptionToEnum(_ description: String) -> Self {
        switch description {
        case "A": return .ButtonA
        case "B": return .ButtonB
        case "X": return .ButtonX
        case "Y": return .ButtonY
        case "Home": return .ButtonHome
        case "L": return .ButtonL
        case "R": return .ButtonR
        case "Up": return .Up
        case "Down": return .Down
        case "Left": return .Left
        case "Right": return .Right
        case "Load": return .QuickLoad
        case "Save": return .QuickSave
        case "Control stick": return .ControlStick
        case "Select": return .Select
        case "Start": return .Start
        case "Main menu": return .MainMenu
        default: return .MainMenu
        }
    }
}

struct ControllerMappingsView: View {
    @Binding var themeColor: Color
    @Binding var isPresented: Bool
    @Binding var gameController: GameController?
    @Binding var buttonMappings: [ButtonEvent:ButtonMapping]

    @State private var awaitingInput: [ButtonEvent:Bool] = [:]

    private func detectButtonPressed() -> ButtonMapping? {
        if let gamepad = gameController?.controller?.extendedGamepad {
            if gamepad.buttonA.isPressed {
                return .a
            } else if gamepad.buttonB.isPressed {
                return .b
            } else if gamepad.buttonX.isPressed {
                return .x
            } else if gamepad.buttonY.isPressed {
                return .y
            } else if gamepad.buttonMenu.isPressed {
                return .menu
            } else if gamepad.buttonOptions?.isPressed ?? false {
                return .options
            } else if gamepad.buttonHome?.isPressed ?? false {
                return .home
            } else if gamepad.leftShoulder.isPressed {
                return .leftShoulder
            } else if gamepad.rightShoulder.isPressed {
                return .rightShoulder
            } else if gamepad.leftTrigger.isPressed {
                return .leftTrigger
            } else if gamepad.rightTrigger.isPressed {
                return .rightTrigger
            } else if gamepad.leftThumbstickButton?.isPressed ?? false {
                return .leftThumbstick
            } else if gamepad.rightThumbstickButton?.isPressed ?? false {
                return .rightThumbstick
            } else if gamepad.dpad.up.isPressed {
                return .up
            } else if gamepad.dpad.down.isPressed {
                return .down
            } else if gamepad.dpad.left.isPressed {
                return .left
            } else if gamepad.dpad.right.isPressed {
                return .right
            }

            return nil
        } else {
            return .noButton
        }
    }

    var body: some View {
        VStack {
            List {
                Section(header: Text("Joypad mappings").foregroundColor(Colors.primaryColor)) {
                    Button {
                        awaitingInput[.Up] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.Up] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.Up] = button
                                    }
                                    awaitingInput[.Up] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Up")
                            if awaitingInput[.Up] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.Up]?.description ?? "Up")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput[.Down] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.Down] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.Down] = button
                                    }
                                    awaitingInput[.Down] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Down")
                            if awaitingInput[.Down] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.Down]?.description ?? "Down")
                                    .foregroundColor(Colors.primaryColor)

                            }

                        }
                    }
                    Button {
                        awaitingInput[.Left] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.Left] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.Left] = button
                                    }
                                    awaitingInput[.Left] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Left")
                            if awaitingInput[.Left] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.Left]?.description ?? "Left")
                                    .foregroundColor(Colors.primaryColor)
                            }


                        }
                    }
                    Button {
                        awaitingInput[.Right] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.Right] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.Right] = button
                                    }
                                    awaitingInput[.Right] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Right")
                            if awaitingInput[.Right] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.Right]?.description ?? "Right")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput[.ButtonA] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.ButtonA] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.ButtonA] = button
                                    }
                                    awaitingInput[.ButtonA] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("A button")
                            if awaitingInput[.ButtonA] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.ButtonA]?.description ?? "B")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput[.ButtonB] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.ButtonB] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.ButtonB] = button
                                    }
                                    awaitingInput[.ButtonB] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("B button")
                            if awaitingInput[.ButtonB] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.ButtonB]?.description ?? "A")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button{
                        awaitingInput[.ButtonY] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.ButtonY] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.ButtonY] = button
                                    }
                                    awaitingInput[.ButtonY] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Y button")
                            if awaitingInput[.ButtonY] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.ButtonY]?.description ?? "X")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput[.ButtonX] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.ButtonX] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.ButtonX] = button
                                    }
                                    awaitingInput[.ButtonX] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("X button")
                            if awaitingInput[.ButtonX] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.ButtonX]?.description ?? "Y")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {
                        awaitingInput[.ButtonL] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.ButtonL] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.ButtonL] = button
                                    }
                                    awaitingInput[.ButtonL] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("L button")
                            if awaitingInput[.ButtonL] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.ButtonL]?.description ?? "Left shoulder")
                                    .foregroundColor(Colors.primaryColor)
                            }

                        }
                    }
                    Button {
                        awaitingInput[.ButtonR] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.ButtonR] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.ButtonR] = button
                                    }
                                    awaitingInput[.ButtonR] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("R button")
                            if awaitingInput[.ButtonR] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.ButtonR]?.description ?? "Right shoulder")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {
                        awaitingInput[.Start] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.Start] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.Start] = button
                                    }
                                    awaitingInput[.Start] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Start")
                            if awaitingInput[.Start] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.Start]?.description ?? "Menu")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {
                        awaitingInput[.Select] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.Select] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.Select] = button
                                    }
                                    awaitingInput[.Select] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Select")
                            if awaitingInput[.Select] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.Select]?.description ?? "Options")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                }
                Section(header: Text("Hotkey mappings").foregroundColor(Colors.primaryColor)) {
                    Button {
                        awaitingInput[.MainMenu] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.MainMenu] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.MainMenu] = button
                                    }
                                    awaitingInput[.MainMenu] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Main menu (hold for 5 seconds)")
                            if awaitingInput[.MainMenu] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.MainMenu]?.description ?? "Home")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {
                        awaitingInput[.ControlStick] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.ControlStick] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.ControlStick] = button
                                    }
                                    awaitingInput[.ControlStick] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Control stick mode (SM64 DS only)")
                            if awaitingInput[.ControlStick] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.ControlStick]?.description ?? "L2")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button() {
                        awaitingInput[.QuickLoad] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.QuickLoad] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.QuickLoad] = button
                                    }
                                    awaitingInput[.QuickLoad] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Quick load")
                            if awaitingInput[.QuickLoad] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.QuickLoad]?.description ?? "L3")
                                    .foregroundColor(Colors.primaryColor)
                            }
                        }
                    }
                    Button {
                        awaitingInput[.QuickSave] = true
                        DispatchQueue.global().async {
                            while awaitingInput[.QuickSave] ?? false {
                                if let button = detectButtonPressed() {
                                    if button != .noButton {
                                        buttonMappings[.QuickSave] = button
                                    }
                                    awaitingInput[.QuickSave] = false
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text("Quick save")
                            if awaitingInput[.QuickSave] ?? false {
                                Spacer()
                                ProgressView()
                            } else {
                                Spacer()
                                Text(buttonMappings[.QuickSave]?.description ?? "R3")
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
        .onChange(of: buttonMappings) {
            do {
                let defaults = UserDefaults.standard

                let buttonMappingsEncoded = try JSONEncoder().encode(Dictionary(uniqueKeysWithValues: buttonMappings.map{ key, value in (key.description, value) }))

                defaults.set(buttonMappingsEncoded, forKey: "buttonMappings")
            } catch {
                print(error)
            }
        }
    }
}
