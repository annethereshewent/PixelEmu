//
//  GamesListViewInner.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/18/25.
//

import SwiftUI

struct GamesListViewInner: View {
    @Environment(\.modelContext) private var context
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    let gameType: GameType

    @State private var showDeleteConfirmation = false
    @State private var showDeleteError = false
    @State private var deleteAction: () -> Void = {}
    @State private var gameToDelete: (any Playable)?

    @State private var showResumeDialog = false
    @State private var resumeGame = false
    @State private var settingChanged = false
    @State private var isLoadStatesPresented = false
    @State private var selectedGame: (any Playable)? = nil

    @State private var dsGame: Game? = nil
    @State private var selectedDsGame: Game? = nil

    @State private var gbaGame: GBAGame? = nil
    @State private var selectedGbaGame: GBAGame? = nil

    @State private var gbcGame: GBCGame? = nil
    @State private var selectedGbcGame: GBCGame? = nil

    @State private var filteredGamesClosure: ((_ game: Game) -> Void)? = nil
    @State private var filteredGbcGamesClosure: ((_ game: GBCGame) -> Void)? = nil
    @State private var filteredGbaGamesClosure: ((_ game: GBAGame) -> Void)? = nil

    @Binding var showGameError: Bool
    @Binding var gameUrl: URL?
    @Binding var themeColor: Color
    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var game: (any Playable)?
    @Binding var workItem: DispatchWorkItem?
    @Binding var isRunning: Bool
    @Binding var path: NavigationPath
    @Binding var isPaused: Bool

    var filteredGames: [Game]? = nil
    var filteredGbcGames: [GBCGame]? = nil
    var filteredGbaGames: [GBAGame]? = nil

    private func updateLastPlayed() {
        switch gameType {
        case .gbc:
            if let game = game as! GBCGame? {
                game.lastPlayed = Date.now
            }
        case .gba:
            if let game = game as! GBAGame? {
                game.lastPlayed = Date.now
            }
        case .nds:
            if let game = game as! Game? {
                game.lastPlayed = Date.now
            }
        }
    }

    private func startNewGame(_ game: (any Playable)? = nil) {
        emulator = nil
        workItem?.cancel()
        isRunning = false

        workItem = nil

        switch gameType {
        case .nds:
            if let game = game as! Game? {
                self.game = game
                game.lastPlayed = Date.now
                path.append("NDSGameView")
            } else if let game = self.game as! Game? {
                game.lastPlayed = Date.now
                path.append("NDSGameView")
            } else {
                showGameError = true
            }
        case .gba:
            if let game = game as! GBAGame? {
                self.game = game
                game.lastPlayed = Date.now
                path.append("NDSGBAGameView")
            } else if let game = self.game as! GBAGame? {
                game.lastPlayed = Date.now
                path.append("NDSGBAGameView")
            } else {
                showGameError = true
            }
        case .gbc:
            if let game = game as! GBCGame? {
                self.game = game
                game.lastPlayed = Date.now
                path.append("NDSGBCGameView")
            } else if let game = self.game as! GBCGame? {
                game.lastPlayed = Date.now
                path.append("NDSGBCGameView")
            } else {
                showGameError = true
            }
        }
    }

    var body: some View {
        ZStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    switch gameType {
                    case .nds:
                        if let filteredGames = filteredGames {
                            ForEach(filteredGames) { game in
                                GameEntryViewWrapper(
                                    showDeleteConfirmation: $showDeleteConfirmation,
                                    deleteAction: $deleteAction,
                                    gameToDelete: $gameToDelete,
                                    isLoadStatesPresented: $isLoadStatesPresented,
                                    selectedGame: $selectedGame,
                                    themeColor: $themeColor,
                                    game: game
                                ) {
                                    filteredGamesClosure!(game)
                                }
                            }
                        }
                    case .gba:
                        if let filteredGbaGames = filteredGbaGames {
                            ForEach(filteredGbaGames) { game in
                                GameEntryViewWrapper(
                                    showDeleteConfirmation: $showDeleteConfirmation,
                                    deleteAction: $deleteAction,
                                    gameToDelete: $gameToDelete,
                                    isLoadStatesPresented: $isLoadStatesPresented,
                                    selectedGame: $selectedGame,
                                    themeColor: $themeColor,
                                    game: game
                                ) {
                                    filteredGbaGamesClosure!(game)
                                }
                            }
                        }
                    case .gbc:
                        if let filteredGbcGames = filteredGbcGames {
                            ForEach(filteredGbcGames) { game in
                                GameEntryViewWrapper(
                                    showDeleteConfirmation: $showDeleteConfirmation,
                                    deleteAction: $deleteAction,
                                    gameToDelete: $gameToDelete,
                                    isLoadStatesPresented: $isLoadStatesPresented,
                                    selectedGame: $selectedGame,
                                    themeColor: $themeColor,
                                    game: game
                                ) {
                                    filteredGbcGamesClosure!(game)
                                }
                            }
                        }
                    }
                }
                .onChange(of: settingChanged) {
                    if resumeGame {
                        emulator?.setPaused(false)
                        switch gameType {
                        case .nds: path.append("NDSGameView")
                        case .gba: path.append("GBAGameView")
                        case .gbc: path.append("GBCGameView")
                        }
                    } else {
                        startNewGame()
                    }
                }
                .onChange(of: game?.gameName) {
                    switch gameType {
                    case .gba: gbaGame = game as! GBAGame?
                    case .nds: dsGame = game as! Game?
                    case .gbc: gbcGame = game as! GBCGame?
                    }
                }
                .onChange(of: selectedGame?.gameName) {
                    switch gameType {
                    case .nds: selectedDsGame = selectedGame as! Game?
                    case .gba: selectedGbaGame = selectedGame as! GBAGame?
                    case .gbc: selectedGbcGame = selectedGame as! GBCGame?
                    }
                }
                .onChange(of: gameToDelete?.gameName) {
                    deleteAction = {
                        if let game = gameToDelete {
                            switch gameType {
                            case .gba: context.delete(game as! GBAGame)
                            case .gbc: context.delete(game as! GBCGame)
                            case .nds: context.delete(game as! Game)
                            }
                        } else {
                            showDeleteError = true
                        }
                    }
                }
                .onAppear() {
                    switch gameType {
                    case .nds: dsGame = game as! Game?
                    case .gba: gbaGame = game as! GBAGame?
                    case .gbc: gbcGame = game as! GBCGame?
                    }

                    filteredGamesClosure = { game in
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

                                }

                                if bios7Data != nil &&
                                    bios9Data != nil
                                {
                                    let dsGame = self.game as! Game?
                                    if dsGame != nil && dsGame! == game {
                                        updateLastPlayed()
                                        showResumeDialog = true
                                    } else {
                                        startNewGame(game)
                                    }
                                }

                            }
                        }

                    }

                    filteredGbaGamesClosure = { game in
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

                                }

                                let gbaGame = self.game as! GBAGame?
                                if gbaGame != nil && gbaGame! == game {
                                    updateLastPlayed()
                                    showResumeDialog = true
                                } else {
                                    startNewGame(game)
                                }

                            }
                        }
                    }

                    filteredGbcGamesClosure = { game in
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

                                }

                                let gbcGame = self.game as! GBCGame?
                                if gbcGame != nil && gbcGame! == game {
                                    updateLastPlayed()
                                    showResumeDialog = true
                                } else {
                                    startNewGame(game)
                                }

                            }
                        }
                    }

                }
                .sheet(isPresented: $isLoadStatesPresented) {
                    LoadStatesView(
                        emulator: $emulator,
                        selectedGame: $selectedDsGame,
                        game: $dsGame,
                        isPresented: $isLoadStatesPresented,
                        romData: $romData,
                        bios7Data: $bios7Data,
                        bios9Data: $bios9Data,
                        firmwareData: $firmwareData,
                        path: $path,
                        isRunning: $isRunning,
                        workItem: $workItem,
                        gameUrl: $gameUrl
                    )
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
        
    }
}

