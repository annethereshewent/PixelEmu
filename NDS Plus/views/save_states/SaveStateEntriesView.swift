//
//  SaveStateEntriesView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI
import SwiftData
import DSEmulatorMobile

struct SaveStateEntriesView: View {
    @Environment(\.modelContext) private var context
    
    @Binding var emulator: MobileEmulator?
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var game: Game?
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Spacer()
                Button("+") {
                    // create a  new save state
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
                            
                            let saveName = "state_\(game.saveStates.count + 1).save"
                            
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
                            
                            context.insert(SaveState(
                                saveName: saveName,
                                screenshot: screenshot,
                                bookmark: bookmark,
                                game: game
                            ))
                            
                            print("successfully created save state")
                            isMenuPresented = false
                        } catch {
                            print(error)
                        }
                    }
                }
                    .font(.largeTitle)
                    .foregroundColor(.green)
                    .padding(.trailing, 25)
                    .padding(.top, 25)
            }
            HStack {
                if let game = game {
                    ForEach(game.saveStates.sorted(by: { $0.saveName < $1.saveName })) { saveState in
                        SaveStateView(saveState: saveState)
                    }
                }
            }
            .padding()
            Spacer()
        }
    }
}
