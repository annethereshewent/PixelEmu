//
//  LoadStateEntryView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/20/24.
//

import SwiftUI

struct LoadStateEntryView: View {
    let gameType: GameType
    let saveState: any Snapshottable

    @Binding var currentState: (any Snapshottable)?

    @State private var screenshot = UIImage()

    private let graphicsParser = GraphicsParser()

    var width: Int {
        switch gameType {
        case .nds:
            return NDS_SCREEN_WIDTH
        case .gba:
            return GBA_SCREEN_WIDTH
        case .gbc:
            return GBC_SCREEN_WIDTH
        }
    }

    var height: Int {
        switch gameType {
        case .nds:
            return NDS_SCREEN_HEIGHT * 2
        case .gba:
            return GBA_SCREEN_HEIGHT
        case .gbc:
            return GBC_SCREEN_HEIGHT
        }
    }

    var body: some View {
        Button() {
            currentState = saveState
        } label: {
            VStack {
                Image(uiImage: screenshot)
                    .resizable()
                    .frame(width: CGFloat(width) * 0.5, height: CGFloat(height) * 0.5)
                Text(saveState.saveName)
            }
        }
        .onAppear() {
            if let image = graphicsParser.fromBytes(bytes: Array(saveState.screenshot), width: width, height: height) {
                screenshot = UIImage(cgImage: image)
            }
        }
    }
}
