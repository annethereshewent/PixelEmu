//
//  LoadStateEntryView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/20/24.
//

import SwiftUI

struct LoadStateEntryView: View {
    let saveState: SaveState

    @Binding var currentState: SaveState?

    @State private var screenshot = UIImage()

    private let graphicsParser = GraphicsParser()

    var body: some View {
        Button() {
            currentState = saveState
        } label: {
            VStack {
                Image(uiImage: screenshot)
                    .resizable()
                    .frame(width: CGFloat(NDS_SCREEN_WIDTH) * 0.5, height: CGFloat(NDS_SCREEN_HEIGHT))
                Text(saveState.saveName)
            }
        }
        .onAppear() {
            if let image = graphicsParser.fromBytes(bytes: Array(saveState.screenshot), width: NDS_SCREEN_WIDTH, height: NDS_SCREEN_HEIGHT * 2) {
                screenshot = UIImage(cgImage: image)
            }
        }
    }
}
