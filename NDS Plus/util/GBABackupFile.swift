//
//  GBABackupFile.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 12/4/24.
//

import Foundation

class GBABackupFile {

    private var gameUrl: URL
    private var backupSize: Int
    private var saveUrl: URL? = nil

    init(gameUrl: URL, backupSize: Int) {
        self.gameUrl = gameUrl
        self.backupSize = backupSize
    }

    func saveGame(ptr: UnsafePointer<UInt8>, backupLength: Int) {
        print("saving da game")
        let buffer = UnsafeBufferPointer(start: ptr, count: backupLength)

        let data = Data(buffer)

        if let saveUrl = self.saveUrl {
            do {
                print("saving da game for real")
                try data.write(to: saveUrl)
                print("it worked!")
            } catch {
                print(error)
            }
        }
    }


    func createBackupFile() -> UnsafeBufferPointer<UInt8>? {
        let saveName = BackupFile.getSaveName(gameUrl: gameUrl)

        if var location = try? FileManager.default.url(
             for: .applicationSupportDirectory,
             in: .userDomainMask,
             appropriateFor: nil,
             create: true
        ) {
            location.appendPathComponent("saves")

            if !FileManager.default.fileExists(atPath: location.path) {
                try? FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
            }

            // finally, see if the file exists in the directory and load that, otherwise create it
            location.appendPathComponent(saveName)

            if FileManager.default.fileExists(atPath: location.path) {
                if let data = try? Data(contentsOf: location){
                    saveUrl = location

                    return BackupFile.getPointer(data)
                }
            } else {
                let buffer = [UInt8](repeating: 0xff, count: backupSize)

                let data = Data(buffer)

                let ptr = buffer.withUnsafeBufferPointer { ptr in
                    return ptr
                }

                do {
                    try data.write(to: location)
                } catch {
                    print(error)
                }

                saveUrl = location

                return ptr
            }
        }

        return nil
    }
}
