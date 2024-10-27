//
//  GameMenuView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI
import DSEmulatorMobile

struct GameMenuView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var emulator: MobileEmulator?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var audioManager: AudioManager?
    @Binding var isMenuPresented: Bool
    @Binding var gameName: String
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var shouldGoHome: Bool
    @Binding var game: Game?
    @Binding var isHoldButtonsPresented: Bool

    @State var isStateEntriesPresented: Bool = false
    
    private var color: Color {
        switch colorScheme {
        case .dark:
            return Color.white
        case .light:
            return Color.black
        @unknown default:
            return Color.white
        }
    }
    
    private func goHome() {
        isMenuPresented = false
        shouldGoHome = true
    }
    var body: some View {
        VStack {
            HStack {
                Button("Home") {
                    goHome()
                }
                .foregroundColor(.red)
                .font(.custom("Departure Mono", size: 24))
                Spacer()
                Spacer()
            }
            .padding(.leading, 25)
            HStack {
                Spacer()
                Button() {
                    isStateEntriesPresented = true
                } label: {
                    VStack {
                        Image(systemName: "tray.and.arrow.up")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Save states")
                    }
                }
                Spacer()
                Button() {
                    isHoldButtonsPresented = true
                    isMenuPresented = false
                } label: {
                    VStack {
                        Image(systemName: "button.horizontal.top.press.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Hold Button")
                    }
                    
                }
                Spacer()
                Button() {
                    isMenuPresented = false
                } label: {
                    VStack {
                        Image(systemName: "play")
                            .resizable()
                            .frame(width: 35, height: 35)
                        Text("Resume game")
                    }
                }
                
                Spacer()
            }
            .onDisappear() {
                if !isHoldButtonsPresented {
                    if let emu = emulator {
                        emu.setPause(false)
                    }
                }
            }
            .presentationDetents([.height(150)])
        }
        .foregroundColor(Colors.primaryColor)
        .font(.custom("Departure Mono", size: 16))
        .foregroundColor(color)
        .sheet(isPresented: $isStateEntriesPresented) {
            SaveStateEntriesView(
                emulator: $emulator,
                gameName: $gameName,
                isMenuPresented: $isMenuPresented,
                game: $game,
                bios7Data: $bios7Data,
                bios9Data: $bios9Data,
                firmwareData: $firmwareData,
                romData: $romData
            )
        }
    }
}
