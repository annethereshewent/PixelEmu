//
//  GameScreenView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/4/24.
//

import Foundation
import SwiftUI

struct GameScreenView: UIViewRepresentable {
    @Binding var image: CGImage?
    let frame = CGRect(x: 0, y: 0, width: Int(Float(SCREEN_WIDTH) * SCREEN_RATIO), height: Int(Float(SCREEN_HEIGHT) * SCREEN_RATIO))

    func makeUIView(context: Context) -> GameScreen {
        return GameScreen(image: image, frame: frame)
    }

    func updateUIView(_ uiView: GameScreen, context: Context) {
        uiView.image = image
        uiView.setNeedsDisplay()
    }
}
