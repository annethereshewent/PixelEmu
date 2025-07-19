//
//  GameController.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/17/24.
//

import Foundation
import GameController
import DSEmulatorMobile

enum PressedButton: Int {
    case ButtonCross = 0
    case ButtonCircle = 1
    case ButtonSquare = 2
    case ButtonTriangle = 3
    case Select = 4
    case Start = 6
    case ButtonL = 9
    case ButtonR = 10
    case Up = 12
    case Down = 13
    case Left = 14
    case Right = 15
    case QuickSave = 16
    case QuickLoad = 17
    case MainMenu = 18
    case HomeButton = 19
    case ControlStick = 20
}

@Observable
class GameController {
    let eventListenerClosure: (GCController) -> Void

    var controller: GCController? = GCController()

    init(closure: @escaping (GCController) -> Void) {
        eventListenerClosure = closure
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleControllerDidConnect),
            name: NSNotification.Name.GCControllerDidConnect, object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleControllerDidDisconnect),
            name: NSNotification.Name.GCControllerDidDisconnect,
            object: nil
        )


        if let controller = GCController.controllers().first {
            self.controller = controller
            self.controller?.physicalInputProfile.buttons[GCInputButtonHome]?.preferredSystemGestureState = GCControllerElement.SystemGestureState.disabled

            eventListenerClosure(controller)
        }
    }

    @objc private func handleControllerDidDisconnect(_ notification: Notification) {
        self.controller = nil
    }

    @objc private func handleControllerDidConnect(_ notification: Notification) {
        guard let gameController = notification.object as? GCController else {
            return
        }

        self.controller = gameController

        eventListenerClosure(gameController)

        gameController.physicalInputProfile.buttons[GCInputButtonHome]?.preferredSystemGestureState = GCControllerElement.SystemGestureState.disabled
    }
}
