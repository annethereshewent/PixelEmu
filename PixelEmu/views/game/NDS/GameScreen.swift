//
//  GameScreen.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/4/24.
//

import Foundation
import UIKit

class GameScreen: UIView {
    var image: CGImage?

    init(image: CGImage?, frame: CGRect) {
        self.image = image
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        guard let image = image else { return }

        let imageRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height)

        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1.0, y: -1.0)

        context.draw(image, in: imageRect)
    }
}
