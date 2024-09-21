//
//  NFingerGestureRecognizer.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/20/24.
//

// see https://stackoverflow.com/questions/61566929/swiftui-multitouch-gesture-multiple-gestures
import Foundation
import UIKit

class NFingerGestureRecognizer: UIGestureRecognizer {

    var tappedCallback: ([UITouch:CGPoint]) -> Void

    var touchViews = [UITouch:CGPoint]()

    init(target: Any?, tappedCallback: @escaping ([UITouch:CGPoint]) -> ()) {
        self.tappedCallback = tappedCallback
        super.init(target: target, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            let location = touch.location(in: touch.view)
            touchViews[touch] = location
        }
        tappedCallback(touchViews)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            let newLocation = touch.location(in: touch.view)

            touchViews[touch] = newLocation
        }
        tappedCallback(touchViews)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        for touch in touches {
            touchViews.removeValue(forKey: touch)
        }
        tappedCallback(touchViews)
    }
}
