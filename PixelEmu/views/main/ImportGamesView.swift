//
//  ImportGamesView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import DSEmulatorMobile
import ZIPFoundation

struct ImportGamesView: View {
    @State private var showRomDialog = false
    @State private var showErrorMessage = false
    @State private var gameNamesSet: Set<String> = []

    private let artworkService = ArtworkService()
    @Query private var games: [Game]
    @Query private var gbaGames: [GBAGame]

    @Environment(\.modelContext) private var context

    let ndsType = UTType(filenameExtension: "nds", conformingTo: .data)
    let gbaType = UTType(filenameExtension: "gba", conformingTo: .data)
    let gbType = UTType(filenameExtension: "gb", conformingTo: .data)
    let gbcType = UTType(filenameExtension: "gbc", conformingTo: .data)
    let zipType = UTType(filenameExtension: "zip", conformingTo: .data)

    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var path: NavigationPath
    @Binding var gameUrl: URL?
    @Binding var workItem: DispatchWorkItem?
    @Binding var isRunning: Bool
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var gameName: String
    @Binding var currentView: CurrentView
    @Binding var themeColor: Color
    @Binding var loading: Bool

    @Binding var currentLibrary: String


    private func storeGBAGame(data: Data, emu: (any EmulatorWrapper)?, url: URL, _ isZip: Bool) async {
        if var game = GBAGame.storeGame(
            gameName: gameName,
            data: data,
            url: url,
            isZip: isZip
        ) {
            if !gameNamesSet.contains(gameName) {
                if let artwork = await artworkService.fetchArtwork(for: gameName, systemId: GBA_ID) {
                    game.albumArt = artwork
                }
                context.insert(game as! GBAGame)
                gameNamesSet.insert(game.gameName)
            }
        }
    }

    private func storeGBCGame(data: Data, emu: (any EmulatorWrapper)?, url: URL, _ isZip: Bool) async {
        if var game = GBCGame.storeGame(
            gameName: gameName,
            data: data,
            url: url,
            isZip: isZip
        ) {
            if !gameNamesSet.contains(game.gameName) {
                var id = 0
                if game.gameName.lowercased().contains(/\.gbc$/) {
                    id = GBC_ID
                } else {
                    id = GB_ID
                }
                if let artwork = await artworkService.fetchArtwork(for: game.gameName, systemId: id) {
                    game.albumArt = artwork
                }

                context.insert(game as! GBCGame)
                gameNamesSet.insert(game.gameName)
            }
        }
    }

    private func storeDSGame(data: Data, emu: (any EmulatorWrapper)?, url: URL, _ isZip: Bool) async {
        var emu = emu
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

                emu = DSEmulatorWrapper(emu: MobileEmulator(bios7Bytes, bios9Bytes, firmwareBytes, romPtr))
            }
        } else {
            try! emu?.reloadRom(romPtr)
        }

        try! emu?.loadIcon()
        if var game = Game.storeGame(
            gameName: gameName,
            data: romData!,
            url: url,
            iconPtr: try! emu?.getGameIconPointer(),
            isZip: isZip
        ) {
            // check if album artwork exists before inserting game into DB
            if !gameNamesSet.contains(gameName) {
                if let artwork = await artworkService.fetchArtwork(for: gameName, systemId: DS_ID) {
                    game.albumArt = artwork
                }

                context.insert(game as! Game)
            }
        }
    }

    func unzipGame(url: URL) -> (URL?, Data?) {
        let fileManager = FileManager()

        do {
            var destinationUrl = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            var actualUrl = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

            destinationUrl.appendPathComponent("temp")

            if fileManager.fileExists(atPath: destinationUrl.path) {
                try fileManager.removeItem(at: destinationUrl)
            }
            try fileManager.createDirectory(at: destinationUrl, withIntermediateDirectories: true)

            try fileManager.unzipItem(at: url, to: destinationUrl)

            let contents = try fileManager.contentsOfDirectory(at: destinationUrl, includingPropertiesForKeys: nil)

            var tempUrl: URL!
            for content in contents {
                if ["nds", "gba", "gbc", "gb"].contains(content.pathExtension.lowercased()) {
                    tempUrl = content
                    break
                }
            }

            if tempUrl == nil {
                return (nil, nil)
            }

            let data = try Data(contentsOf: tempUrl)

            let fileName = tempUrl.lastPathComponent

            actualUrl.appendPathComponent("unzipped-roms")

            if !fileManager.fileExists(atPath: actualUrl.path()) {
                try fileManager.createDirectory(at: actualUrl, withIntermediateDirectories: true, attributes: nil)
            }

            // overwrite the file if it exists
            actualUrl.appendPathComponent(fileName)

            if fileManager.fileExists(atPath: actualUrl.path) {
                try fileManager.removeItem(at: actualUrl)
            }

            // move file and remove temp directory
            try fileManager.moveItem(at: tempUrl, to: actualUrl)

            return (actualUrl, data)
        } catch {
            print("couldn't open application support directory")

            return (nil, nil)
        }
    }

    var body: some View {
        ZStack {
            VStack {
                Text("Import games")
                HStack {
                    Image("Import Cartridge")
                        .foregroundColor(themeColor)
                    Text(".nds, .gba, .gbc, and .gb supported")
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
                allowedContentTypes: [ndsType!, gbaType!, gbType!, gbcType!, zipType!],
                allowsMultipleSelection: true
            ) { result in
                do {
                    var emu: (any EmulatorWrapper)?
                    let urls = try result.get()
                    loading = true
                    var actualUrl: URL!
                    var firstUrl: URL!
                    Task {
                        for url in urls {
                            if url.startAccessingSecurityScopedResource() {
                                defer {
                                    url.stopAccessingSecurityScopedResource()
                                }

                                var data: Data!
                                actualUrl = try FileManager.default.url(
                                    for: .applicationSupportDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: true
                                )

                                var isZip = false

                                if url.pathExtension == "zip" {
                                    isZip = true
                                    (actualUrl, data) = unzipGame(url: url)
                                } else {
                                    data = try Data(contentsOf: url)
                                    actualUrl = url
                                }

                                if (actualUrl == nil) {
                                    continue
                                }

                                if firstUrl == nil {
                                    firstUrl = actualUrl
                                }

                                romData = data

                                gameName = String(actualUrl
                                    .relativeString
                                    .split(separator: "/")
                                    .last
                                    .unsafelyUnwrapped
                                )
                                .removingPercentEncoding
                                .unsafelyUnwrapped

                                switch actualUrl.pathExtension.lowercased() {
                                case "nds": await storeDSGame(data: data, emu: emu, url: actualUrl, isZip)
                                case "gba": await storeGBAGame(data: data, emu: emu, url: actualUrl, isZip)
                                case "gbc": await storeGBCGame(data: data, emu: emu, url: actualUrl, isZip)
                                case "gb": await storeGBCGame(data: data, emu: emu, url: actualUrl, isZip)
                                default: break
                                }
                            }
                        }
                        // once done processing all games, return back to library view
                        currentView = .library
                        loading = false

                        var current = firstUrl.pathExtension.lowercased()

                        if current == "gb" {
                            current = "gbc"
                        }
                        currentLibrary = current

                        let defaults = UserDefaults.standard

                        defaults.set(currentLibrary, forKey: "currentLibrary")

                        emu = nil
                    }
                } catch {
                    print(error)
                    showErrorMessage = true
                }
            }
            .onAppear() {
                for game in games {
                    gameNamesSet.insert(game.gameName)
                }

                for game in gbaGames {
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
