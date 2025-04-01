//
//  GBAStateView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 12/6/24.
//

import SwiftUI

struct GBAStateView: View {
    let saveState: GBASaveState
    @State private var screenshot = UIImage()
    @State private var isPopoverPresented = false

    @Binding var action: SaveStateAction
    @Binding var currentState: GBASaveState?

    let graphicsParser = GraphicsParser()

    var body: some View {
        Button() {
            isPopoverPresented = !isPopoverPresented
        } label: {
            VStack {
                Image(uiImage: screenshot)
                    .resizable()
                    .frame(width: CGFloat(GBA_SCREEN_WIDTH) * 0.5, height: CGFloat(GBA_SCREEN_HEIGHT) * 0.5)
                Text(saveState.saveName)
            }
        }
        .onAppear() {
            if let image = graphicsParser.fromBytes(bytes: Array(saveState.screenshot), width: GBA_SCREEN_WIDTH, height: GBA_SCREEN_HEIGHT) {
                screenshot = UIImage(cgImage: image)
            }
        }
        .popover(isPresented: $isPopoverPresented) {
            VStack(alignment: .leading) {
                Button() {
                    currentState = saveState
                    action = .load
                } label: {
                    HStack {
                        Image(systemName: "tray.and.arrow.down")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.yellow)
                        Text("Load save state")
                    }
                }
                Button() {
                    currentState = saveState
                    action = .update
                } label: {
                    HStack {
                        Image(systemName: "tray.and.arrow.up")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.green)
                        Text("Update save state")

                    }
                }
                Button() {
                    currentState = saveState
                    action = .delete
                } label: {
                    HStack {
                        Image(systemName: "xmark.bin")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.red)
                        Text("Delete save state")
                    }
                }
            }
            .presentationCompactAdaptation(.popover)
            .padding()
        }
        .foregroundColor(Colors.primaryColor)
        .font(.custom("Departure Mono", size: 16))
    }
}
