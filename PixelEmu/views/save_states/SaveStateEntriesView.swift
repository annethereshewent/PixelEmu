//
//  SaveStateEntriesView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI
import SwiftData
import DSEmulatorMobile

enum SaveStateAction {
    case none
    case update
    case load
    case delete
}

struct SaveStateEntriesView: View {
    @Environment(\.modelContext) private var context

    @State var currentState: (any Snapshottable)? = nil

    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var game: (any Playable)?

    @Binding var biosData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?

    @State private var action: SaveStateAction = .none

    @State private var stateManager: StateManager!

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private func createSaveState(updateState: (any Snapshottable)? = nil) {
        // create a new save state

        if let emu = emulator {
            let dataPtr = emu.createSaveState()
            let compressedLength = emu.compressedLength()

            let unsafeBufferPtr = UnsafeBufferPointer(start: dataPtr, count: Int(compressedLength))

            let data = Data(unsafeBufferPtr)

            let timestamp = Int(Date().timeIntervalSince1970)
            let saveName = "state_\(timestamp).save"

            do {
                switch game!.type {
                case .nds:
                    try stateManager.createNdsSaveState(
                        data: data,
                        saveName: saveName,
                        timestamp: timestamp,
                        updateState: updateState as! SaveState?
                    )
                case .gba:
                    try stateManager.createGbSaveState(
                        data: data,
                        saveName: saveName,
                        timestamp: timestamp,
                        updateState: updateState as! GBASaveState?
                    )
                case .gbc:
                    try stateManager.createGbSaveState(
                        data: data,
                        saveName: saveName,
                        timestamp: timestamp,
                        updateState: updateState as! GBCSaveState?
                    )
                }
            } catch {
                print(error)
            }
        }
        isMenuPresented = false
    }

    private func loadSaveState() {
        do {
            try stateManager.loadSaveState(currentState: currentState!)
        } catch {
            print(error)
        }
        isMenuPresented = false
    }

    private func updateSaveState() {
        if let currentState = currentState {
            createSaveState(updateState: currentState)
        }
    }

    private func deleteSaveState() {
        if let saveState = currentState, var game = game {
            switch game.type {
            case .nds:
                if let index = game.saveStates?.firstIndex(of: saveState as! SaveState) {
                    game.saveStates?.remove(at: index)
                    context.delete(saveState as! SaveState)
                }
            case .gba:
                if let index = game.gbaSaveStates?.firstIndex(of: saveState as! GBASaveState) {
                    game.gbaSaveStates?.remove(at: index)
                    context.delete(saveState as! GBASaveState)
                }
            case .gbc:
                if let index = game.gbcSaveStates?.firstIndex(of: saveState as! GBCSaveState) {
                    game.gbcSaveStates?.remove(at: index)
                    context.delete(saveState as! GBCSaveState)
                }
            }

        }
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                // Spacer()
                Button("+") {
                    createSaveState()
                }
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .padding(.trailing, 25)
                    .padding(.top, 25)
            }
            Text("Save States")
                .font(.custom("Departure Mono", size: 24))
            ScrollView {
                if let game = game {
                    LazyVGrid(columns: columns) {
                        switch game.type {
                        case .nds:
                            ForEach(game.saveStates!.sorted { $0.compare($1) }) { saveState in
                                SaveStateView(
                                    gameType: game.type,
                                    saveState: saveState,
                                    action: $action,
                                    currentState: $currentState
                                )
                            }
                        case .gba:
                            ForEach(game.gbaSaveStates!.sorted { $0.compare($1) }) { saveState in
                                SaveStateView(
                                    gameType: game.type,
                                    saveState: saveState,
                                    action: $action,
                                    currentState: $currentState
                                )
                            }
                        case .gbc:
                            ForEach(game.gbcSaveStates!.sorted { $0.compare($1) }) { saveState in
                                SaveStateView(
                                    gameType: game.type,
                                    saveState: saveState,
                                    action: $action,
                                    currentState: $currentState
                                )
                            }
                        }

                    }
                }
            }
            Spacer()
        }
        .onAppear() {
            switch game!.type {
            case .nds:
                if let emu = emulator, let game = game, let bios7Data = bios7Data, let bios9Data = bios9Data, let romData = romData {
                    stateManager = StateManager(
                        emu: emu,
                        game: game,
                        context: context,
                        biosData: biosData,
                        bios7Data: bios7Data,
                        bios9Data: bios9Data,
                        romData: romData,
                        firmwareData: firmwareData
                    )
                }
            case .gba:
                if let emu = emulator, let game = game, let biosData = biosData, let romData = romData {
                    stateManager = StateManager(
                        emu: emu,
                        game: game,
                        context: context,
                        biosData: biosData,
                        bios7Data: nil,
                        bios9Data: nil,
                        romData: romData,
                        firmwareData: nil
                    )
                }
            case .gbc:
                if let emu = emulator, let game = game, let romData = romData {
                    stateManager = StateManager(
                        emu: emu,
                        game: game,
                        context: context,
                        biosData: nil,
                        bios7Data: nil,
                        bios9Data: nil,
                        romData: romData,
                        firmwareData: nil
                    )
                }
            }

        }
        .onChange(of: action) {
            switch action {
            case .delete:
                deleteSaveState()
                action = .none
                break
            case .load:
                loadSaveState()
                action = .none
                break
            case .update:
                updateSaveState()
                action = .none
                break
            case .none:
                break
            }
        }
        .font(.custom("Departure Mono", size: 20))
        .foregroundColor(Colors.primaryColor)
    }
}
