//
//  LibraryView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI
import DSEmulatorMobile
import SwiftData

let TWENTYFOUR_HOURS = 60 * 60 * 24

enum LibraryFilter {
    case recent
    case all
}

struct LibraryView: View {
    
    @State private var recentColor = Colors.accentColor
    @State private var allColor = Colors.primaryColor
    @State private var filter = LibraryFilter.recent
    
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
    @Binding var shouldUpdateGame: Bool
    
    var body: some View {
       
        VStack {
            Text("Game library")
                .fontWeight(.bold)
            HStack {
                Spacer()
                    
                Button {
                    recentColor = Colors.accentColor
                    allColor = Colors.primaryColor
                    filter = .recent
                } label: {
                    HStack {
                        if filter == .recent {
                            Image("Caret")
                        }
                        Text("Recent")
                            .foregroundColor(recentColor)
                    }
                }
                
                Spacer()
                Button {
                    allColor = Colors.accentColor
                    recentColor = Colors.primaryColor
                    filter = .all
                } label: {
                    HStack {
                        if filter == .all {
                            Image("Caret")
                        }
                        Text("All")
                            .foregroundColor(allColor)
                    }
                }
               
                Spacer()
            }
            .padding(.top, 10)
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
                game: $game,
                filter: $filter,
                shouldUpdateGame: $shouldUpdateGame
            )
        }
        .font(.custom("Departure Mono", size: 24.0))
        .foregroundColor(Colors.primaryColor)
    }
}
