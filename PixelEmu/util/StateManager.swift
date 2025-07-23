//
//  StateManager.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/31/24.
//

import Foundation
import DSEmulatorMobile
import GBAEmulatorMobile
import SwiftData

class StateManager {
    private let emu: (any EmulatorWrapper)?
    private var game: any Playable
    private let context: ModelContext

    private let biosData: Data?
    private let bios7Data: Data?
    private let bios9Data: Data?
    private let romData: Data
    private let firmwareData: Data?

    init(
        emu: (any EmulatorWrapper)?,
        game: any Playable,
        context: ModelContext,
        biosData: Data?,
        bios7Data: Data?,
        bios9Data: Data?,
        romData: Data,
        firmwareData: Data?
    ) {
        self.emu = emu
        self.game = game
        self.context = context

        self.biosData = biosData
        self.bios7Data = bios7Data
        self.bios9Data = bios9Data
        self.romData = romData
        self.firmwareData = firmwareData
    }

    func saveGbaState(
        _ game: GBAGame,
        _ updateState: GBASaveState?,
        screenshot: [UInt8],
        bookmark: Data,
        timestamp: Int,
        saveName: String
    ) {
        let dateString = getCurrentDateString()

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
            index = game.gbaSaveStates!.firstIndex(of: updateState)
        } else if saveName == "quick_save.save" {
            index = game.gbaSaveStates!.map({ $0.saveName }).firstIndex(of: "Quick save")
        }

        if let index = index {
            let currState = game.gbaSaveStates![index]

            currState.screenshot = Data(saveState.screenshot)
            currState.bookmark = saveState.bookmark

            context.insert(currState)
        } else {
            game.gbaSaveStates!.append(saveState)
            context.insert(saveState)
        }
    }

    func saveNdsState(
        _ game: Game,
        _ updateState: SaveState?,
        screenshot: [UInt8],
        bookmark: Data,
        timestamp: Int,
        saveName: String
    ) {
        let dateString = getCurrentDateString()
        var saveState: SaveState!
        if (saveName == "quick_save.save") {
            saveState = SaveState(
                saveName: "Quick save",
                screenshot: screenshot,
                bookmark: bookmark,
                timestamp: timestamp
            )
        } else {
            saveState = SaveState(
                saveName: "Save on \(dateString)",
                screenshot: screenshot,
                bookmark: bookmark,
                timestamp: timestamp
            )
        }

        var index: Int?
        if let updateState = updateState {
            index = game.saveStates?.firstIndex(of: updateState)
        } else if saveName == "quick_save.save" {
            index = game.saveStates?.map({ $0.saveName }).firstIndex(of: "Quick save")
        }

        if let index = index {
            let currState = game.saveStates![index]

            currState.screenshot = Data(saveState.screenshot)
            currState.bookmark = saveState.bookmark

            context.insert(currState)

        } else {
            game.saveStates?.append(saveState)
            context.insert(saveState)
        }
    }

    func saveGbcGame(_ game: Game) {

    }

    func getCurrentDateString() -> String {
        let date = Date()
        let calendar = Calendar.current

        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)

        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)

        let dateString = String(format: "%02d/%02d/%04d %02d:%02d:%02d", month, day, year, hour, minutes, seconds)

        return dateString
    }

    func loadSaveState(currentState: SaveState?, isQuickSave: Bool = false) throws {
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
            if let bios7Data = bios7Data, let bios9Data = bios9Data, let emu = emu {
                var dataPtr: UnsafeBufferPointer<UInt8>!
                data.withUnsafeBufferPointer { ptr in
                    dataPtr = ptr
                }

                var bios7Ptr: UnsafeBufferPointer<UInt8>!
                var bios9Ptr: UnsafeBufferPointer<UInt8>!
                var romPtr: UnsafeBufferPointer<UInt8>!

                let bios7Arr = Array(bios7Data)

                bios7Arr.withUnsafeBufferPointer { ptr in
                    bios7Ptr = ptr
                }

                let bios9Arr = Array(bios9Data)

                bios9Arr.withUnsafeBufferPointer { ptr in
                    bios9Ptr = ptr
                }

                let romArr = Array(romData)

                romArr.withUnsafeBufferPointer { ptr in
                    romPtr = ptr
                }

                emu.loadSaveState(dataPtr)
                try! emu.reloadBios(bios7Ptr, bios9Ptr)

                if let firmwareData = firmwareData {
                    var firmwarePtr: UnsafeBufferPointer<UInt8>!
                    let firmwareArr = Array(firmwareData)

                    firmwareArr.withUnsafeBufferPointer { ptr in
                        firmwarePtr = ptr
                    }

                    try! emu.reloadFirmware(firmwarePtr)
                } else {
                    try! emu.hleFirmware()
                }
                emu.reloadRom(romPtr)
            }
        }
    }

    func loadGbaSaveState(currentState: GBASaveState?, isQuickSave: Bool = false) throws {
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

            let gameFolder = game.gameName.replacing(".gba", with: "").replacing(".GBA", with: "")

            url.appendPathComponent(gameFolder)

            if !FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            }

            url.appendPathComponent("quick_save.save")
        } else {
            return
        }
        if let emu = emu {
            if let data = try? Array(Data(contentsOf: url)) {
                if let biosData = biosData {
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
                    try! emu.loadBios(biosPtr)

                    emu.reloadRom(romPtr)
                }
            }
        }
    }

    func createGbaSaveState(data: Data, saveName: String, timestamp: Int, updateState: GBASaveState? = nil) throws {
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

        let gameFolder = game.gameName.replacing(".gba", with: "")

        location.appendPathComponent(gameFolder)

        if !FileManager.default.fileExists(atPath: location.path) {
            try FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
        }

        location.appendPathComponent(saveName)

        try data.write(to: location)
        let bookmark = try location.bookmarkData(options: [])

        var screenshot: [UInt8]!

        let picturePtr = try! emu?.getPicturePtr()

        let bufferPtr = UnsafeBufferPointer(start: picturePtr, count: GBA_SCREEN_WIDTH * GBA_SCREEN_HEIGHT * 4)

        screenshot = Array(bufferPtr)

        saveGbaState(
            game as! GBAGame,
            updateState,
            screenshot: screenshot,
            bookmark: bookmark,
            timestamp: timestamp,
            saveName: saveName
        )
    }

    func createSaveState(data: Data, saveName: String, timestamp: Int, updateState: SaveState? = nil) throws {
        if let emu = emu {
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

            if emu.isTopA() {
                let topBufferPtr = UnsafeBufferPointer(start: try! emu.getEngineAPicturePointer(), count: NDS_SCREEN_WIDTH * NDS_SCREEN_HEIGHT * 4)
                screenshot = Array(topBufferPtr)

                let bottomBufferPtr = UnsafeBufferPointer(start: try! emu.getEngineBPicturePointer(), count: NDS_SCREEN_HEIGHT * NDS_SCREEN_WIDTH * 4)

                screenshot.append(contentsOf: Array(bottomBufferPtr))
            } else {
                let topBufferPtr = UnsafeBufferPointer(start: try! emu.getEngineBPicturePointer(), count: NDS_SCREEN_WIDTH * NDS_SCREEN_HEIGHT * 4)
                screenshot = Array(topBufferPtr)

                let bottomBufferPtr = UnsafeBufferPointer(start: try! emu.getEngineAPicturePointer(), count: NDS_SCREEN_HEIGHT * NDS_SCREEN_WIDTH * 4)

                screenshot.append(contentsOf: Array(bottomBufferPtr))
            }

            saveNdsState(
                game as! Game,
                updateState,
                screenshot: screenshot,
                bookmark: bookmark,
                timestamp: timestamp,
                saveName: saveName
            )
        }
    }
}
