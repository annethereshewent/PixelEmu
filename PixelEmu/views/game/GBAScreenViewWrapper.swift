//
//  GBAScreenViewWrapper.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/29/24.
//

import SwiftUI
import GBAEmulatorMobile

struct GBAScreenViewWrapper: View {
    @Binding var gameController: GameController?
    @Binding var image: CGImage?
    @Binding var emulator: GBAEmulator?
    @Binding var buttonStarted: [GBAButtonEvent:Bool]
    @Binding var audioManager: AudioManager?
    @Binding var isSoundOn: Bool
    @Binding var isHoldButtonsPresented: Bool
    @Binding var heldButtons: Set<GBAButtonEvent>
    @Binding var themeColor: Color

    @EnvironmentObject var orientationInfo: OrientationInfo

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)

    // these are to access image width/height easily, and scale them proportionately
    private let rectangleImage = UIImage(named: "Rectangle")
    private let shoulderButton = UIImage(named: "L Button")
    private let volumeButton = UIImage(named: "Volume Button")

    private var buttonScale: CGFloat {
        if orientationInfo.orientation == .landscape {
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
        if orientationInfo.orientation == .portrait {
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
        if orientationInfo.orientation == .portrait {
            return CGFloat(GBA_SCREEN_WIDTH) * 1.8
        }

        return CGFloat(GBA_SCREEN_WIDTH) * 1.5
    }

    private var rectangleHeight: CGFloat {
        if orientationInfo.orientation == .portrait {
            return CGFloat(GBA_SCREEN_HEIGHT) * 2.0
        }

        return CGFloat(GBA_SCREEN_WIDTH) * 1.1
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
                    GBAScreenView(
                        gameController: $gameController,
                        image: $image,
                        isHoldButtonsPresented: $isHoldButtonsPresented,
                        themeColor: $themeColor,
                        emulator: $emulator,
                        heldButtons: $heldButtons
                    )
                }
                .padding(.top, padding)
                if gameController?.controller?.extendedGamepad == nil {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Image("L Button")
                                .resizable()
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged() { result in
                                            if !buttonStarted[GBAButtonEvent.ButtonL]! {
                                                feedbackGenerator.impactOccurred()
                                                buttonStarted[GBAButtonEvent.ButtonL] = true
                                            }
                                            emulator?.updateInput(GBAButtonEvent.ButtonL, true)
                                        }
                                        .onEnded() { result in
                                            buttonStarted[GBAButtonEvent.ButtonL] = false
                                            emulator?.updateInput(GBAButtonEvent.ButtonL, false)
                                        }
                                )
                                .frame(width: shoulderButton!.size.width * buttonScale, height: shoulderButton!.size.height * buttonScale)
                            Spacer()
                            Button {
                                if let manager = audioManager {
                                    feedbackGenerator.impactOccurred()
                                    manager.toggleAudio()

                                    isSoundOn = !manager.playerPaused

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
                                            if !buttonStarted[GBAButtonEvent.ButtonR]! {
                                                feedbackGenerator.impactOccurred()
                                                buttonStarted[GBAButtonEvent.ButtonR] = true
                                            }
                                            emulator?.updateInput(GBAButtonEvent.ButtonR, true)
                                        }
                                        .onEnded() { result in
                                            buttonStarted[GBAButtonEvent.ButtonR] = false
                                            emulator?.updateInput(GBAButtonEvent.ButtonR, false)
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
