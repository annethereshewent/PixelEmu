//
//  GBAStateEntriesView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 12/6/24.
//

import SwiftUI
import GBAEmulatorMobile

struct GBAStateEntriesView: View {
    @Environment(\.modelContext) private var context

    @State private var currentState: GBASaveState? = nil

    @Binding var emulator: GBAEmulator?
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var game: GBAGame?

    @Binding var biosData: Data?
    @Binding var romData: Data?

    @State private var action: SaveStateAction = .none

    @State private var stateManager: GBAStateManager!

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private func createSaveState(updateState: GBASaveState? = nil) {
        // create a new save state

        if let emu = emulator {
            let dataPtr = emu.createSaveState()
            let compressedLength = emu.compressedLength()

            let unsafeBufferPtr = UnsafeBufferPointer<UInt8>(start: dataPtr, count: Int(compressedLength))

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
        if let saveState = currentState, let game = game {
            if let index = game.saveStates.firstIndex(of: saveState) {
                game.saveStates.remove(at: index)
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
                        ForEach(game.saveStates.sorted { $0.compare($1) }) { saveState in
                            GBAStateView(
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
            if let emu = emulator, let game = game, let biosData = biosData, let romData = romData {
                stateManager = GBAStateManager(
                    emu: emu,
                    game: game,
                    context: context,
                    biosData: biosData,
                    romData: romData
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
