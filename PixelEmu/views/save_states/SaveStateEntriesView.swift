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

    @State var currentState: SaveState? = nil

    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var game: (any Playable)?

    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?

    @State private var action: SaveStateAction = .none

    @State private var stateManager: StateManager!

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private func createSaveState(updateState: SaveState? = nil) {
        // create a new save state

        if let emu = emulator {
            let dataPtr = emu.createSaveState()
            let compressedLength = emu.compressedLength()

            let unsafeBufferPtr = UnsafeBufferPointer(start: dataPtr, count: Int(compressedLength))

            let data = Data(unsafeBufferPtr)

            let timestamp = Int(Date().timeIntervalSince1970)
            let saveName = "state_\(timestamp).save"

            do {
                try stateManager.createSaveState(
                    data: data,
                    saveName: saveName,
                    timestamp: timestamp,
                    updateState: updateState
                )
            } catch {
                print(error)
            }
        }
        isMenuPresented = false
    }

    private func loadSaveState() {
        do {
            try stateManager.loadSaveState(currentState: currentState)
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
            if let index = game.saveStates?.firstIndex(of: saveState) {
                game.saveStates?.remove(at: index)
                context.delete(saveState)
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
                        ForEach(game.saveStates!.sorted { $0.compare($1) }) { saveState in
                            SaveStateView(
                                saveState: saveState,
                                action: $action,
                                currentState: $currentState
                            )
                        }
                    }
                }
            }
            Spacer()
        }
        .onAppear() {
            if let emu = emulator, let game = game, let bios7Data = bios7Data, let bios9Data = bios9Data, let romData = romData {
                stateManager = StateManager(
                    emu: emu,
                    game: game,
                    context: context,
                    biosData: nil,
                    bios7Data: bios7Data,
                    bios9Data: bios9Data,
                    romData: romData,
                    firmwareData: firmwareData
                )
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
