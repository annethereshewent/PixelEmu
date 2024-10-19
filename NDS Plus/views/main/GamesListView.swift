//
//  GamesListView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import SwiftUI
import DSEmulatorMobile

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
    @Binding var game: Game?
    let games: [Game]
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        if games.count > 0 {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(games) { game in
                        GameEntryView(game: game) {
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
                                            bios9Data != nil
                                        {
                                            emulator = nil
                                            workItem?.cancel()
                                            isRunning = false
                                            
                                            workItem = nil
                                            
                                            self.game = game
                                
                                            path.append("GameView")
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

