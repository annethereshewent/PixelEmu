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
    
    func saveGame(ptr: UnsafePointer<UInt8>, backupLength: Int) {
        let buffer = UnsafeBufferPointer(start: ptr, count: backupLength)
        
        let data = Data(buffer)
        
        if let saveUrl = self.saveUrl {
            do {
                try data.write(to: saveUrl)
            } catch {
                print(error)
            }
        }
    }
    
    static func getFileLocation(saveName: String) -> URL? {
        do {
            var location = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            location.appendPathComponent("saves")
            
            if !FileManager.default.fileExists(atPath: location.path) {
                try? FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
            }
            
            location.appendPathComponent(saveName)
            
            return location
        } catch {
            print(error)
        }
        
        return nil
    }
    
    static func deleteSave(saveName: String) -> Bool {
        do {
            if let location = Self.getFileLocation(saveName: saveName) {
                try FileManager.default.removeItem(at: location)
                
                return true
            }
        } catch {
            print(error)
        }
        
        
        return false
    }
    
    static func saveCloudFile(saveName: String, saveFile: Data) {
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
            
            location.appendPathComponent(saveName)
            do {
                try saveFile.write(to: location)
            } catch {
                print(error)
            }
        }
    }
    
    static func getSave(saveName: String) -> Data? {
        do {
            if let location = Self.getFileLocation(saveName: saveName) {
                let data = try Data(contentsOf: location)
                
                return data
            }
        } catch {
            print(error)
        }
        
        return nil
    }
    
    static func getLocalSaves(games: [Game]) -> [SaveEntry] {
        var saveEntries = [SaveEntry]()
        do {
            var location = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            location.appendPathComponent("saves")
            
            if !FileManager.default.fileExists(atPath: location.path) {
                try? FileManager.default.createDirectory(at: location, withIntermediateDirectories: true)
            }
                
            let items = try FileManager.default.contentsOfDirectory(atPath: location.path)
            
            var gameDictionary = [String:Game]()
            
            for game in games {
                gameDictionary[game.gameName.replacing(".nds", with: ".sav")] = game
            }
            
            for item in items {
                if let game = gameDictionary[item] {
                    saveEntries.append(SaveEntry(game: game))
                }
            }
            
        } catch {
            print(error)
        }
        
        return saveEntries
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
