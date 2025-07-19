//
//  ControllerMappingsView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 11/1/24.
//

import SwiftUI
import DSEmulatorMobile
import GBAEmulatorMobile

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

struct ControllerMappingsView: View {
    @Binding var themeColor: Color
    @Binding var isPresented: Bool
    @Binding var gameController: GameController?
    @Binding var buttonDict: [ButtonMapping:PressedButton]
    @State private var buttonMappings: [PressedButton:ButtonMapping] = [:]
    @State private var awaitingInput: [PressedButton:Bool] = [:]

    var body: some View {
        VStack {
            List {
                Section(header: Text("Joypad mappings").foregroundColor(Colors.primaryColor)) {
                    ControllerMappingButtonView(
                        pressedButton: .Up,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Up",
                        buttonText: "Up"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .Down,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Down",
                        buttonText: "Down"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .Left,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Left",
                        buttonText: "Left"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .Right,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Right",
                        buttonText: "Right"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonCross,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "B",
                        buttonText: "A button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonCircle,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "A",
                        buttonText: "B button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonTriangle,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "X",
                        buttonText: "Y button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonSquare,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Y",
                        buttonText: "X button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonL,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Left shoulder",
                        buttonText: "L button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonR,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Right shoulder",
                        buttonText: "R button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .Start,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Menu",
                        buttonText: "Start"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .Select,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Options",
                        buttonText: "Select"
                    )
                }
                Section(header: Text("Hotkey mappings").foregroundColor(Colors.primaryColor)) {
                    ControllerMappingButtonView(
                        pressedButton: .MainMenu,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Home",
                        buttonText: "Main menu"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ControlStick,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Left trigger",
                        buttonText: "Control stick mode (SM64 DS only)"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .QuickSave,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Left thumbstick",
                        buttonText: "Quick save"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .QuickLoad,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Right thumbstick",
                        buttonText: "Quick load"
                    )
                }

            }
            Button("Dismiss") {
                isPresented = false
            }
        }
        .font(.custom("Departure Mono", size: 18))
        .foregroundColor(themeColor)
        .onAppear() {
            for (key, value) in buttonDict {
                buttonMappings[value] = key
            }
        }
        .onChange(of: buttonMappings) {
            do {
                let defaults = UserDefaults.standard

                buttonDict = [:]

                for (key, value) in buttonMappings {
                    buttonDict[value] = key
                }

                let toEncode = buttonDict.map{ key, value in (key, value.rawValue) }

                let buttonMappingsEncoded = try JSONEncoder().encode(Dictionary(uniqueKeysWithValues: toEncode))

                defaults.set(buttonMappingsEncoded, forKey: "buttonMappings")
            } catch {
                print(error)
            }
        }
    }
}
