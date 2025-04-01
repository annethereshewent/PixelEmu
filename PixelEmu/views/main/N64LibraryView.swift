//
//  N64LibraryView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 3/31/25.
//

import SwiftUI

struct N64LibraryView: View {
    @Binding var recentColor: Color
    @Binding var allColor: Color
    @Binding var filter: LibraryFilter

    @Binding var romData: Data?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var gameUrl: URL?
    @Binding var path: NavigationPath
    @Binding var game: N64Game?
    @Binding var themeColor: Color
    @Binding var isPaused: Bool

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
            N64ListView(
                romData: $romData,
                isRunning: $isRunning,
                workItem: $workItem,
                gameUrl: $gameUrl,
                path: $path,
                game: $game,
                filter: $filter,
                themeColor: $themeColor,
                isPaused: $isPaused
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
