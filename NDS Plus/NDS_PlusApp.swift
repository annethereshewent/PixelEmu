//
//  NDS_PlusApp.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI

@main
struct NDS_PlusApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Game.self])
        }
    }
}
