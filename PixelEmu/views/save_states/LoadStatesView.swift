//
//  LoadStatesView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/20/24.
//

import SwiftUI
import DSEmulatorMobile
import GBAEmulatorMobile
import GBCEmulatorMobile

struct LoadStatesView: View {
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var selectedGame: (any Playable)?
    @Binding var game: (any Playable)?
    @Binding var isPresented: Bool

    @Binding var romData: Data?
    @Binding var biosData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var path: NavigationPath
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var gameUrl: URL?
    @State private var currentState: (any Snapshottable)? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private func loadGbState(saveState: any Snapshottable, _ gameType: GameType) throws {
        if let emu = emulator, let selectedGame = selectedGame {
            var isStale = false
            let url = try URL(resolvingBookmarkData: saveState.bookmark, bookmarkDataIsStale: &isStale)
            let data = try Array(Data(contentsOf: url))

            var isStale2 = false
            let romUrl = try URL(resolvingBookmarkData: selectedGame.bookmark, bookmarkDataIsStale: &isStale2)
            let romData = try Data(contentsOf: romUrl)

            data.withUnsafeBufferPointer { ptr in
                emu.loadSaveState(ptr)
            }

            if gameType == .gba {
                if let biosData = biosData {
                    Array(biosData).withUnsafeBufferPointer { ptr in
                        try! emu.loadBios(ptr)
                    }

                } else {
                    print("[Warning] GBA selected but BIOS not found. Emulation may fail.")
                    return
                }
            }

            let romArr = Array(romData)

            romArr.withUnsafeBufferPointer { ptr in
                emu.reloadRom(ptr)
            }

            workItem?.cancel()
            isRunning = true

            workItem = nil

            gameUrl = url

            game = selectedGame

            isPresented = false

            if gameType == .gba {
                path.append("GBAGameView")
            } else {
                path.append("GBCGameView")
            }

        } else {
            isPresented = false
        }
    }

    private func loadDsState(saveState: any Snapshottable) throws {
        var isStale = false
        let url = try URL(resolvingBookmarkData: saveState.bookmark, bookmarkDataIsStale: &isStale)
        let data = try Array(Data(contentsOf: url))

        var isStale2 = false

        let romUrl = try URL(resolvingBookmarkData: saveState.game!.bookmark, bookmarkDataIsStale: &isStale2)
        let romData = try Data(contentsOf: romUrl)

        if let emu = emulator, let bios7 = bios7Data, let bios9 = bios9Data {
            var dataPtr: UnsafeBufferPointer<UInt8>!
            data.withUnsafeBufferPointer { ptr in
                dataPtr = ptr
            }

            var bios7Ptr: UnsafeBufferPointer<UInt8>!
            var bios9Ptr: UnsafeBufferPointer<UInt8>!
            var romPtr: UnsafeBufferPointer<UInt8>!

            let bios7Arr = Array(bios7)

            bios7Arr.withUnsafeBufferPointer { ptr in
                bios7Ptr = ptr
            }

            let bios9Arr = Array(bios9)

            bios9Arr.withUnsafeBufferPointer { ptr in
                bios9Ptr = ptr
            }

            let romArr = Array(romData)

            romArr.withUnsafeBufferPointer { ptr in
                romPtr = ptr
            }

            emu.loadSaveState(dataPtr)
            try! emu.reloadBios(bios7Ptr, bios9Ptr)

            if let firmwareData = firmwareData {
                var firmwarePtr: UnsafeBufferPointer<UInt8>!
                let firmwareArr = Array(firmwareData)

                firmwareArr.withUnsafeBufferPointer { ptr in
                    firmwarePtr = ptr
                }

                try! emu.reloadFirmware(firmwarePtr)
            } else {
                try! emu.hleFirmware()
            }

            emu.reloadRom(romPtr)

            workItem?.cancel()
            isRunning = true

            workItem = nil

            var isStale = false
            let url = try URL(resolvingBookmarkData: selectedGame!.bookmark, bookmarkDataIsStale: &isStale)

            gameUrl = url

            isPresented = false

            game = selectedGame

            path.append("NDSGameView")

        } else {
            isPresented = false
        }
    }

    private func initEmu() throws {
        if let saveState = currentState, let selectedGame = selectedGame {
            switch selectedGame.type {
            case .nds:
                emulator = DSEmulatorWrapper(emu: DSEmulatorMobile.newLoadState())
                try loadDsState(saveState: saveState)
            case .gba:
                emulator = GBAEmulatorWrapper(emu: GBAEmulator())
                try loadGbState(saveState: saveState, selectedGame.type)
            case .gbc:
                emulator = GBCEmulatorWrapper(emu: GBCMobileEmulator())
                try loadGbState(saveState: saveState, selectedGame.type)
            }
        }
    }

    private func loadSaveState() {
        do {
            try initEmu()
        } catch {
            print(error)
        }
    }
    var body: some View {
        VStack {
            Text("Save States")
                .font(.custom("Departure Mono", size: 24))
            ScrollView {
                if let selectedGame = selectedGame {
                    switch selectedGame.type {
                    case .nds:
                        LazyVGrid(columns: columns) {
                            ForEach(selectedGame.saveStates!.sorted { $0.compare($1) }) { saveState in
                                LoadStateEntryView(
                                    gameType: selectedGame.type,
                                    saveState: saveState,
                                    currentState: $currentState
                                )
                            }
                        }
                    case .gba:
                        LazyVGrid(columns: columns) {
                            ForEach(selectedGame.gbaSaveStates!.sorted { $0.compare($1) }) { saveState in
                                LoadStateEntryView(gameType: selectedGame.type, saveState: saveState, currentState: $currentState)
                            }
                        }
                    case .gbc:
                        LazyVGrid(columns: columns) {
                            ForEach(selectedGame.gbcSaveStates!.sorted { $0.compare($1) }) { saveState in
                                LoadStateEntryView(gameType: selectedGame.type, saveState: saveState, currentState: $currentState)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .onChange(of: currentState?.timestamp) {
            loadSaveState()
        }
    }
}
