//
//  ImportGamesView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportGamesView: View {
    @State private var showRomDialog = false
    
    @Binding var romData: Data?
    @Binding var shouldUpdateGame: Bool
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var path: NavigationPath
    @Binding var gameUrl: URL?
    
    let ndsType = UTType(filenameExtension: "nds", conformingTo: .data)
    var body: some View {
        VStack {
            Text("Import Games")
            HStack {
                Image("Import Cartridge")
                Text("Only \".nds\" files allowed")
                    .frame(width: 200, height: 60)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.custom("Departure Mono", size: 20))
            }
            Spacer()
            Spacer()
            HStack {
                Button {
                    showRomDialog = true
                } label: {
                    Image("Browse")
                    Text("Browse files")
                        .foregroundColor(Colors.accentColor)
                        .font(.custom("Departure Mono", size: 20))
                }
            }
            Spacer()
            Spacer()
            
        }
        .font(.custom("Departure Mono", size: 24))
        .foregroundColor(Colors.primaryColor)
        .fileImporter(
            isPresented: $showRomDialog,
            allowedContentTypes: [ndsType.unsafelyUnwrapped]
        ) { result in
            if let url = try? result.get() {
                if url.startAccessingSecurityScopedResource() {
                    defer {
                        url.stopAccessingSecurityScopedResource()
                    }
                    if let data = try? Data(contentsOf: url) {
                        romData = data
                        shouldUpdateGame = true
                        
                        if bios7Data != nil && bios9Data != nil {
                            gameUrl = url
                            
                            print("(inside ImportGamesView) switching to GameView")
                            path.append("GameView")
                        }
                    }
                }
            }
        }
    }
}
