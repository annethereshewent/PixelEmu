//
//  CloudService.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import Foundation
import GoogleSignIn

class CloudService {
    private var user: GIDGoogleUser
    private var dsFolderId: String? = nil
    private let jsonDecoder = JSONDecoder()
    
    
    private let googleBase = "https://www.googleapis.com"
    private let drivesUrl = "https://www.googleapis.com/drive/v3/files"
    
    init(user: GIDGoogleUser) {
        self.user = user
        
        let defaults = UserDefaults.standard
        
        if let dsFolderId = defaults.string(forKey: "dsFolderId") {
            self.dsFolderId = dsFolderId
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
        
        let capturedRequest = request
        
        let task = Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: capturedRequest)
                
                // if Data? type isn't explicitly defined, compiler won't allow nil to be returned below
                let dataCopy: Data? = data
     
                return dataCopy
            } catch {
                print(error)
            }
            
            return nil
        }
        
        do {
            let data = try await task.result.get()
            
            return data
        } catch {
            print(error)
        }
        
        return nil
    }
    
    private func checkForDSFolder() async -> String? {
        if let folderId = self.dsFolderId {
            return folderId
        }
        
        let params = [URLQueryItem(name: "q", value: "mimeType = \"application/vnd.google-apps.folder\" and name=\"ds-saves\"")]
        
        let url = buildUrl(params: params)
        
        let request = URLRequest(url: url)
        
        if let data = await self.cloudRequest(request: request) {
            do {
                let driveResponse = try jsonDecoder.decode(DriveResponse.self, from: data)
                if driveResponse.files.count > 0 {
                    self.dsFolderId = driveResponse.files[0].id
                    
                    let defaults = UserDefaults.standard
                    
                    defaults.set(self.dsFolderId, forKey: "dsFolderId")
                    
                    return driveResponse.files[0].id
                }
            } catch {
                print(error)
            }
        }
        
        // create the folder
        let folderParams = [URLQueryItem(name: "uploadType", value: "media")]
        do {
            let url = buildUrl(params: folderParams)
            
            var request = URLRequest(url: url)
            request.httpBody = try JSONEncoder().encode(FileJSON(
                name: "ds-saves",
                mimeType: "application/vnd.google-apps.folder"
            ))
            
            request.httpMethod = "POST"
            
            if let data = await self.cloudRequest(request: request) {
                do {
                    let driveResponse = try jsonDecoder.decode(DriveResponse.self, from: data)
                    if driveResponse.files.count > 0 {
                        self.dsFolderId = driveResponse.files[0].id
                        
                        let defaults = UserDefaults.standard
                        
                        defaults.set(self.dsFolderId, forKey: "dsFolderId")
                        
                        return driveResponse.files[0].id
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
    
    private func getSaveInfo(_ saveName: String, _ folderId: String) async -> DriveResponse? {
        let params = [
            URLQueryItem(name: "q", value: "name = \"\(saveName)\" and parents in \"\(folderId)\""),
            URLQueryItem(name: "fields", value: "files/id,files/parents,files/name")
        ]
        
        let url = buildUrl(params: params)
        
        let request = URLRequest(url: url)
    
        if let data = await self.cloudRequest(request: request) {
            if let driveResponse = try? jsonDecoder.decode(DriveResponse.self, from: data) {
                return driveResponse
            }
        }
        
        return nil
    }
    
    func getSave(saveName: String) async -> Data? {
        if let folderId = await self.checkForDSFolder() {
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
    
    func uploadSave(saveName: String, data: Data) async {
        if let folderId = await self.checkForDSFolder() {
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
                        // finally move the file to ds-saves folder
                        let params = [URLQueryItem(name: "uploadType", value: "media"), URLQueryItem(name: "addParents", value: self.dsFolderId)]
                        
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
