//
//  PixelEmuApp.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI

@main
struct PixelEmuApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Game.self, SaveState.self, GBAGame.self, GBASaveState.self, N64Game.self])
                .environmentObject(OrientationInfo())
        }
    }
}
