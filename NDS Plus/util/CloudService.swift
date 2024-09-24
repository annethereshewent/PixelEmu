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
    
    private var drivesUrl = "https://www.googleapis.com/drive/v3/files"
    
    init(user: GIDGoogleUser) {
        self.user = user
    }
    
    
    private func cloudRequest(request: URLRequest, headers: [String:String]? = nil) async -> Data? {
        self.user.refreshTokensIfNeeded { user, error in
            guard error == nil else { return }
            guard let user = user else { return }
            
            self.user = user
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
                
                // fuck you
                let dataCopy: Data? = data
     
                return dataCopy
            } catch {
                print("failed to send request: \(error)")
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
        
        var request = URLRequest(url: url)
        
        if let data = await self.cloudRequest(request: request) {
            print("made it past the request....")
            do {
                let driveResponse = try jsonDecoder.decode(DriveResponse.self, from: data)
                print("got the drive response.....")
                if driveResponse.files.count > 0 {
                    print("yeah")
                    return driveResponse.files[0].id
                }
            } catch {
                print(error)
            }
        }
        
        print("yo what the fuck")
        
        // create the folder
        let folderParams = [URLQueryItem(name: "uploadType", value: "media")]
        do {
            let url = buildUrl(params: folderParams)
            
            var request = URLRequest(url: url)
            request.httpBody = try JSONEncoder().encode(FileJSON(
                name: "ds-saves",
                mimeType: "application/vnd.google-apps.folder"
            ))
            
            throw NSError()
            
            request.httpMethod = "POST"
            
            
            if let data = await self.cloudRequest(request: request) {
                do {
                    let driveResponse = try jsonDecoder.decode(DriveResponse.self, from: data)
                    if driveResponse.files.count > 0 {
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
    
    func getSave(saveName: String) async -> Data? {
        if let folderId = await self.checkForDSFolder() {
            let params = [
                URLQueryItem(name: "q", value: "name = \"\(saveName)\" and parents in \"\(folderId)\""),
                URLQueryItem(name: "fields", value: "files/id,files/parents,files/name")
            ]
            
            let url = buildUrl(params: params)
            
            let request = URLRequest(url: url)
        
            if let data = await self.cloudRequest(request: request){
                if let driveResponse = try? jsonDecoder.decode(DriveResponse.self, from: data) {
                    if driveResponse.files.count > 0 {
                        let fileId = driveResponse.files[0].id
                        
                        let params = [URLQueryItem(name: "alt", value: "media")]
                        
                        let url = buildUrl(params: params, urlStr: "\(drivesUrl)/\(fileId)")
                        
                        print(url)
                        
                        let request = URLRequest(url: url)
                        
                        print("we made it to here")
                        
                        return await self.cloudRequest(request: request)
                    }
                }
            }
        }
        
        return nil
    }
    
    func buildUrl(params: [URLQueryItem], urlStr: String? = nil) -> URL {
        
        var urlComponents = URLComponents(string: urlStr ?? drivesUrl)
        
        urlComponents?.queryItems = params
        
        return urlComponents!.url!
    }
 }
