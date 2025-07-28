//
//  GameMenuView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI
import DSEmulatorMobile
import GBAEmulatorMobile

struct GameMenuView: View {
    let gameType: GameType
    @Environment(\.colorScheme) private var colorScheme
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var audioManager: AudioManager?
    @Binding var isMenuPresented: Bool
    @Binding var gameName: String
    @Binding var biosData: Data?
    @Binding var bios7Data: Data?
    @Binding var bios9Data: Data?
    @Binding var firmwareData: Data?
    @Binding var romData: Data?
    @Binding var shouldGoHome: Bool
    @Binding var game: (any Playable)?
    @Binding var isHoldButtonsPresented: Bool
    @Binding var isSoundOn: Bool
    @Binding var gameController: GameController?
    @Binding var themeColor: Color

    @State private var isStateEntriesPresented: Bool = false
    @State private var isPalettePickerPresented: Bool = false

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
                if gameController?.controller?.extendedGamepad == nil {
                    Button() {
                        isHoldButtonsPresented = true
                        isMenuPresented = false
                    } label: {
                        VStack {
                            Image(systemName: "button.horizontal.top.press.fill")
                                .resizable()
                                .frame(width: 35, height: 35)
                            Text("Hold button")
                        }

                    }
                } else {
                    Button {
                        isSoundOn = !isSoundOn

                        if isSoundOn {
                            audioManager?.resumeAudio()
                        } else {
                            audioManager?.muteAudio()
                        }

                        let defaults = UserDefaults.standard

                        defaults.setValue(isSoundOn, forKey: "isSoundOn")

                        isMenuPresented = false
                    } label: {
                        VStack {
                            if isSoundOn {
                                Image(systemName: "speaker.slash")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                Text("Mute audio")
                            } else {
                                Image(systemName: "speaker")
                                    .resizable()
                                    .frame(width: 35, height: 35)
                                Text("Unmute audio")
                            }
                        }
                    }
                }
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
                if game!.type == .gbc {
                    Button {
                        isPalettePickerPresented = true
                    } label: {
                        VStack {
                            Image(systemName: "paintpalette")
                                .resizable()
                                .frame(width: 35, height: 35)
                            Text("Pick palette")
                        }

                    }
                }
            }
            .onDisappear() {
                if !isHoldButtonsPresented && !shouldGoHome {
                    emulator?.setPaused(false)
                    if isSoundOn {
                        audioManager?.resumeAudio()
                    }
                }
            }
        }
        .presentationDetents([.height(150)])
        .foregroundColor(Colors.primaryColor)
        .font(.custom("Departure Mono", size: 16))
        .foregroundColor(color)
        .sheet(isPresented: $isStateEntriesPresented) {
            SaveStateEntriesView(
                emulator: $emulator,
                gameName: $gameName,
                isMenuPresented: $isMenuPresented,
                game: $game,
                biosData: $biosData,
                bios7Data: $bios7Data,
                bios9Data: $bios9Data,
                firmwareData: $firmwareData,
                romData: $romData
            )
        }
        .sheet(isPresented: $isPalettePickerPresented) {
            PalettePickerView(
                themeColor: $themeColor,
                emulator: $emulator,
                isPresented: $isPalettePickerPresented,
                isMenuPresented: $isMenuPresented
            )
        }
    }
}
