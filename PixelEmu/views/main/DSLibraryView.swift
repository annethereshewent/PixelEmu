//
//  DSLibraryView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/28/24.
//

import SwiftUI

import DSEmulatorMobile

struct DSLibraryView: View {
    @Binding var recentColor: Color
    @Binding var allColor: Color
    @Binding var filter: LibraryFilter

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
    @Binding var themeColor: Color

    var body: some View {
        VStack {
            HStack {
                Spacer()

                Button {
                    recentColor = themeColor
                    allColor = Colors.primaryColor
                    filter = .recent
                } label: {
                    HStack {
                        if filter == .recent {
                            Image("Caret")
                                .foregroundColor(themeColor)
                        }
                        Text("Recent")
                            .foregroundColor(recentColor)
                    }
                }

                Spacer()
                Button {
                    allColor = themeColor
                    recentColor = Colors.primaryColor
                    filter = .all
                } label: {
                    HStack {
                        if filter == .all {
                            Image("Caret")
                                .foregroundColor(themeColor)
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
                themeColor: $themeColor
            )

        }
        .onAppear() {
            recentColor = themeColor
            filter = LibraryFilter.recent
            allColor = Colors.primaryColor
        }
        .font(.custom("Departure Mono", size: 24.0))
        .foregroundColor(Colors.primaryColor)
    }
}
