//
//  SaveStateView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI
import DSEmulatorMobile

struct SaveStateView: View {
    let gameType: GameType
    let saveState: any Snapshottable
    @State private var screenshot = UIImage()
    @State private var isPopoverPresented = false

    @Binding var action: SaveStateAction
    @Binding var currentState: (any Snapshottable)?

    let graphicsParser = GraphicsParser()

    var width: Int {
        switch gameType {
        case .nds: return NDS_SCREEN_WIDTH
        case .gba: return GBA_SCREEN_WIDTH
        case .gbc: return GBC_SCREEN_WIDTH
        }
    }

    var height: Int {
        switch gameType {
        case .nds: return NDS_SCREEN_HEIGHT * 2
        case .gba: return GBA_SCREEN_HEIGHT
        case .gbc: return GBC_SCREEN_HEIGHT
        }
    }

    var body: some View {
        Button() {
            isPopoverPresented = !isPopoverPresented
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
