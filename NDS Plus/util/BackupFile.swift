//
//  BackupFile.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import Foundation

class BackupFile {
    var entry: GameEntry
    var gameUrl: URL
    var saveUrl: URL? = nil
    
    init(entry: GameEntry, gameUrl: URL) {
        self.entry = entry
        self.gameUrl = gameUrl
    }
    
    static func getSaveName(gameUrl: URL) -> String {
        return String(gameUrl
            .deletingPathExtension()
            .appendingPathExtension("sav")
            .relativeString
            .split(separator: "/")
            .last
            .unsafelyUnwrapped
        )
            .removingPercentEncoding
            .unsafelyUnwrapped
    }
    
    static func getPointer(_ data: Data) -> UnsafeBufferPointer<UInt8> {
        let buffer = Array(data)
        
        let ptr = buffer.withUnsafeBufferPointer { ptr in
            return ptr
        }
        
        return ptr
    }
    
    func createBackupFile() -> UnsafeBufferPointer<UInt8>? {
        let saveName = Self.getSaveName(gameUrl: gameUrl)

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
                    
                    return Self.getPointer(data)
                }
            } else {
                let buffer = [UInt8](repeating: 0xff, count: Int(entry.ramCapacity))
                
                let ptr = buffer.withUnsafeBufferPointer { ptr in
                    return ptr
                }
                
                let data = Data(buffer)
                
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
