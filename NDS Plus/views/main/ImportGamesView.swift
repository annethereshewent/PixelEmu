//
//  ImportGamesView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import DSEmulatorMobile

struct ImportGamesView: View {
    @State private var showRomDialog = false
    @State private var showErrorMessage = false
    @State private var gameNamesSet: Set<String> = []

    private let artworkService = ArtworkService()
    @Query private var games: [Game]

    @Environment(\.modelContext) private var context

    let ndsType = UTType(filenameExtension: "nds", conformingTo: .data)
    let gbaType = UTType(filenameExtension: "gba", conformingTo: .data)

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
    @Binding var themeColor: Color
    @Binding var loading: Bool
    @Binding var currentLibrary: LibraryType

    var body: some View {
        ZStack {
            VStack {
                Text("Import games")
                HStack {
                    Image("Import Cartridge")
                        .foregroundColor(themeColor)
                    Text("Only .nds, .gba supported")
                        .frame(width: 200, height: 60)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.custom("Departure Mono", size: 20))
                }
                Spacer()
                HStack {
                    Button {
                        showRomDialog = true
                    } label: {
                        Image("Browse")
                            .foregroundColor(themeColor)
                        Text("Browse files")
                            .foregroundColor(themeColor)
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
                allowedContentTypes: [ndsType!, gbaType!],
                allowsMultipleSelection: true
            ) { result in
                do {
                    var emu: MobileEmulator!
                    let urls = try result.get()
                    loading = true
                    Task {
                        for url in urls {
                            if url.startAccessingSecurityScopedResource() {
                                defer {
                                    url.stopAccessingSecurityScopedResource()
                                }
                                let data = try Data(contentsOf: url)

                                romData = data

                                gameName = String(url
                                    .relativeString
                                    .split(separator: "/")
                                    .last
                                    .unsafelyUnwrapped
                                )
                                .removingPercentEncoding
                                .unsafelyUnwrapped

                                if url.pathExtension.lowercased() == "nds" {
                                    var romPtr: UnsafeBufferPointer<UInt8>!

                                    let dataArr = Array(data)

                                    dataArr.withUnsafeBufferPointer { ptr in
                                        romPtr = ptr
                                    }

                                    if emu == nil {
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

                                            Array([]).withUnsafeBufferPointer { ptr in
                                                firmwareBytes = ptr
                                            }

                                            emu = MobileEmulator(bios7Bytes, bios9Bytes, firmwareBytes, romPtr)
                                        }
                                    } else {
                                        emu.reloadRom(romPtr)
                                    }

                                    emu.loadIcon()
                                    if let game = Game.storeGame(
                                        gameName: gameName,
                                        data: romData!,
                                        url: url,
                                        iconPtr: emu.getGameIconPointer()
                                    ) {
                                        // check if album artwork exists before inserting game into DB
                                        if !gameNamesSet.contains(gameName) {
                                            if let artwork = await artworkService.fetchArtwork(for: gameName) {
                                                game.albumArt = artwork
                                            }
                                            context.insert(game)
                                            gameNamesSet.insert(gameName)
                                        }
                                    }
                                }

                                else {
                                    if let game = GBAGame.storeGame(
                                        gameName: gameName,
                                        data: data,
                                        url: url
                                    ) {
                                        if !gameNamesSet.contains(gameName) {
                                            if let artwork = await artworkService.fetchArtwork(for: gameName) {
                                                game.albumArt = artwork
                                            }
                                            context.insert(game)
                                            gameNamesSet.insert(gameName)
                                        }
                                    }
                                }
                            }
                        }
                        // once done processing all games, return back to library view
                        currentView = .library
                        loading = false
                        if urls[0].pathExtension.lowercased() == "nds" {
                            currentLibrary = .nds
                        } else {
                            currentLibrary = .gba
                        }
                        emu = nil
                    }
                } catch {
                    showErrorMessage = true
                    print(error)
                }
            }
            .onAppear() {
                for game in games {
                    gameNamesSet.insert(game.gameName)
                }
            }
            if showErrorMessage {
                AlertModal(
                    alertTitle: "Oops!",
                    text: "There was an error importing the game(s).",
                    showAlert: $showErrorMessage,
                    themeColor: $themeColor
                )
            }
        }
    }
}
