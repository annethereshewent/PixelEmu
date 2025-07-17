//
//  DriveResponse.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/23/24.
//

import Foundation


class DriveResponse : Decodable {
    var files: [File]
}

class File : Decodable {
    var id: String
    var name: String
    var parents: [String]?
}
