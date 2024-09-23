//
//  BackupFile.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import Foundation

class BackupFile {
    static func createBackupFile(entry: GameEntry, gameUrl: URL) -> UnsafeBufferPointer<UInt8>? {
        let saveName = String(gameUrl
            .deletingPathExtension()
            .appendingPathExtension("sav")
            .relativeString
            .split(separator: "/")
            .last
            .unsafelyUnwrapped
        )
            .removingPercentEncoding
            .unsafelyUnwrapped

        print("creating backup file from \(entry.saveType) with save name \(saveName)")
        
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
            
            print(location.absoluteString)
            
            if FileManager.default.fileExists(atPath: location.path) {
                if let data = try? Data(contentsOf: location){
                    let buffer = Array(data)
                    
                    let ptr = buffer.withUnsafeBufferPointer { ptr in
                        return ptr
                    }
                    
                    return ptr
                }
            } else {
                print("didn't find the file :-(")
                let buffer = [UInt8](repeating: 0xff, count: Int(entry.ramCapacity))
                
                let ptr = buffer.withUnsafeBufferPointer { ptr in
                    return ptr
                }
                
                let data = Data(buffer)
                
                do {
                    try data.write(to: location)
                    print("successfully wrote the file!")
                } catch {
                    print(error)
                }
                
                return ptr
            }
        }
        
        return nil
    }
}
