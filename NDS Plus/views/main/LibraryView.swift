//
//  LibraryView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI
import DSEmulatorMobile

struct LibraryView: View {
    @Binding var romData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var emulator: MobileEmulator?
    @Binding var gameUrl: URL?
    @Binding var path: NavigationPath
    @Binding var game: Game?
    
    var body: some View {
       
        VStack {
            Text("Game Library")
            HStack {
                Spacer()
                Text("Recent")
                Spacer()
                Text("All")
                Spacer()
            }
            GamesListView(
                romData: $romData,
                bios7Data: $bios7Data,
                bios9Data: $bios9Data,
                firmwareData: $firmwareData,
                isRunning: $isRunning,
                workItem: $workItem,
                emulator: $emulator,
                gameUrl: $gameUrl,
                path: $path,
                game: $game
            )
        }
        .font(.custom("Departure Mono", size: 24.0))
        .foregroundColor(Color(red: 0x88 / 0xff, green: 0x88 / 0xff, blue: 0x88 / 0xff))
    }
}
