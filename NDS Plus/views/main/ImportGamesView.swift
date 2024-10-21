//
//  ImportGamesView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI
import UniformTypeIdentifiers
import DSEmulatorMobile

extension String: Error {}

struct ImportGamesView: View {
    @State private var showRomDialog = false
    @State private var showErrorMessage = false
    
    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var path: NavigationPath
    @Binding var gameUrl: URL?
    @Binding var workItem: DispatchWorkItem?
    @Binding var isRunning: Bool
    @Binding var emulator: MobileEmulator?
    @Binding var gameName: String
    @Binding var currentView: CurrentView
    
    @Environment(\.modelContext) private var context
    
    let ndsType = UTType(filenameExtension: "nds", conformingTo: .data)
    var body: some View {
        ZStack {
            VStack {
                Text("Import Games")
                HStack {
                    Image("Import Cartridge")
                    Text("Only \".nds\" files allowed")
                        .frame(width: 200, height: 60)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.custom("Departure Mono", size: 20))
                }
                Spacer()
                Spacer()
                HStack {
                    Button {
                        showRomDialog = true
                    } label: {
                        Image("Browse")
                        Text("Browse files")
                            .foregroundColor(Colors.accentColor)
                            .font(.custom("Departure Mono", size: 20))
                    }
                }
                Spacer()
                Spacer()
                
            }
            .font(.custom("Departure Mono", size: 24))
            .foregroundColor(Colors.primaryColor)
            .fileImporter(
                isPresented: $showRomDialog,
                allowedContentTypes: [ndsType.unsafelyUnwrapped],
                allowsMultipleSelection: true
            ) { result in
                do {
                    if let bios7Data = bios7Data, let bios9Data = bios9Data {
                        var bios7Bytes: UnsafeBufferPointer<UInt8>!
                        var bios9Bytes: UnsafeBufferPointer<UInt8>!
                        var firmwareBytes: UnsafeBufferPointer<UInt8>!
                        
                        Array(bios7Data).withUnsafeBufferPointer { ptr in
                            bios7Bytes = ptr
                        }
                        Array(bios9Data).withUnsafeBufferPointer { ptr in
                            bios9Bytes = ptr
                        }
                        
                        // firmware is unnecessary for this as we are just
                        // using the emulator to get the game icon.
                        [].withUnsafeBufferPointer { ptr in
                            firmwareBytes = ptr
                        }
                        
                        var emu: MobileEmulator!
                        
                        let urls = try result.get()
                        for url in urls {

                            if url.startAccessingSecurityScopedResource() {
                                defer {
                                    url.stopAccessingSecurityScopedResource()
                                }
                                let data = try Data(contentsOf: url)
                                
                                var romPtr: UnsafeBufferPointer<UInt8>!
                                
                                let dataArr = Array(data)
                                
                                dataArr.withUnsafeBufferPointer { ptr in
                                    romPtr = ptr
                                }
                                
                                if emu == nil {
                                    emu = MobileEmulator(bios7Bytes, bios9Bytes, firmwareBytes, romPtr)
                                } else {
                                    emu.reloadRom(romPtr)
                                }
                                
                                emu.loadIcon()
                                
                                romData = data
                                
                                gameName = String(url
                                    .relativeString
                                    .split(separator: "/")
                                    .last
                                    .unsafelyUnwrapped
                                )
                                .removingPercentEncoding
                                .unsafelyUnwrapped
                                
                                if let game = Game.storeGame(
                                    gameName: gameName,
                                    data: romData!,
                                    url: url,
                                    iconPtr: emu.getGameIconPointer()
                                ) {
                                    context.insert(game)
                                }
                            }
                        }
                        // once done processing all games, return back to library view
                        currentView = .library
                        emu = nil
                    } else {
                        showErrorMessage = true
                    }
                } catch {
                    showErrorMessage = true
                    print(error)
                }
            }
            if showErrorMessage {
                AlertModal(
                    alertTitle: "Oops!",
                    text: "There was an error importing the game(s).",
                    showAlert: $showErrorMessage
                )
            }
        }
    }
}
