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
        var isStale = false
        let url = try URL(resolvingBookmarkData: saveState.bookmark, bookmarkDataIsStale: &isStale)
        let data = try Array(Data(contentsOf: url))

        var isStale2 = false

        if let emu = emulator, let selectedGame = selectedGame {
            let romUrl = try URL(resolvingBookmarkData: selectedGame.bookmark, bookmarkDataIsStale: &isStale2)
            let romData = try Data(contentsOf: romUrl)
            var dataPtr: UnsafeBufferPointer<UInt8>!

            data.withUnsafeBufferPointer { ptr in
                dataPtr = ptr
            }

            var romPtr: UnsafeBufferPointer<UInt8>!
            Array(romData).withUnsafeBufferPointer { ptr in
                romPtr = ptr
            }

            emu.loadSaveState(dataPtr)

            if gameType == .gba {
                if let biosData = biosData {
                    var biosPtr: UnsafeBufferPointer<UInt8>!
                    Array(biosData).withUnsafeBufferPointer { ptr in
                        biosPtr = ptr
                    }
                    try! emu.loadBios(biosPtr)
                } else {
                    print("[Warning] GBA selected but BIOS not found. Emulation may fail.")
                    return
                }
            }
            emu.reloadRom(romPtr)

            workItem?.cancel()
            isRunning = true

            workItem = nil

            var isStale = false
            let url = try URL(resolvingBookmarkData: selectedGame.bookmark, bookmarkDataIsStale: &isStale)

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
            case .nds: initDsEmu(saveState: saveState, selectedGame: selectedGame)
            case .gba:
                emulator = GBAEmulatorWrapper(emu: GBAEmulator())
                try loadGbState(saveState: saveState, selectedGame.type)
            case .gbc:
                emulator = GBCEmulatorWrapper(emu: GBCMobileEmulator())
                try loadGbState(saveState: saveState, selectedGame.type)
            }
        }
    }

    private func initDsEmu(saveState: any Snapshottable, selectedGame: any Playable) {
        var bios7Ptr: UnsafeBufferPointer<UInt8>!
        var bios9Ptr: UnsafeBufferPointer<UInt8>!
        var firmwarePtr: UnsafeBufferPointer<UInt8>!
        var romPtr: UnsafeBufferPointer<UInt8>!

        if let bios7Data = bios7Data, let bios9Data = bios9Data {
            Array(bios7Data).withUnsafeBufferPointer { ptr in
                bios7Ptr = ptr
            }
            Array(bios9Data).withUnsafeBufferPointer { ptr in
                bios9Ptr = ptr
            }

            if let firmwareData = firmwareData {
                Array(firmwareData).withUnsafeBufferPointer { ptr in
                    firmwarePtr = ptr
                }
            } else {
                [].withUnsafeBufferPointer { ptr in
                    firmwarePtr = ptr
                }
            }
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: selectedGame.bookmark, bookmarkDataIsStale: &isStale)
                let data = try Data(contentsOf: url)

                romData = data

                Array(data).withUnsafeBufferPointer { ptr in
                    romPtr = ptr
                }

                emulator = DSEmulatorWrapper(emu: MobileEmulator(bios7Ptr, bios9Ptr, firmwarePtr, romPtr))
                try loadDsState(saveState: saveState)
            } catch {
                print(error)
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
