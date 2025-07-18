//
//  GamesListView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/22/24.
//

import SwiftUI
import DSEmulatorMobile
import GBAEmulatorMobile
import SwiftData

struct GamesListView: View {
    let gameType: GameType = .nds

    @State private var showGameError = false

    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var gbaBios: Data?

    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var emulator: MobileEmulator?
    @Binding var gbaEmulator: GBAEmulator?
    @Binding var gameUrl: URL?
    @Binding var path: NavigationPath
    @Binding var game: (any Playable)?
    @Binding var filter: LibraryFilter
    @Binding var themeColor: Color
    @Binding var isPaused: Bool

    @Query private var games: [Game]
    @Query private var gbaGames: [GBAGame]

    private var filteredGames: [any Playable] {
        var sortedGames: [any Playable] = []

        switch gameType {
        case .nds:
            sortedGames = games
        case .gba:
            sortedGames = gbaGames
        case .gbc:
            sortedGames = []
        }
        switch filter {
        case .all:
            return sortedGames.sorted {
                $0.lastPlayed > $1.lastPlayed
            }
        case .recent:
            return sortedGames.filter { game in
                let today = Date.now
                let diff = today.timeIntervalSince1970 - game.lastPlayed.timeIntervalSince1970

                return diff <= Double(TWELVE_HOURS)
            }.sorted {
                $0.lastPlayed > $1.lastPlayed
            }
        }
    }

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        if games.count > 0 {
            if games[0].type == .nds {
                DSListView(
                    showGameError: $showGameError,
                    gameUrl: $gameUrl,
                    themeColor: $themeColor,
                    romData: $romData,
                    bios7Data: $bios7Data,
                    bios9Data: $bios9Data,
                    firmwareData: $firmwareData,
                    emulator: $emulator,
                    game: $game,
                    workItem: $workItem,
                    isRunning: $isRunning,
                    path: $path,
                    filteredGames: filteredGames as! [Game]
                )
            } else if games[0].type == .gba {
                GBAListView(
                    showGameError: $showGameError,
                    gameUrl: $gameUrl,
                    themeColor: $themeColor,
                    romData: $romData,
                    bios7Data: $bios7Data,
                    bios9Data: $bios9Data,
                    firmwareData: $firmwareData,
                    emulator: $gbaEmulator,
                    game: $game,
                    workItem: $workItem,
                    isRunning: $isRunning,
                    path: $path,
                    isPaused: $isPaused,
                    filteredGames: filteredGames as! [GBAGame]
                )
            }
        }
    }
}

