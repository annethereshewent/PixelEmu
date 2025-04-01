//
//  N64ListView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//

import SwiftUI
import SwiftData

struct N64ListView: View {
    @Environment(\.modelContext) private var context

    @Binding var romData: Data?

    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var gameUrl: URL?
    @Binding var path: NavigationPath
    @Binding var game: N64Game?
    @Binding var filter: LibraryFilter
    @Binding var themeColor: Color
    @Binding var isPaused: Bool

    @State private var showResumeDialog = false
    @State private var resumeGame = false
    @State private var settingChanged = false

    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteAction: () -> Void = {}
    @State private var gameToDelete: N64Game?
    @State private var showGameError = false

    @State private var isLoadStatesPresented = false
    @State private var selectedGame: N64Game?
    @Query private var games: [N64Game]

    private var filteredGames: [N64Game] {
        switch filter {
        case .all:
            return games.sorted {
                $0.lastPlayed > $1.lastPlayed
            }
        case .recent:
            return games.filter { game in
                let today = Date.now
                let diff = today.timeIntervalSince1970 - game.lastPlayed.timeIntervalSince1970

                return diff <= Double(TWELVE_HOURS)
            }.sorted {
                $0.lastPlayed > $1.lastPlayed
            }
        }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private func startNewGame(_ game: N64Game? = nil) {
        // emulator = nil
        workItem?.cancel()
        isRunning = false

        isPaused = false

        workItem = nil

        if let game = game {
            self.game = game
            game.lastPlayed = Date.now
            path.append("N64GameView")
        } else if let game = self.game {
            game.lastPlayed = Date.now
            path.append("N64GameView")
        } else {
            showGameError = true
        }
    }

    private func updateLastPlayed() {
        if let game = game {
            game.lastPlayed = Date.now
        }
    }

    var body: some View {
        if games.count > 0 {
            ZStack {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(filteredGames) { game in
                            N64EntryViewWrapper(
                                showDeleteConfirmation: $showDeleteConfirmation,
                                deleteAction: $deleteAction,
                                gameToDelete: $gameToDelete,
                                isLoadStatesPresented: $isLoadStatesPresented,
                                selectedGame: $selectedGame,
                                themeColor: $themeColor,
                                game: game
                            ) {
                                var isStale = false
                                do {
                                    let url = try URL(
                                        resolvingBookmarkData: game.bookmark,
                                        options: [.withoutUI],
                                        relativeTo: nil,
                                        bookmarkDataIsStale: &isStale
                                    )
                                    if url.startAccessingSecurityScopedResource() {
                                        defer {
                                            url.stopAccessingSecurityScopedResource()
                                        }

                                        // do some other shit here
                                        let data = try Data(contentsOf: url)

                                        // now load the rom and bios
                                        // emulator = GBAEmulator()

                                        romData = data
                                        gameUrl = url

                                        if self.game != nil && self.game! == game {
                                            updateLastPlayed()
                                            showResumeDialog = true
                                        } else {
                                            startNewGame(game)
                                        }
                                    }
                                } catch {
                                    print(error)
                                }
                            }
                        }
                    }
                }
                if showResumeDialog {
                    ResumeGameDialog(
                        showDialog: $showResumeDialog,
                        resumeGame: $resumeGame,
                        settingChanged: $settingChanged,
                        themeColor: $themeColor
                    )
                } else if showDeleteConfirmation {
                    DeleteDialog(
                        showDialog: $showDeleteConfirmation,
                        deleteAction: $deleteAction,
                        themeColor: $themeColor,
                        deleteMessage: "Are you sure you want to remove this game from your library?"
                    )
                } else if showDeleteError {
                    AlertModal(
                        alertTitle: "Oops!",
                        text: "There was an error removing the game.",
                        showAlert: $showDeleteError,
                        themeColor: $themeColor
                    )
                } else if showGameError {
                    AlertModal(
                        alertTitle: "Oops!",
                        text: "There was an error loading the specified game.",
                        showAlert: $showGameError,
                        themeColor: $themeColor
                    )
                }
            }
            .onChange(of: settingChanged) {
                if resumeGame {
                    isPaused = false

                    // this isn't working - pause from swift instead of rust for now
                    // emulator?.setPaused(false)
                    path.append("N64GameView")
                } else {
                    startNewGame()
                }
            }
            .onChange(of: gameToDelete) {
                deleteAction = {
                    if let game = gameToDelete {
                        context.delete(game)
                    } else {
                        showDeleteError = true
                    }
                }
            }
        } else {
            Spacer()
            Spacer()
        }
    }
}

