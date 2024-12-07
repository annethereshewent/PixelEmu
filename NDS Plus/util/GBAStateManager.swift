//
//  GBAStateManager.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 12/6/24.
//

import Foundation
import GBAEmulatorMobile
import SwiftData

class GBAStateManager {
    private let emu: GBAEmulator
    private let game: GBAGame
    private let context: ModelContext

    private let biosData: Data
    private let romData: Data

    init(
        emu: GBAEmulator,
        game: GBAGame,
        context: ModelContext,
        biosData: Data,
        romData: Data
    ) {
        self.emu = emu
        self.game = game
        self.context = context

        self.biosData = biosData
        self.romData = romData
    }

    func loadSaveState(currentState: GBASaveState?, isQuickSave: Bool = false) throws {
        var url: URL!
        if let saveState = currentState {
            var isStale = false
            url = try URL(resolvingBookmarkData: saveState.bookmark, bookmarkDataIsStale: &isStale)
        } else if isQuickSave {
            url = try FileManager.default.url(
                 for: .applicationSupportDirectory,
                 in: .userDomainMask,
                 appropriateFor: nil,
                 create: true
             )

            url.appendPathComponent("save_states")

            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }

            let gameFolder = game.gameName.replacing(".nds", with: "")

            url.appendPathComponent(gameFolder)

            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }

            url.appendPathComponent("quick_save.save")
        } else {
            return
        }
        if let data = try? Array(Data(contentsOf: url)) {
            var dataPtr: UnsafeBufferPointer<UInt8>!
            data.withUnsafeBufferPointer { ptr in
                dataPtr = ptr
            }

            var biosPtr: UnsafeBufferPointer<UInt8>!
            var romPtr: UnsafeBufferPointer<UInt8>!

            Array(romData).withUnsafeBufferPointer { ptr in
                romPtr = ptr
            }

            Array(biosData).withUnsafeBufferPointer { ptr in
                biosPtr = ptr
            }

            emu.loadSaveState(dataPtr)
            emu.loadBios(biosPtr)
            emu.load(romPtr)
        }
    }

    func createSaveState(data: Data, saveName: String, timestamp: Int, updateState: GBASaveState? = nil) throws {
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

        let gameFolder = game.gameName.replacing(".nds", with: "")

        location.appendPathComponent(gameFolder)

        if !FileManager.default.fileExists(atPath: location.path) {
            try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
        }

        location.appendPathComponent(saveName)

        try data.write(to: location)
        let bookmark = try location.bookmarkData(options: [])

        var screenshot: [UInt8]!

        let picturePtr = emu.getPicturePtr()

        let bufferPtr = UnsafeBufferPointer(start: picturePtr, count: GBA_SCREEN_WIDTH * GBA_SCREEN_HEIGHT * 4)

        screenshot = Array(bufferPtr)

        let date = Date()
        let calendar = Calendar.current

        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)

        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)

        let dateString = String(format: "%02d/%02d/%04d %02d:%02d:%02d", month, day, year, hour, minutes, seconds)
        var saveState: GBASaveState!
        if (saveName == "quick_save.save") {
            saveState = GBASaveState(
                saveName: "Quick save",
                screenshot: screenshot,
                bookmark: bookmark,
                timestamp: timestamp
            )
        } else {
            saveState = GBASaveState(
                saveName: "Save on \(dateString)",
                screenshot: screenshot,
                bookmark: bookmark,
                timestamp: timestamp
            )
        }

        var index: Int?

        if let updateState = updateState {
            index = game.saveStates.firstIndex(of: updateState)
        } else if saveName == "quick_save.save" {
            index = game.saveStates.map({ $0.saveName }).firstIndex(of: "Quick save")
        }

        if let index = index {
            let currState = game.saveStates[index]

            currState.screenshot = Data(saveState.screenshot)
            currState.bookmark = saveState.bookmark

            context.insert(currState)
        } else {
            game.saveStates.append(saveState)
            context.insert(saveState)
        }
    }
}

