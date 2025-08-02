//
//  GameScreensViewWrapper.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/13/24.
//

import SwiftUI
import DSEmulatorMobile

struct DualScreenViewWrapper: View {
    @Binding var gameController: GameController?
    @Binding var topImage: CGImage?
    @Binding var bottomImage: CGImage?
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var buttonStarted: [PressedButton:Bool]
    @Binding var audioManager: AudioManager?
    @Binding var isSoundOn: Bool
    @Binding var isHoldButtonsPresented: Bool
    @Binding var heldButtons: Set<PressedButton>
    @Binding var themeColor: Color

    var renderingData: RenderingData
    var renderingDataBottom: RenderingData

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // these are to access image width/height easily, and scale them proportionately
    private let rectangleImage = UIImage(named: "Rectangle")
    private let shoulderButton = UIImage(named: "L Button")
    private let volumeButton = UIImage(named: "Volume Button")

    private var buttonScale: CGFloat {
        if UIDevice.current.orientation.isLandscape{
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
        if gameController?.controller?.extendedGamepad == nil {
            return 40.0
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
        if UIDevice.current.orientation.isLandscape {
            return rectangleImage!.size.height * 1.02
        }

        return rectangleImage!.size.width * 1.05
    }

    private var rectangleHeight: CGFloat {
        if UIDevice.current.orientation.isLandscape {
            return rectangleImage!.size.width * 0.70
        }

        return rectangleImage!.size.height * 0.9
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
                if UIDevice.current.orientation.isPortrait {
                    VStack {
                        DualScreenView(
                            gameController: $gameController,
                            topImage: $topImage,
                            bottomImage: $bottomImage,
                            isHoldButtonsPresented: $isHoldButtonsPresented,
                            themeColor: $themeColor,
                            emulator: $emulator,
                            heldButtons: $heldButtons,
                            renderingData: renderingData,
                            renderingDataBottom: renderingDataBottom
                        )
                    }
                    .padding(.top, padding)
                } else {
                    HStack {
                        DualScreenView(
                            gameController: $gameController,
                            topImage: $topImage,
                            bottomImage: $bottomImage,
                            isHoldButtonsPresented: $isHoldButtonsPresented,
                            themeColor: $themeColor,
                            emulator: $emulator,
                            heldButtons: $heldButtons,
                            renderingData: renderingData,
                            renderingDataBottom: renderingDataBottom
                        )
                    }
                    .padding(.top, landscapePadding)
                    .padding(.leading, landscapeLeading)
                }
                if gameController?.controller?.extendedGamepad == nil {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
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
                            Spacer()
                            Button {
                                if let manager = audioManager {
                                    feedbackGenerator.impactOccurred()
                                    manager.toggleAudio()

                                    isSoundOn = !manager.playerPaused

                                    emulator!.setPausedAudio(manager.playerPaused)

                                    let defaults = UserDefaults.standard

                                    defaults.setValue(isSoundOn, forKey: "isSoundOn")
                                }
                            } label: {
                                Image("Volume Button")
                                    .resizable()
                                    .frame(width: volumeButton!.size.width * buttonScale, height: volumeButton!.size.height * buttonScale)
                            }
                            Spacer()
                            Image("R Button")
                                .resizable()
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged() { result in
                                            if !buttonStarted[PressedButton.ButtonR]! {
                                                feedbackGenerator.impactOccurred()
                                                buttonStarted[PressedButton.ButtonR] = true
                                            }
                                            emulator?.updateInput(PressedButton.ButtonR, true)
                                        }
                                        .onEnded() { result in
                                            buttonStarted[PressedButton.ButtonR] = false
                                            emulator?.updateInput(PressedButton.ButtonR, false)
                                        }
                                )
                                .frame(width: shoulderButton!.size.width * buttonScale, height: shoulderButton!.size.height * buttonScale)
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
