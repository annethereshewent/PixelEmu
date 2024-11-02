//
//  SaveStateView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI
import DSEmulatorMobile

struct SaveStateView: View {
    @Environment(\.colorScheme) private var colorScheme
    let saveState: SaveState
    @State private var screenshot = UIImage()
    @State private var isPopoverPresented = false
    
    @Binding var action: SaveStateAction
    @Binding var currentState: SaveState?
    
    let graphicsParser = GraphicsParser()
    
    var color: Color {
        if colorScheme == ColorScheme.dark {
            return .white
        } else {
            return .black
        }
    }
    
    var body: some View {
        Button() {
            isPopoverPresented = !isPopoverPresented
        } label: {
            VStack {
                Image(uiImage: screenshot)
                    .resizable()
                    .frame(width: CGFloat(SCREEN_WIDTH) * 0.5, height: CGFloat(SCREEN_HEIGHT))
                Text(saveState.saveName)
            }
        }
        .onAppear() {
            if let image = graphicsParser.fromBytes(bytes: saveState.deleteMe, width: SCREEN_WIDTH, height: SCREEN_HEIGHT * 2) {
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
