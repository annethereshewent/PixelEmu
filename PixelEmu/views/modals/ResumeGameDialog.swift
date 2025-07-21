//
//  ResumeGameDialog.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/19/24.
//

import SwiftUI

struct ResumeGameDialog: View {
    @Binding var showDialog: Bool
    @Binding var resumeGame: Bool
    @Binding var settingChanged: Bool
    @Binding var themeColor: Color

    var body: some View {
        VStack {
            Text("Resume game")
                .foregroundColor(themeColor)
                .font(.custom("Departure Mono", size: 24))
            Text("Game is already running. Would you like to resume?")

            HStack {
                Button("Resume") {
                    resumeGame = true
                    settingChanged = !settingChanged
                    showDialog = false

                }
                .foregroundColor(.green)
                .border(.gray)
                .cornerRadius(0.3)
                .padding(.top, 20)
                Button("Start new game") {
                    resumeGame = false
                    settingChanged = !settingChanged
                    showDialog = false
                }
                .foregroundColor(themeColor)
                .border(.gray)
                .cornerRadius(0.3)
                .padding(.top, 20)
            }
        }
        .background(Colors.backgroundColor)
        .frame(width: 300, height: 300)
        .opacity(0.9)
        .font(.custom("Departure Mono", size: 20))
    }
}
