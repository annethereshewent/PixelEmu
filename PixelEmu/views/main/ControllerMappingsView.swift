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
    case cross
    case square
    case circle
    case triangle
    case start
    case select
    case home
    case l1
    case r1
    case leftStick
    case rightStick
    case l2
    case r2
    case up
    case down
    case left
    case right
    case noButton

    var description: String {
        switch self {
        case .cross: return "Cross"
        case .circle: return "Circle"
        case .triangle: return "Triangle"
        case .square: return "Square"
        case .start: return "Start"
        case .select: return "Select"
        case .home: return "Home"
        case .l1: return "L1"
        case .l2: return "L2"
        case .leftStick: return "Left Stick"
        case .rightStick: return "Right Stick"
        case .down: return "Down"
        case .left: return "Left"
        case .right: return "Right"
        case .up: return "Up"
        case .noButton: return "Default"
        case .r1: return "R1"
        case .r2: return "R2"
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
                        pressedButton: .ButtonA,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "B",
                        buttonText: "A button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonB,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "A",
                        buttonText: "B button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonY,
                        buttonMappings: $buttonMappings,
                        buttonDict: $buttonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "X",
                        buttonText: "Y button"
                    )
                    ControllerMappingButtonView(
                        pressedButton: .ButtonX,
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
                        pressedButton: .ControlStickMode,
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

                let toEncode = buttonDict.map{ key, value in (key, String(value.rawValue)) }

                let buttonMappingsEncoded = try JSONEncoder().encode(Dictionary(uniqueKeysWithValues: toEncode))

                defaults.set(buttonMappingsEncoded, forKey: "buttonMappings")
            } catch {
                print(error)
            }
        }
    }
}
