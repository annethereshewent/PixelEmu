//
//  GamesListView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import SwiftUI
import DSEmulatorMobile
import SwiftData

struct GamesListView: View {
    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var emulator: MobileEmulator?
    @Binding var gameUrl: URL?
    @Binding var path: NavigationPath
    
    @Query private var games: [Game] = []
    
    var body: some View {
        if games.count > 0 {
            List {
                Section(header: Text("Games")) {
                    ForEach(games) { game in
                        HStack {
                            if let image = GraphicsParser().fromBytes(bytes: game.gameIcon, width: 32, height: 32) {
                                Image(uiImage: image)
                            }
                            Button(game.gameName.removingPercentEncoding!) {
                                // refresh the url's bookmark
                                var isStale = false
                                if let url = try? URL(
                                    resolvingBookmarkData: game.bookmark,
                                    options: [.withoutUI],
                                    relativeTo: nil,
                                    bookmarkDataIsStale: &isStale
                                ) {
                                    if url.startAccessingSecurityScopedResource() {
                                        gameUrl = url
                                        defer {
                                            url.stopAccessingSecurityScopedResource()
                                        }
                                        if let data = try? Data(contentsOf: url) {
                                            romData = data
                                            
                                            if bios7Data != nil &&
                                                bios9Data != nil &&
                                                firmwareData != nil
                                            {
                                                print("canceling shit")
                                                emulator = nil
                                                workItem?.cancel()
                                                isRunning = false
                                                
                                                workItem = nil
                                                
                                                path.append("GameView")
                                            }
                                        }
                                    }
                                }
                                
                            }
                        }
                    }
                }
            }
        } else {
            Spacer()
            Spacer()
        }
       
    }
}

