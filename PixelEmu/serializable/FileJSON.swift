//
//  FileJSON.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/23/24.
//

import Foundation

class FileJSON: Encodable {
    var name: String
    var mimeType: String
    
    init(name: String, mimeType: String) {
        self.name = name
        self.mimeType = mimeType
    }
}
