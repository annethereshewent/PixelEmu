//
//  NDS_PlusApp.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/15/24.
//

import SwiftUI
import SwiftData

@main
struct NDS_PlusApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Game.self,
                migrationPlan: GameMigrationPlan.self
            )
        } catch {
            fatalError("Failed to initialize model container.")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .modelContainer(for: [SaveState.self])
                .environmentObject(OrientationInfo())
        }
    }
}
