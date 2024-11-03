//
//  Game.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/18/24.
//

import Foundation
import SwiftData
import UIKit

let ICON_WIDTH = 32
let ICON_HEIGHT = 32

enum GameSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Game.self]
    }

    @Model
    class Game {
        @Attribute(.unique)
        var gameName: String
        var bookmark: Data
        var gameIcon: [UInt8]
        @Relationship(deleteRule: .cascade, inverse: \SaveState.game)
        var saveStates: [SaveState]
        @Attribute(originalName: "addedOn")
        var lastPlayed: Date


        init(gameName: String, bookmark: Data, gameIcon: [UInt8], saveStates: [SaveState], lastPlayed: Date) {
            self.bookmark = bookmark
            self.gameName = gameName
            self.gameIcon = gameIcon
            self.saveStates = saveStates
            self.lastPlayed = lastPlayed
        }

        static func storeGame(gameName: String, data: Data, url: URL, iconPtr: UnsafePointer<UInt8>) -> Game? {
            let buffer = UnsafeBufferPointer(start: iconPtr, count: ICON_WIDTH * ICON_HEIGHT * 4)

            let pixelsArr = Array(buffer)

            // store bookmark for later use
            if url.startAccessingSecurityScopedResource() {
                if let bookmark = try? url.bookmarkData(options: []) {
                    return Game(gameName: gameName, bookmark: bookmark, gameIcon: pixelsArr, saveStates: [], lastPlayed: Date.now)
                }
            }


            return nil
        }
    }
}

enum GameSchemaV1_1_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 1, 0)

    static var models: [any PersistentModel.Type] {
        [Game.self]
    }

    @Model
    class Game {
        @Attribute(.unique)
        var gameName: String
        var bookmark: Data
        @Attribute(originalName: "gameIcon")
        var deleteMe: [UInt8]
        var gameIconNew: Data?
        @Relationship(deleteRule: .cascade, inverse: \SaveState.game)
        var saveStates: [SaveState]
        @Attribute(originalName: "addedOn")
        var lastPlayed: Date


        init(gameName: String, bookmark: Data, gameIcon: [UInt8], saveStates: [SaveState], lastPlayed: Date) {
            self.bookmark = bookmark
            self.gameName = gameName
            self.deleteMe = gameIcon
            self.gameIconNew = Data(gameIcon)
            self.saveStates = saveStates
            self.lastPlayed = lastPlayed
        }

        static func storeGame(gameName: String, data: Data, url: URL, iconPtr: UnsafePointer<UInt8>) -> Game? {
            let buffer = UnsafeBufferPointer(start: iconPtr, count: ICON_WIDTH * ICON_HEIGHT * 4)

            let pixelsArr = Array(buffer)

            // store bookmark for later use
            if url.startAccessingSecurityScopedResource() {
                if let bookmark = try? url.bookmarkData(options: []) {
                    return Game(gameName: gameName, bookmark: bookmark, gameIcon: pixelsArr, saveStates: [], lastPlayed: Date.now)
                }
            }


            return nil
        }
    }
}

enum GameMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [GameSchemaV1.self, GameSchemaV1_1_0.self, GameSchemaV2_0_0.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1_0_0toV1_1_0, migrateV1_1_0toV2_0_0]
    }

    static let migrateV1_0_0toV1_1_0 = MigrationStage.custom(
        fromVersion: GameSchemaV1.self,
        toVersion: GameSchemaV1_1_0.self,
        willMigrate: nil,
        didMigrate: { context in
            var instances: [GameSchemaV1_1_0.Game] = []
            // Fetch a list of all instances
            do {
                instances = try context.fetch(FetchDescriptor<GameSchemaV1_1_0.Game>())
            } catch {
                print("Error while fetching instances from persistent data model")
            }

            for instance in instances {
                instance.gameIconNew = Data(instance.deleteMe)
            }
            do {
                try context.save() // Don't forget to save or SwiftData might crash your app!
            } catch {
                print("Saving context failed")
            }
        }
    )

    static let migrateV1_1_0toV2_0_0 = MigrationStage.lightweight(
        fromVersion: GameSchemaV1_1_0.self,
        toVersion: GameSchemaV2_0_0.self
    )
}

enum GameSchemaV2_0_0: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Game.self]
    }

    @Model
    class Game {
        @Attribute(.unique)
        var gameName: String
        var bookmark: Data
        @Attribute(originalName: "gameIconNew")
        var gameIcon: Data
        @Relationship(deleteRule: .cascade, inverse: \SaveState.game)
        var saveStates: [SaveState]
        @Attribute(originalName: "addedOn")
        var lastPlayed: Date


        init(gameName: String, bookmark: Data, gameIcon: [UInt8], saveStates: [SaveState], lastPlayed: Date) {
            self.bookmark = bookmark
            self.gameName = gameName
            self.gameIcon = Data(gameIcon)
            self.saveStates = saveStates
            self.lastPlayed = lastPlayed
        }

        static func storeGame(gameName: String, data: Data, url: URL, iconPtr: UnsafePointer<UInt8>) -> Game? {
            let buffer = UnsafeBufferPointer(start: iconPtr, count: ICON_WIDTH * ICON_HEIGHT * 4)

            let pixelsArr = Array(buffer)

            // store bookmark for later use
            if url.startAccessingSecurityScopedResource() {
                if let bookmark = try? url.bookmarkData(options: []) {
                    return Game(gameName: gameName, bookmark: bookmark, gameIcon: pixelsArr, saveStates: [], lastPlayed: Date.now)
                }
            }


            return nil
        }
    }
}


typealias Game = GameSchemaV2_0_0.Game

