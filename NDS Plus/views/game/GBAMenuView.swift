//
//  GBAMenuView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 12/6/24.
//

import SwiftUI
import GBAEmulatorMobile

struct GBAMenuView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Binding var emulator: GBAEmulator?
    @Binding var backupFile: GBABackupFile?
    @Binding var isRunning: Bool
    @Binding var workItem: DispatchWorkItem?
    @Binding var audioManager: AudioManager?
    @Binding var isMenuPresented: Bool
    @Binding var gameName: String
    @Binding var biosData: Data?
    @Binding var romData: Data?
    @Binding var shouldGoHome: Bool
    @Binding var game: GBAGame?
    @Binding var isHoldButtonsPresented: Bool
    @Binding var isSoundOn: Bool
    @Binding var gameController: GameController?

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
                    Button() {
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
            GBAStateEntriesView(
                emulator: $emulator,
                backupFile: $backupFile,
                gameName: $gameName,
                isMenuPresented: $isMenuPresented,
                game: $game,
                biosData: $biosData,
                romData: $romData
            )
        }
    }
}
