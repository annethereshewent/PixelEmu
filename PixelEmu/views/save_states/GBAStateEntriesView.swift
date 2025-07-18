//
//  GBAStateEntriesView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 12/6/24.
//

import SwiftUI
import GBAEmulatorMobile
import DSEmulatorMobile

struct GBAStateEntriesView: View {
    @Environment(\.modelContext) private var context

    @State private var currentState: GBASaveState? = nil
    private let dsEmu: MobileEmulator? = nil

    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var game: (any Playable)?

    @Binding var biosData: Data?
    @Binding var romData: Data?

    @State private var action: SaveStateAction = .none

    @State private var stateManager: StateManager!

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private func createSaveState(updateState: GBASaveState? = nil) {
        // create a new save state

        if let emu = emulator {
            let dataPtr = try! emu.createSaveState()
            let compressedLength = try! emu.compressedLength()

            let unsafeBufferPtr = UnsafeBufferPointer<UInt8>(start: dataPtr, count: Int(compressedLength))

            let data = Data(unsafeBufferPtr)

            let timestamp = Int(Date().timeIntervalSince1970)
            let saveName = "state_\(timestamp).save"

            do {
                try stateManager.createGbaSaveState(
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
            try stateManager.loadGbaSaveState(currentState: currentState)
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
        if let saveState = currentState, let game = game as! GBAGame? {
            if let index = game.gbaSaveStates!.firstIndex(of: saveState) {
                game.gbaSaveStates!.remove(at: index)
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
                        ForEach(game.gbaSaveStates!.sorted { $0.compare($1) }) { saveState in
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
