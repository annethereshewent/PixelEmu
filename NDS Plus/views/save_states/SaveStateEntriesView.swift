//
//  SaveStateEntriesView.swift
//  NDS Plus
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
    
    @Binding var emulator: MobileEmulator?
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var game: Game?
    
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?

    @State private var action: SaveStateAction = .none
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    private func createSaveState(updateState: SaveState? = nil) {
        // create a new save state
        if let emu = emulator, let game = game {
            let dataPtr = emu.createSaveState()
            let compressedLength = emu.compressedLength()
            
            let unsafeBufferPtr = UnsafeBufferPointer(start: dataPtr, count: Int(compressedLength))
            
            let data = Data(unsafeBufferPtr)
            
            do {
                var location = try FileManager.default.url(
                     for: .applicationSupportDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true
                 )
                
                location.appendPathComponent("save_states")
                
                if !FileManager.default.fileExists(atPath: location.path) {
                    try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
                }
                
                let gameFolder = gameName.replacing(".nds", with: "")
                
                location.appendPathComponent(gameFolder)
                
                if !FileManager.default.fileExists(atPath: location.path) {
                    try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
                }
                
                let numSaves = game.saveStates.count
                
                let saveName = "state_\(numSaves + 1).save"
                
                location.appendPathComponent(saveName)
                
                try data.write(to: location)
                let bookmark = try location.bookmarkData(options: [])
                
                var screenshot: [UInt8]!
                
                if emu.isTopA() {
                    let topBufferPtr = UnsafeBufferPointer(start: emu.getEngineAPicturePointer(), count: SCREEN_WIDTH * SCREEN_HEIGHT * 4)
                    screenshot = Array(topBufferPtr)
                    
                    let bottomBufferPtr = UnsafeBufferPointer(start: emu.getEngineBPicturePointer(), count: SCREEN_HEIGHT * SCREEN_WIDTH * 4)
                    
                    screenshot.append(contentsOf: Array(bottomBufferPtr))
                } else {
                    let topBufferPtr = UnsafeBufferPointer(start: emu.getEngineBPicturePointer(), count: SCREEN_WIDTH * SCREEN_HEIGHT * 4)
                    screenshot = Array(topBufferPtr)
                    
                    let bottomBufferPtr = UnsafeBufferPointer(start: emu.getEngineAPicturePointer(), count: SCREEN_HEIGHT * SCREEN_WIDTH * 4)
                    
                    screenshot.append(contentsOf: Array(bottomBufferPtr))
                }
                
                let saveState = SaveState(
                    saveName: "Save \(numSaves + 1)",
                    screenshot: screenshot,
                    bookmark: bookmark
                )
                if let updateState = updateState, let index = game.saveStates.firstIndex(of: updateState) {
                    updateState.screenshot = saveState.screenshot
                    updateState.bookmark = saveState.bookmark
                
                    game.saveStates[index] = updateState
                    context.insert(updateState)
                } else {
                    game.saveStates.append(saveState)
                    context.insert(saveState)
                }
                
                isMenuPresented = false
            } catch {
                print(error)
            }
        }
    }
    
    private func loadSaveState() {
        do {
            if let saveState = currentState {
                var isStale = false
                let url = try URL(resolvingBookmarkData: saveState.bookmark, bookmarkDataIsStale: &isStale)
                if let data = try? Array(Data(contentsOf: url)) {
                    if let emu = emulator {
                        var dataPtr: UnsafeBufferPointer<UInt8>!
                        data.withUnsafeBufferPointer { ptr in
                            dataPtr = ptr
                        }
                        
                        if let bios7 = bios7Data, let bios9 = bios9Data, let rom = romData {
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
                            
                            let romArr = Array(rom)
                            
                            romArr.withUnsafeBufferPointer { ptr in
                                romPtr = ptr
                            }
                            
                            emu.loadSaveState(dataPtr)
                            emu.reloadBios(bios7Ptr, bios9Ptr)
                            
                            if let firmwareData = firmwareData {
                                var firmwarePtr: UnsafeBufferPointer<UInt8>!
                                let firmwareArr = Array(firmwareData)
                                
                                firmwareArr.withUnsafeBufferPointer { ptr in
                                    firmwarePtr = ptr
                                }
                                
                                emu.reloadFirmware(firmwarePtr)
                            } else {
                                emu.hleFirmware()
                            }
                            emu.reloadRom(romPtr)
                        }
                        isMenuPresented = false
                    }
                } else {
                    isMenuPresented = false
                }
            }
        } catch {
            print(error)
        }
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
            ScrollView {
                if let game = game {
                    LazyVGrid(columns: columns) {
                        ForEach(game.saveStates.sorted { $0.compare($1) }) { saveState in
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
            print(game)
            print(game?.saveStates.count ?? 0)
        }
        .onChange(of: action) {
            switch action {
            case .delete:
                deleteSaveState()
                break
            case .load:
                loadSaveState()
                break
            case .update:
                updateSaveState()
                break
            case .none:
                break
            }
        }
    }
}
