//
//  GameController.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/17/24.
//

import Foundation
import GameController
import DSEmulatorMobile

@Observable
class GameController {
    let eventListenerClosure: (GCController?) -> Void
    
    var controller: GCController? = GCController()
    
    init(closure: @escaping (GCController?) -> Void) {
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
        
        print("Controller connected")
        
        eventListenerClosure(self.controller)
        
        controller?.physicalInputProfile.buttons[GCInputButtonHome]?.preferredSystemGestureState = GCControllerElement.SystemGestureState.disabled
    }
}
