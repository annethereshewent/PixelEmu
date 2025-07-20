//
//  ControllerMappingButtonView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 11/2/24.
//

import SwiftUI
import DSEmulatorMobile
import GBAEmulatorMobile

struct ControllerMappingButtonView: View {
    var pressedButton: PressedButton
    @Binding var buttonMappings: [PressedButton:ButtonMapping]
    @Binding var buttonDict: [ButtonMapping:PressedButton]
    @Binding var awaitingInput: [PressedButton:Bool]
    @Binding var gameController: GameController?

    var defaultButton: String
    var buttonText: String

    private func detectButtonPressed() -> ButtonMapping {
        if let gamepad = gameController?.controller?.extendedGamepad {
            if gamepad.buttonA.isPressed {
                return .cross
            } else if gamepad.buttonB.isPressed {
                return .circle
            } else if gamepad.buttonX.isPressed {
                return .square
            } else if gamepad.buttonY.isPressed {
                return .triangle
            } else if gamepad.buttonMenu.isPressed {
                return .start
            } else if gamepad.buttonOptions?.isPressed ?? false {
                return .select
            } else if gamepad.buttonHome?.isPressed ?? false {
                return .home
            } else if gamepad.leftShoulder.isPressed {
                return .l1
            } else if gamepad.rightShoulder.isPressed {
                return .r1
            } else if gamepad.leftTrigger.isPressed {
                return .l2
            } else if gamepad.rightTrigger.isPressed {
                return .r2
            } else if gamepad.leftThumbstickButton?.isPressed ?? false {
                return .leftStick
            } else if gamepad.rightThumbstickButton?.isPressed ?? false {
                return .rightStick
            } else if gamepad.dpad.up.isPressed {
                return .up
            } else if gamepad.dpad.down.isPressed {
                return .down
            } else if gamepad.dpad.left.isPressed {
                return .left
            } else if gamepad.dpad.right.isPressed {
                return .right
            }
        }

        return .noButton
    }

    var body: some View {
        Button {
            awaitingInput[pressedButton] = true
            DispatchQueue.global().async {
                while awaitingInput[pressedButton]! {
                    let button = detectButtonPressed()
                    if button != .noButton {
                        if let switchEvent = buttonDict[button], let oldButton = buttonMappings[pressedButton] {
                            buttonMappings[switchEvent] = oldButton
                        }
                        buttonMappings[pressedButton] = button
                        awaitingInput[pressedButton] = false
                    }
                }
            }
        } label: {
            HStack {
                Text(buttonText)
                if awaitingInput[pressedButton] ?? false {
                    Spacer()
                    ProgressView()
                } else {
                    Spacer()
                    Text(buttonMappings[pressedButton]?.description ?? defaultButton)
                        .foregroundColor(Colors.primaryColor)
                }

            }
        }
    }
}
