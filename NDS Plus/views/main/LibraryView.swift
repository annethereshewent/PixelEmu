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
    private let chosenColor = Color(
        red: 0xf6 / 0xff,
        green: 0x96 / 0xff,
        blue: 0x31 / 0xff
    )
    
    private let defaultColor = Color(
        red: 0x88 / 0xff,
        green: 0x88 / 0xff,
        blue: 0x88 / 0xff
    )
    
    @State private var recentColor = Color(
        red: 0xf6 / 0xff,
        green: 0x96 / 0xff,
        blue: 0x31 / 0xff
    )
    
    @State private var allColor = Color(
        red: 0x88 / 0xff,
        green: 0x88 / 0xff,
        blue: 0x88 / 0xff
    )
    @State private var filter = LibraryFilter.recent
    
    @Query private var games: [Game] = []
    
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
    
    private var filteredGames: [Game] {
        switch filter {
        case .all:
            return games
        case .recent:
            return games.filter { game in
                let today = Date.now
                let diff = today.timeIntervalSince1970 - game.addedOn.timeIntervalSince1970
                
                return diff <= Double(TWENTYFOUR_HOURS)
            }
        }
    }
    
    var body: some View {
       
        VStack {
            Text("Game Library")
                .fontWeight(.bold)
            HStack {
                Spacer()
                    
                Button {
                    recentColor = chosenColor
                    allColor = defaultColor
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
                    allColor = chosenColor
                    recentColor = defaultColor
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
                games: filteredGames
            )
        }
        .font(.custom("Departure Mono", size: 24.0))
        .foregroundColor(Color(red: 0x88 / 0xff, green: 0x88 / 0xff, blue: 0x88 / 0xff))
    }
}
