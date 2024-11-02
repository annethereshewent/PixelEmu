//
//  LoadStateEntryView.swift
//  NDS Plus
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
                    .frame(width: CGFloat(SCREEN_WIDTH) * 0.5, height: CGFloat(SCREEN_HEIGHT))
                Text(saveState.saveName)
            }
        }
        .onAppear() {
            if let image = graphicsParser.fromBytes(bytes: saveState.screenshot, width: SCREEN_WIDTH, height: SCREEN_HEIGHT * 2) {
                screenshot = UIImage(cgImage: image)
            }
        }
    }
}
