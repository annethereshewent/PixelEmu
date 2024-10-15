//
//  StateMenuView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI
import DSEmulatorMobile

struct StateMenuView: View {
    @Binding var emulator: MobileEmulator?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var audioManager: AudioManager?
    @Binding var isMenuPresented: Bool
    @Binding var gameName: String
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var shouldGoHome: Bool
    @Binding var game: Game?
    
    @State var isStateEntriesPresented: Bool = false
    
    private func goHome() {
        shouldGoHome = true
    }
    var body: some View {
        VStack {
            HStack {
                Button("Home") {
                    goHome()
                }
                .foregroundColor(.red)
                .font(.title2)
                Spacer()
                Spacer()
            }
            .padding(.leading, 25)
            HStack {
                Spacer()
                Button() {
                    isStateEntriesPresented = true
                } label: {
                    VStack {
                        Image(systemName: "tray.and.arrow.up")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Save state")
                            .font(.callout)
                    }
                }
                Spacer()
                Button() {
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
                        
                        location.appendPathComponent("state_1.save")
                        
                        if let data = try? Array(Data(contentsOf: location)) {
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
                    } catch {
                        print(error)
                    }
                } label: {
                    VStack {
                        Image(systemName: "tray.and.arrow.down")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Load state")
                            .font(.callout)
                    }
                    
                }
                Spacer()
                Button() {
                    isMenuPresented = false
                } label: {
                    VStack {
                        Image(systemName: "play")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Resume game")
                            .font(.callout)
                    }
                }
                
                Spacer()
            }
            .onDisappear() {
                if let emu = emulator {
                    emu.setPause(false)
                }
            }
            .presentationDetents([.height(150)])
        }
        .sheet(isPresented: $isStateEntriesPresented) {
            SaveStateEntriesView(
                emulator: $emulator,
                gameName: $gameName,
                isMenuPresented: $isMenuPresented,
                game: $game
            )
        }
    }
}
