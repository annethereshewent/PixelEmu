//
//  LoadStatesView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/20/24.
//

import SwiftUI
import DSEmulatorMobile

struct LoadStatesView: View {
    @Binding var emulator: MobileEmulator?
    @Binding var selectedGame: Game?
    @Binding var game: Game?
    @Binding var isPresented: Bool
    
    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var path: NavigationPath
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var gameUrl: URL?
    @State private var currentState: SaveStateV2? = nil

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
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
                            isPresented = false
                            
                            workItem?.cancel()
                            isRunning = false
                            
                            workItem = nil
                            
                            var isStale = false
                            let url = try URL(resolvingBookmarkData: selectedGame!.bookmark, bookmarkDataIsStale: &isStale)
                            
                            gameUrl = url
                            
                            isPresented = false
                            
                            game = selectedGame
                            
                            path.append("GameView")
                            
                        } else {
                            isPresented = false
                        }
                        
                    } else {
                        isPresented = false
                    }
                } else {
                    isPresented = false
                }
            }
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
                    LazyVGrid(columns: columns) {
                        ForEach(selectedGame.saveStatesV2!.sorted { $0.compare($1) }) { saveState in
                            LoadStateEntryView(saveState: saveState, currentState: $currentState)
                        }
                    }
                }
            }
            Spacer()
        }
        .onChange(of: currentState) {
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
                if let selectedGame = selectedGame {
                    do {
                        let url = try URL(resolvingBookmarkData: selectedGame.bookmark, bookmarkDataIsStale: &isStale)
                        let data = try Data(contentsOf: url)
                        
                        romData = data
                        
                        Array(data).withUnsafeBufferPointer { ptr in
                            romPtr = ptr
                        }
            
                        emulator = MobileEmulator(bios7Ptr, bios9Ptr, firmwarePtr, romPtr)
                        loadSaveState()
                    } catch {
                        print(error)
                    }
                }
            }
        }
    }
}
