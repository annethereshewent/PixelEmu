//
//  OrientationInfo.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/28/24.
//

import Foundation
import UIKit

// see https://forums.developer.apple.com/forums/thread/126878
final class OrientationInfo: ObservableObject {
    enum Orientation {
        case portrait
        case landscape
    }

    @Published var orientation: Orientation

    private var _observer: NSObjectProtocol?

    init() {
        // fairly arbitrary starting value for 'flat' orientations
        if UIDevice.current.orientation.isLandscape {
            self.orientation = .landscape
        }
        else {
            self.orientation = .portrait
        }

        // unowned self because we unregister before self becomes invalid
        _observer = NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification, object: nil, queue: nil) { [unowned self] note in
            guard let device = note.object as? UIDevice else {
                return
            }
            if device.orientation.isPortrait {
                self.orientation = .portrait
            }
            else if device.orientation.isLandscape {
                self.orientation = .landscape
            }
        }
    }

    deinit {
        if let observer = _observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
