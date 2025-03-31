//
//  CloudService.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import Foundation
import GoogleSignIn

enum SaveType {
    case nds
    case gba
}

class CloudService {
    private var user: GIDGoogleUser
    private var dsFolderId: String? = nil
    private var gbaFolderId: String? = nil
    private let jsonDecoder = JSONDecoder()
    
    
    private let googleBase = "https://www.googleapis.com"
    private let drivesUrl = "https://www.googleapis.com/drive/v3/files"
    
    init(user: GIDGoogleUser) {
        self.user = user
        
        let defaults = UserDefaults.standard
        
        if let dsFolderId = defaults.string(forKey: "dsFolderId") {
            self.dsFolderId = dsFolderId
        }

        if let gbaFolderId = defaults.string(forKey: "gbaFolderId") {
            self.gbaFolderId = gbaFolderId
        }
    }
    
    
    private func cloudRequest(request: URLRequest, headers: [String:String]? = nil) async -> Data? {
        do {
            let user = try await self.user.refreshTokensIfNeeded()
            
            self.user = user
        } catch {
            print(error)
        }
        
        var request = request

        request.setValue("Bearer \(self.user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        
        if let headers = headers {
            for header in headers {
                request.setValue(header.value, forHTTPHeaderField: header.key)
            }
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            
            return data
        } catch {
            print(error)
        }
        
        return nil
    }

    private func checkForGbaFolder() async -> String? {
        if let folderId = self.gbaFolderId {
            return folderId
        }
        return await checkForFolder(folderName: "gba-saves")
    }

    private func checkForDsFolder() async -> String? {
        if let folderId = self.dsFolderId {
            return folderId
        }
        return await checkForFolder(folderName: "ds-saves")
    }

    private func checkForFolder(folderName: String) async -> String? {
        let params = [URLQueryItem(name: "q", value: "mimeType = \"application/vnd.google-apps.folder\" and name=\"\(folderName)\"")]

        let url = buildUrl(params: params)
        
        let request = URLRequest(url: url)

        if let data = await self.cloudRequest(request: request) {
            do {
                let driveResponse = try jsonDecoder.decode(DriveResponse.self, from: data)
                if driveResponse.files.count > 0 {
                    let defaults = UserDefaults.standard

                    if folderName == "ds-saves" {
                        self.dsFolderId = driveResponse.files[0].id
                        defaults.set(self.dsFolderId, forKey: "dsFolderId")
                    } else if folderName == "gba-saves" {
                        self.gbaFolderId = driveResponse.files[0].id
                        defaults.set(self.gbaFolderId, forKey: "gbaFolderId")
                    }

                    return driveResponse.files[0].id
                }
            } catch {
                print(error)
            }
        }

        // create the folder
        let folderParams = [URLQueryItem(name: "uploadType", value: "media"), URLQueryItem(name: "fields", value: "id,name")]
        do {
            let url = buildUrl(params: folderParams)
            
            var request = URLRequest(url: url)

            let headers = ["Content-Type": "application/json"]

            request.httpMethod = "POST"

            request.httpBody = try JSONEncoder().encode(FileJSON(
                name: folderName,
                mimeType: "application/vnd.google-apps.folder"
            ))

            if let data = await self.cloudRequest(request: request, headers: headers) {
                do {
                    let fileResponse = try jsonDecoder.decode(File.self, from: data)

                    if fileResponse.name == folderName {
                        let defaults = UserDefaults.standard
                        if folderName == "ds-saves" {
                            self.dsFolderId = fileResponse.id
                            defaults.set(self.dsFolderId, forKey: "dsFolderId")
                        } else if folderName == "gba-saves" {
                            self.gbaFolderId = fileResponse.id
                            defaults.set(self.gbaFolderId, forKey: "gbaFolderId")
                        }

                        return fileResponse.id
                    }
                } catch {
                    print(error)
                }
            }
            
        } catch {
            print(error)
        }
        
        return nil
    }

    func getSavesData(saveType: SaveType) async -> DriveResponse? {
        if let folderId = switch saveType {
        case .gba: await self.checkForGbaFolder()
        case .nds: await self.checkForDsFolder()
        } {
            let params = [URLQueryItem(name: "q", value: "parents in \"" + folderId + "\"")]

            let url = buildUrl(params: params)

            let request = URLRequest(url: url)

            if let data = await self.cloudRequest(request: request) {
                do {
                    return try jsonDecoder.decode(DriveResponse.self, from: data)
                } catch {
                    print(error)
                }
            }
        }

        return nil
    }

    func getDsSaves(games: [Game]) async -> [SaveEntry] {
        if let driveResponse = await getSavesData(saveType: .nds) {
            var gameDictionary = [String:Game]()

            for game in games {
                gameDictionary[game.gameName] = game
            }

            var saveEntries = [SaveEntry]()

            for file in driveResponse.files {
                let gameName = file.name.replacing(".sav", with: ".nds")
                if let game = gameDictionary[gameName] {
                    saveEntries.append(SaveEntry(game: game))
                }
            }

            return saveEntries
        }
        
        
        return []
    }

    func getGbaSaves(games: [GBAGame]) async -> [GBASaveEntry] {
        if let driveResponse = await getSavesData(saveType: .gba) {
            var gameDictionary = [String:GBAGame]()

            for game in games {
                gameDictionary[game.gameName.replacing(".GBA", with: ".gba")] = game
            }

            var saveEntries = [GBASaveEntry]()

            for file in driveResponse.files {
                let gameName = file.name.replacing(".sav", with: ".gba")
                if let game = gameDictionary[gameName] {
                    saveEntries.append(GBASaveEntry(game: game))
                }
            }

            return saveEntries
        }


        return []
    }

    private func getSaveInfo(_ saveName: String, _ folderId: String) async -> DriveResponse? {
        let params = [
            URLQueryItem(name: "q", value: "name = \"\(saveName)\" and parents in \"\(folderId)\""),
            URLQueryItem(name: "fields", value: "files/id,files/parents,files/name")
        ]
        
        let url = buildUrl(params: params)
        
        let request = URLRequest(url: url)
    
        if let data = await self.cloudRequest(request: request) {
            do {
                let driveResponse = try jsonDecoder.decode(DriveResponse.self, from: data)
                return driveResponse
            } catch {
                print(error)
            }
        }
        
        return nil
    }
    
    func getSave(saveName: String, saveType: SaveType) async -> Data? {
        if let folderId = switch saveType {
        case .gba: await self.checkForGbaFolder()
        case .nds: await self.checkForDsFolder()
        } {
            if let driveResponse = await self.getSaveInfo(saveName, folderId) {
                if driveResponse.files.count > 0 {
                    let fileId = driveResponse.files[0].id
                    
                    let params = [URLQueryItem(name: "alt", value: "media")]
                    
                    let url = buildUrl(params: params, urlStr: "\(drivesUrl)/\(fileId)")
                    
                    let request = URLRequest(url: url)
                    
                    return await self.cloudRequest(request: request)
                }
            }
        }
        
        return nil
    }
    
    func deleteSave(saveName: String, saveType: SaveType) async -> Bool{
        if let folderId = switch saveType {
        case .gba: await self.checkForGbaFolder()
        case .nds: await self.checkForDsFolder()
        } {
            if let driveResponse = await self.getSaveInfo(saveName, folderId) {
                if driveResponse.files.count > 0 {
                    let fileId = driveResponse.files[0].id
                    
                    let url = buildUrl(params: [], urlStr: "\(drivesUrl)/\(fileId)")
                    
                    var request = URLRequest(url: url)
                    
                    request.httpMethod = "DELETE"
                    
                    if let _ = await self.cloudRequest(request: request) {
                        return true
                    }
                }
            }
        }
        
        
        return false
    }
    
    func uploadSave(saveName: String, data: Data, saveType: SaveType) async {
        if let folderId = switch saveType {
        case .gba: await self.checkForGbaFolder()
        case .nds: await self.checkForDsFolder()
        } {
            if let driveResponse = await self.getSaveInfo(saveName, folderId) {
                var headers = [String:String]()
                
                headers["Content-Type"] = "application/octet-stream"
                headers["Content-Length"] = "\(data.count)"
               
                if driveResponse.files.count > 0 {
                    let fileId = driveResponse.files[0].id
                    let urlStr = "\(googleBase)/upload/drive/v3/files/\(fileId)"
                    
                    let url = buildUrl(params: [URLQueryItem(name: "uploadType", value: "media")], urlStr: urlStr)
                    
                    var request = URLRequest(url: url)
                    
                    request.httpMethod = "PATCH"
 
                    request.httpBody = data
                    
                    let _ = await self.cloudRequest(request: request)
                    
                    return
                }
            
                // save doesn't exist, create it
                let params = [URLQueryItem(name: "uploadType", value: "media"), URLQueryItem(name: "fields", value: "id,name,parents")]
                let urlStr = "\(googleBase)/upload/drive/v3/files"
                let url = buildUrl(params: params, urlStr: urlStr)
                
                var request = URLRequest(url: url)
                
                request.httpMethod = "POST"
                
                request.httpBody = data
                
                if let data = await self.cloudRequest(request: request, headers: headers) {
                    do {
                        let fileResponse = try jsonDecoder.decode(File.self, from: data)
                        // finally move the file to correct saves folder
                        let params = switch saveType {
                        case .gba: [URLQueryItem(name: "uploadType", value: "media"), URLQueryItem(name: "addParents", value: self.gbaFolderId)]
                        case .nds : [URLQueryItem(name: "uploadType", value: "media"), URLQueryItem(name: "addParents", value: self.dsFolderId)]
                        }
                        
                        let fileId = fileResponse.id
                        let urlStr = "\(drivesUrl)/\(fileId)"
                        
                        let url = buildUrl(params: params, urlStr: urlStr)
                        
                        var request = URLRequest(url: url)
                        
                        request.httpMethod = "PATCH"
                        
                        request.httpBody = try JSONEncoder().encode(FileJSON(name: saveName, mimeType: "application/octet-stream"))
                        
                        let _ = await self.cloudRequest(request: request)
                    } catch {
                        print(error)
                    }
                    
                }
            }
        }
    }
    
    func buildUrl(params: [URLQueryItem], urlStr: String? = nil) -> URL {
        
        var urlComponents = URLComponents(string: urlStr ?? drivesUrl)
        
        urlComponents?.queryItems = params
        
        return urlComponents!.url!
    }
 }
