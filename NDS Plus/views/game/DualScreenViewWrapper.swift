//
//  GameScreensViewWrapper.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/13/24.
//

import SwiftUI
import DSEmulatorMobile

struct DualScreenViewWrapper: View {
    @Binding var gameController: GameController?
    @Binding var topImage: CGImage?
    @Binding var bottomImage: CGImage?
    @Binding var emulator: MobileEmulator?
    @Binding var buttonStarted: [ButtonEvent:Bool]
    @Binding var audioManager: AudioManager?
    @Binding var isSoundOn: Bool
    @Binding var isHoldButtonsPresented: Bool
    @Binding var heldButtons: Set<ButtonEvent>
    @Binding var themeColor: Color

    @EnvironmentObject var orientationInfo: OrientationInfo
  
    // these are to access image width/height easily, and scale them proportionately
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    private let rectangleImage = UIImage(named: "Rectangle")
    private let shoulderButton = UIImage(named: "L Button")
    private let volumeButton = UIImage(named: "Volume Button")

    private var buttonScale: CGFloat {
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
    
    var body: some View {
        ZStack {
            if gameController?.controller?.extendedGamepad == nil {
                Image("Rectangle")
                    .resizable()
                    .frame(width: rectangleImage!.size.width * 1.05, height: rectangleImage!.size.height * 0.9 )
            }
            VStack(spacing: 0) {
                if orientationInfo.orientation == .portrait {
                    VStack {
                        DualScreenView(
                            gameController: $gameController,
                            topImage: $topImage,
                            bottomImage: $bottomImage,
                            isHoldButtonsPresented: $isHoldButtonsPresented,
                            themeColor: $themeColor,
                            emulator: $emulator,
                            heldButtons: $heldButtons,
                            isPortrait: true
                        )
                    }
                    .padding(.top, padding)
                } else if orientationInfo.orientation == .landscape {
                    HStack {
                        DualScreenView(
                            gameController: $gameController,
                            topImage: $topImage,
                            bottomImage: $bottomImage,
                            isHoldButtonsPresented: $isHoldButtonsPresented,
                            themeColor: $themeColor,
                            emulator: $emulator,
                            heldButtons: $heldButtons,
                            isPortrait: false
                        )
                    }
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
                                            if !buttonStarted[ButtonEvent.ButtonL]! {
                                                feedbackGenerator.impactOccurred()
                                                buttonStarted[ButtonEvent.ButtonL] = true
                                            }
                                            emulator?.updateInput(ButtonEvent.ButtonL, true)
                                        }
                                        .onEnded() { result in
                                            buttonStarted[ButtonEvent.ButtonL] = false
                                            emulator?.updateInput(ButtonEvent.ButtonL, false)
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
                                            if !buttonStarted[ButtonEvent.ButtonR]! {
                                                feedbackGenerator.impactOccurred()
                                                buttonStarted[ButtonEvent.ButtonR] = true
                                            }
                                            emulator?.updateInput(ButtonEvent.ButtonR, true)
                                        }
                                        .onEnded() { result in
                                            buttonStarted[ButtonEvent.ButtonR] = false
                                            emulator?.updateInput(ButtonEvent.ButtonR, false)
                                        }
                                )
                                .frame(width: shoulderButton!.size.width * buttonScale, height: shoulderButton!.size.height * buttonScale)
                            Spacer()
                        }
                    }
                }
            }
        }
        .onAppear() {
            let defaults = UserDefaults.standard

            if let themeColor = defaults.value(forKey: "themeColor") as? Color {
                self.themeColor = themeColor
            }
        }
    }
}
