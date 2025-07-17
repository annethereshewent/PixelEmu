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
    @Binding var buttonEventDict: [ButtonMapping:ButtonEvent]
    @Binding var gbaButtonDict: [ButtonMapping:GBAButtonEvent]
    @State private var buttonMappings: [ButtonEvent:ButtonMapping] = [:]
    @State private var gbaButtonMappings: [GBAButtonEvent:ButtonMapping] = [:]

    @State private var awaitingInput: [ButtonEvent:Bool] = [:]

    var body: some View {
        VStack {
            List {
                Section(header: Text("Joypad mappings").foregroundColor(Colors.primaryColor)) {
                    ControllerMappingButtonView(
                        event: .Up,
                        gbaEvent: .Up,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Up",
                        buttonText: "Up"
                    )
                    ControllerMappingButtonView(
                        event: .Down,
                        gbaEvent: .Down,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Down",
                        buttonText: "Down"
                    )
                    ControllerMappingButtonView(
                        event: .Left,
                        gbaEvent: .Left,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Left",
                        buttonText: "Left"
                    )
                    ControllerMappingButtonView(
                        event: .Right,
                        gbaEvent: .Right,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Right",
                        buttonText: "Right"
                    )
                    ControllerMappingButtonView(
                        event: .ButtonA,
                        gbaEvent: .ButtonA,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "B",
                        buttonText: "A button"
                    )
                    ControllerMappingButtonView(
                        event: .ButtonB,
                        gbaEvent: .ButtonB,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "A",
                        buttonText: "B button"
                    )
                    ControllerMappingButtonView(
                        event: .ButtonY,
                        gbaEvent: nil,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "X",
                        buttonText: "Y button"
                    )
                    ControllerMappingButtonView(
                        event: .ButtonX,
                        gbaEvent: nil,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Y",
                        buttonText: "X button"
                    )
                    ControllerMappingButtonView(
                        event: .ButtonL,
                        gbaEvent: .ButtonL,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Left shoulder",
                        buttonText: "L button"
                    )
                    ControllerMappingButtonView(
                        event: .ButtonR,
                        gbaEvent: .ButtonR,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Right shoulder",
                        buttonText: "R button"
                    )
                    ControllerMappingButtonView(
                        event: .Start,
                        gbaEvent: .Start,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Menu",
                        buttonText: "Start"
                    )
                    ControllerMappingButtonView(
                        event: .Select,
                        gbaEvent: .Select,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Options",
                        buttonText: "Select"
                    )
                }
                Section(header: Text("Hotkey mappings").foregroundColor(Colors.primaryColor)) {
                    ControllerMappingButtonView(
                        event: .MainMenu,
                        gbaEvent: .GameMenu,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Home",
                        buttonText: "Main menu"
                    )
                    ControllerMappingButtonView(
                        event: .ControlStick,
                        gbaEvent: nil,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Left trigger",
                        buttonText: "Control stick mode (SM64 DS only)"
                    )
                    ControllerMappingButtonView(
                        event: .QuickSave,
                        gbaEvent: .QuickSave,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
                        awaitingInput: $awaitingInput,
                        gameController: $gameController,
                        defaultButton: "Left thumbstick",
                        buttonText: "Quick save"
                    )
                    ControllerMappingButtonView(
                        event: .QuickLoad,
                        gbaEvent: .QuickLoad,
                        buttonMappings: $buttonMappings,
                        gbaButtonMappings: $gbaButtonMappings,
                        buttonEventDict: $buttonEventDict,
                        gbaButtonDict: $gbaButtonDict,
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
            for (key, value) in buttonEventDict {
                buttonMappings[value] = key
            }

            for (key, value) in gbaButtonDict {
                gbaButtonMappings[value] = key
            }
        }
        .onChange(of: buttonMappings) {
            do {
                let defaults = UserDefaults.standard

                buttonEventDict = [:]

                for (key, value) in buttonMappings {
                    buttonEventDict[value] = key
                }

                let toEncode = buttonEventDict.map{ key, value in (key, value.description) }

                let buttonMappingsEncoded = try JSONEncoder().encode(Dictionary(uniqueKeysWithValues: toEncode))

                defaults.set(buttonMappingsEncoded, forKey: "buttonMappings")
            } catch {
                print(error)
            }
        }
    }
}
