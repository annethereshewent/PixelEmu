//
//  ControllerMappingButtonView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/2/24.
//

import SwiftUI
import DSEmulatorMobile

struct ControllerMappingButtonView: View {
    var event: ButtonEvent
    @Binding var buttonMappings: [ButtonEvent:ButtonMapping]
    @Binding var awaitingInput: [ButtonEvent:Bool]
    @Binding var gameController: GameController?

    var defaultButton: String
    var buttonText: String

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
        Button {
            awaitingInput[event] = true
            DispatchQueue.global().async {
                while awaitingInput[event] ?? false {
                    if let button = detectButtonPressed() {
                        if button != .noButton {
                            buttonMappings[event] = button
                        }
                        awaitingInput[event] = false
                    }
                }
            }
        } label: {
            HStack {
                Text(buttonText)
                if awaitingInput[event] ?? false {
                    Spacer()
                    ProgressView()
                } else {
                    Spacer()
                    Text(buttonMappings[event]?.description ?? defaultButton)
                        .foregroundColor(Colors.primaryColor)
                }

            }
        }
    }
}
