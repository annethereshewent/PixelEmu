//
//  GBScreenViewWrapper.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 11/29/24.
//

import SwiftUI
import GBAEmulatorMobile

struct GBScreenViewWrapper: View {
    let gameType: GameType
    @Binding var gameController: GameController?
    @Binding var image: CGImage?
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var buttonStarted: [PressedButton:Bool]
    @Binding var audioManager: AudioManager?
    @Binding var isSoundOn: Bool
    @Binding var isHoldButtonsPresented: Bool
    @Binding var heldButtons: Set<PressedButton>
    @Binding var themeColor: Color
    var renderingData: RenderingData

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // these are to access image width/height easily, and scale them proportionately
    private let rectangleImage = UIImage(named: "Rectangle")
    private let shoulderButton = UIImage(named: "L Button")
    private let volumeButton = UIImage(named: "Volume Button")

    private var buttonScale: CGFloat {
        if UIDevice.current.orientation.isLandscape {
            return 0.90
        }

        let rect = UIScreen.main.bounds

        if rect.height > 852.0 {
            return 1.1
        } else {
            return 1.05
        }
    }

    private var padding: CGFloat {
        if UIDevice.current.orientation.isPortrait {
            if gameController?.controller?.extendedGamepad == nil {
                return 40.0
            }
        }

        if gameController?.controller?.extendedGamepad == nil {
            return 25.0
        }

        return 0.0
    }

    private var landscapePadding: CGFloat {
        if gameController?.controller?.extendedGamepad == nil {
            return 30.0
        }

        return 0.0
    }

    private var rectangleWidth: CGFloat {
        let width = gameType == .gba ? GBA_SCREEN_WIDTH : GBC_SCREEN_WIDTH
        if UIDevice.current.orientation.isPortrait {
            return gameType == .gba ? CGFloat(width) * 1.7 : CGFloat(width) * 2.2
        }

        return gameType == .gba ? CGFloat(width) * 1.8 : CGFloat(width) * 1.95
    }

    private var rectangleHeight: CGFloat {
        let height = gameType == .gba ? GBA_SCREEN_HEIGHT : GBC_SCREEN_WIDTH

        if UIDevice.current.orientation.isPortrait {
            return gameType == .gba ? CGFloat(height) * 1.8 : CGFloat(height) * 1.97
        }

        return gameType == .gba ? CGFloat(height) * 1.8 : CGFloat(height) * 1.70
    }

    private var landscapeLeading: CGFloat {
        if gameController?.controller?.extendedGamepad == nil {
            return 0
        } else {
            return 40
        }
    }

    var body: some View {
        ZStack {
            if gameController?.controller?.extendedGamepad == nil {
                Image("Rectangle")
                    .resizable()
                    .frame(width: rectangleWidth, height: rectangleHeight )
            }
            VStack(spacing: 0) {
                VStack {
                    GBScreenView(
                        gameType: gameType,
                        gameController: $gameController,
                        image: $image,
                        isHoldButtonsPresented: $isHoldButtonsPresented,
                        themeColor: $themeColor,
                        emulator: $emulator,
                        heldButtons: $heldButtons,
                        renderingData: renderingData
                    )
                }
                .padding(.top, padding)
                if gameController?.controller?.extendedGamepad == nil {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            if gameType != .gbc {
                                Image("L Button")
                                    .resizable()
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged() { result in
                                                if !buttonStarted[PressedButton.ButtonL]! {
                                                    feedbackGenerator.impactOccurred()
                                                    buttonStarted[PressedButton.ButtonL] = true
                                                }
                                                emulator?.updateInput(PressedButton.ButtonL, true)
                                            }
                                            .onEnded() { result in
                                                buttonStarted[PressedButton.ButtonL] = false
                                                emulator?.updateInput(PressedButton.ButtonL, false)
                                            }
                                    )
                                    .frame(width: shoulderButton!.size.width * buttonScale, height: shoulderButton!.size.height * buttonScale)
                            }
                            Spacer()
                            Button {
                                if let manager = audioManager, let emulator = emulator {
                                    feedbackGenerator.impactOccurred()
                                    manager.toggleAudio()

                                    isSoundOn = !manager.playerPaused
                                    emulator.setPausedAudio(manager.playerPaused)

                                    let defaults = UserDefaults.standard

                                    defaults.setValue(isSoundOn, forKey: "isSoundOn")
                                }
                            } label: {
                                Image("Volume Button")
                                    .resizable()
                                    .frame(width: volumeButton!.size.width * buttonScale, height: volumeButton!.size.height * buttonScale)
                            }
                            Spacer()
                            if gameType != .gbc {
                                Image("R Button")
                                    .resizable()
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged() { result in
                                                if !buttonStarted[.ButtonR]! {
                                                    feedbackGenerator.impactOccurred()
                                                    buttonStarted[.ButtonR] = true
                                                }
                                                emulator?.updateInput(.ButtonR, true)
                                            }
                                            .onEnded() { result in
                                                buttonStarted[.ButtonR] = false
                                                emulator?.updateInput(.ButtonR, false)
                                            }
                                    )
                                    .frame(width: shoulderButton!.size.width * buttonScale, height: shoulderButton!.size.height * buttonScale)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
