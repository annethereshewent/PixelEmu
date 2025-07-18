//
//  LibraryView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI
import DSEmulatorMobile
import GBAEmulatorMobile
import GBCEmulatorMobile
import SwiftData

let TWELVE_HOURS = 60 * 60 * 12

enum LibraryFilter {
    case recent
    case all
}

struct LibraryView: View {
    @State private var recentColor = Colors.accentColor
    @State private var allColor = Colors.primaryColor
    @State private var filter = LibraryFilter.recent

    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var gbaBiosData: Data?
    @Binding var firmwareData: Data?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var emulator: MobileEmulator?
    @Binding var gbaEmulator: GBAEmulator?
    @Binding var gbcEmulator: GBCMobileEmulator?
    @Binding var gameUrl: URL?
    @Binding var path: NavigationPath
    @Binding var game: (any Playable)?
    @Binding var gbaGame: (any Playable)?
    @Binding var themeColor: Color
    @Binding var isPaused: Bool
    @Binding var currentLibrary: String

    var body: some View {
        VStack {
            Text("\(currentLibrary.uppercased()) library")
            TabView(selection: $currentLibrary) {
                MainLibraryView(
                    gameType: .nds,
                    recentColor: $recentColor,
                    allColor: $allColor,
                    filter: $filter,
                    romData: $romData,
                    gbaBiosData: $gbaBiosData,
                    bios7Data: $bios7Data,
                    bios9Data: $bios9Data,
                    firmwareData: $firmwareData,
                    isRunning: $isRunning,
                    workItem: $workItem,
                    emulator: $emulator,
                    gbaEmulator: $gbaEmulator,
                    gbcEmulator: $gbcEmulator,
                    gameUrl: $gameUrl,
                    path: $path,
                    game: $game,
                    themeColor: $themeColor,
                    isPaused: $isPaused
                )
                .tag("nds")
                MainLibraryView(
                    gameType: .gba,
                    recentColor: $recentColor,
                    allColor: $allColor,
                    filter: $filter,
                    romData: $romData,
                    gbaBiosData: $gbaBiosData,
                    bios7Data: $bios7Data,
                    bios9Data: $bios9Data,
                    firmwareData: $firmwareData,
                    isRunning: $isRunning,
                    workItem: $workItem,
                    emulator: $emulator,
                    gbaEmulator: $gbaEmulator,
                    gbcEmulator: $gbcEmulator,
                    gameUrl: $gameUrl,
                    path: $path,
                    game: $gbaGame,
                    themeColor: $themeColor,
                    isPaused: $isPaused
                )
                .tag("gba")
            }.tabViewStyle(.page)

        }
        .onAppear() {
            recentColor = themeColor
            filter = LibraryFilter.recent
            allColor = Colors.primaryColor

            let defaults = UserDefaults.standard

            if let current = defaults.string(forKey: "currentLibrary") {
                currentLibrary = current
            }
        }
        .onChange(of: currentLibrary) {
            let defaults = UserDefaults.standard

            defaults.setValue(currentLibrary, forKey: "currentLibrary")
        }
        .font(.custom("Departure Mono", size: 24.0))
        .foregroundColor(Colors.primaryColor)
    }
}
