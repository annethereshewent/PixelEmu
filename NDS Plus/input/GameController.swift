//
//  GameController.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/17/24.
//

import Foundation
import GameController

class GameController {
    var controller = GCController()
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.handleControllerDidConnect),
            name: NSNotification.Name.GCControllerDidConnect, object: nil
        )
        if let controller = GCController.controllers().first {
            self.controller = controller
        }
    }
    
    @objc private func handleControllerDidConnect(_ notification: Notification) {
        guard let gameController = notification.object as? GCController else {
            return
        }
        
        self.controller = gameController
    }
}
