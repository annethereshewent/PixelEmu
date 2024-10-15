//
//  SaveStateView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI

struct SaveStateView: View {
    let saveState: SaveState
    @State private var screenshot = UIImage()
    
    let graphicsParser = GraphicsParser()
    
    var body: some View {
        VStack {
            Image(uiImage: screenshot)
                .resizable()
                .frame(width: CGFloat(SCREEN_WIDTH) * 0.5, height: CGFloat(SCREEN_HEIGHT))
            Text(saveState.saveName)
        }
        .onAppear() {
            if let image = graphicsParser.fromBytes(bytes: saveState.screenshot, width: SCREEN_WIDTH, height: SCREEN_HEIGHT * 2) {
                screenshot = UIImage(cgImage: image)
            }
        }
    }
}
