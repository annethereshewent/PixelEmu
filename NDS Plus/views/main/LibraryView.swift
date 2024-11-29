//
//  LibraryView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI
import DSEmulatorMobile
import GBAEmulatorMobile
import SwiftData

let TWELVE_HOURS = 60 * 60 * 12

enum LibraryFilter {
    case recent
    case all
}

enum LibraryType {
    case nds
    case gba
}

struct LibraryView: View {
    @State private var recentColor = Colors.accentColor
    @State private var allColor = Colors.primaryColor
    @State private var filter = LibraryFilter.recent
    @State private var currentLibrary = LibraryType.nds

    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var emulator: MobileEmulator?
    @Binding var gbaEmulator: GBAEmulator?
    @Binding var gameUrl: URL?
    @Binding var path: NavigationPath
    @Binding var game: Game?
    @Binding var gbaGame: GBAGame?
    @Binding var themeColor: Color

    var libraryTypeText: String {
        switch currentLibrary {
        case .gba: return "GBA"
        case .nds: return "NDS"
        }
    }

    var body: some View {
        VStack {
            Button("\(libraryTypeText) Library") {
                if currentLibrary == .nds {
                    currentLibrary = .gba
                } else {
                    currentLibrary = .nds
                }
            }
            .fontWeight(.bold)
            .foregroundColor(themeColor)
            if currentLibrary == .nds {
                DSLibraryView(
                    recentColor: $recentColor,
                    allColor: $allColor,
                    filter: $filter,
                    romData: $romData,
                    bios7Data: $bios7Data,
                    bios9Data: $bios9Data,
                    firmwareData: $firmwareData,
                    isRunning: $isRunning,
                    workItem: $workItem,
                    emulator: $emulator,
                    gameUrl: $gameUrl,
                    path: $path,
                    game: $game,
                    themeColor: $themeColor
                )
            } else {
                GBALibraryView(
                    recentColor: $recentColor,
                    allColor: $allColor,
                    filter: $filter,
                    romData: $romData,
                    biosData: $bios7Data,
                    isRunning: $isRunning,
                    workItem: $workItem,
                    emulator: $gbaEmulator,
                    gameUrl: $gameUrl,
                    path: $path,
                    game: $gbaGame,
                    themeColor: $themeColor
                )
            }
        }
        .onAppear() {
            recentColor = themeColor
            filter = LibraryFilter.recent
            allColor = Colors.primaryColor
        }
        .font(.custom("Departure Mono", size: 24.0))
        .foregroundColor(Colors.primaryColor)
    }
}
