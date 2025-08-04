//
//  GBBackupFile.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 12/4/24.
//

import Foundation

class GBBackupFile {

    private var gameUrl: URL
    private var backupSize: Int
    private var saveUrl: URL? = nil
    private var rtcUrl: URL? = nil

    init(gameUrl: URL, backupSize: Int) {
        self.gameUrl = gameUrl
        self.backupSize = backupSize
    }

    static func getRtcName(gameUrl: URL) -> String {
        return String(gameUrl
            .deletingPathExtension()
            .appendingPathExtension("rtc")
            .relativeString
            .split(separator: "/")
            .last
            .unsafelyUnwrapped
        )
            .removingPercentEncoding
            .unsafelyUnwrapped
    }

    func saveGame(ptr: UnsafePointer<UInt8>, backupLength: Int) {
        let buffer = UnsafeBufferPointer(start: ptr, count: backupLength)

        let data = Data(buffer)

        if let saveUrl = saveUrl {
            do {
                try data.write(to: saveUrl)
            } catch {
                print(error)
            }
        }
    }

    func loadRtcFile(_ json: String? = nil) -> UnsafeBufferPointer<UInt8>? {
        let rtcName = Self.getRtcName(gameUrl: gameUrl)

        if let ptr = createBackupFile(fileName: rtcName, json) {
            return ptr
        }

        return nil
    }

    func saveRtc(_ json: String) {
        let data = json.data(using: .utf8)!

        if let rtcUrl = rtcUrl {
            do {
                try data.write(to: rtcUrl)
            } catch {
                print(error)
            }
        }
    }

    func createBackupFile(fileName: String? = nil, _ json: String? = nil) -> UnsafeBufferPointer<UInt8>? {
        let name = fileName != nil ? fileName! : BackupFile.getSaveName(gameUrl: gameUrl)

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
            location.appendPathComponent(name)

            if FileManager.default.fileExists(atPath: location.path) {
                if let data = try? Data(contentsOf: location) {
                    if name.hasSuffix(".rtc") {
                        rtcUrl = location
                    } else {
                        saveUrl = location
                    }

                    return BackupFile.getPointer(data)
                }
            } else {
                var buffer: [UInt8] = []
                var data: Data!

                if let json = json {
                    data = json.data(using: .utf8)!
                    buffer = Array(data)
                } else {
                    let jsonCount = json == nil ? 0 : json!.count
                    let count = name.hasSuffix(".rtc") ? jsonCount : backupSize

                    buffer = [UInt8](repeating: 0xff, count: count)
                    data = Data(buffer)
                }

                let ptr = buffer.withUnsafeBufferPointer { ptr in
                    ptr
                }

                do {
                    try data.write(to: location)
                } catch {
                    print(error)
                }

                if name.hasSuffix(".rtc") {
                    rtcUrl = location
                } else {
                    saveUrl = location
                }

                return ptr
            }
        }

        return nil
    }
}
