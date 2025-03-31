//
//  ArtworkService.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/29/24.
//

import Foundation

let GBA_ID = 12
let DS_ID = 15

class GameInfo : Decodable {
    var success: Bool
    var medias: [Media]?

    init(success: Bool, medias: [Media]) {
        self.success = success
        self.medias = medias
    }
}

class Media : Decodable {
    var type: String
    var url: String
    var region: String?

    init(type: String, url: String, region: String) {
        self.type = type
        self.url = url
        self.region = region
    }
}


class ArtworkService {

    private let jsonDecoder = JSONDecoder()
    func fetchArtwork(for gameName: String, systemId: Int) async -> Data? {
        let gameName = URLQueryItem(name: "name", value: gameName)
        let systemId = URLQueryItem(name: "systemId", value: String(systemId))

        var urlComponents = URLComponents(string: "https://nds-plus-service.onrender.com/album-artwork")
        urlComponents?.queryItems = [gameName, systemId]

        let url = urlComponents!.url!

        let request = URLRequest(url: url)

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            let gameInfo = try jsonDecoder.decode(GameInfo.self, from: data)

            if let medias = gameInfo.medias {
                if let media = medias.filter({ ($0.region != nil && $0.region == "us" && $0.type == "box-2D")}).first {
                    let artworkURL = URL(string: media.url)!
                    return try Data(contentsOf: artworkURL)
                } else if let media = medias.filter({ $0.type == "box-2D"}).first {
                    let artworkURL = URL(string: media.url)!
                    return try Data(contentsOf: artworkURL)
                }
            }

        } catch {
            print(error)
        }

        return nil
    }
}
