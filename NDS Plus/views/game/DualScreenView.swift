//
//  GameScreensView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/13/24.
//

import SwiftUI
import DSEmulatorMobile

struct DualScreenView: View {
    @Binding var gameController: GameController?
    private let rectangleImage = UIImage(named: "Rectangle")
    @Binding var topImage: CGImage?
    @Binding var bottomImage: CGImage?
    @Binding var emulator: MobileEmulator?
    @Binding var buttonStarted: [ButtonEvent:Bool]
    @Binding var audioManager: AudioManager?
    @Binding var isSoundOn: Bool
    
    private var screenRatio: Float {
        if gameController?.controller?.extendedGamepad == nil {
            SCREEN_RATIO
        } else {
            FULLSCREEN_RATIO
        }
    }
  
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var padding: CGFloat {
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
                VStack{
                    if gameController?.controller?.extendedGamepad != nil {
                        Spacer()
                    }
                    GameScreenView(image: $topImage)
                        .frame(
                            width: CGFloat(SCREEN_WIDTH) * CGFloat(screenRatio),
                            height: CGFloat(SCREEN_HEIGHT) * CGFloat(screenRatio)
                        )
                    GameScreenView(image: $bottomImage)
                        .frame(
                            width: CGFloat(SCREEN_WIDTH) * CGFloat(screenRatio),
                            height: CGFloat(SCREEN_HEIGHT) * CGFloat(screenRatio)
                        ) 
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged() { value in
                                    if value.location.x >= 0 &&
                                        value.location.y >= 0 &&
                                        value.location.x < CGFloat(SCREEN_WIDTH) * CGFloat(screenRatio) &&
                                        value.location.y < CGFloat(SCREEN_HEIGHT) * CGFloat(screenRatio)
                                    {
                                        let x = UInt16(Float(value.location.x) / screenRatio)
                                        let y = UInt16(Float(value.location.y) / screenRatio)
                                        emulator?.touchScreen(x, y)
                                    } else {
                                        emulator?.releaseScreen()
                                    }
                                }
                                .onEnded() { value in
                                    if value.location.x >= 0 &&
                                        value.location.y >= 0 &&
                                        value.location.x < CGFloat(SCREEN_WIDTH) &&
                                        value.location.y < CGFloat(SCREEN_HEIGHT)
                                    {
                                        let x = UInt16(Float(value.location.x) / screenRatio)
                                        let y = UInt16(Float(value.location.y) / screenRatio)
                                        emulator?.touchScreen(x, y)
                                        DispatchQueue.global().async(execute: DispatchWorkItem {
                                            usleep(200)
                                            DispatchQueue.main.sync() {
                                                emulator?.releaseScreen()
                                            }
                                        })
                                    } else {
                                        emulator?.releaseScreen()
                                    }
                                    
                                }
                        )
                    if gameController?.controller?.extendedGamepad != nil {
                        Spacer()
                    }
                }
                .padding(.top, padding)
                if gameController?.controller?.extendedGamepad == nil {
                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            Image("L Button")
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
                            }
                            Spacer()
                            Image("R Button")
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
                            Spacer()
                        }
                    }
                }
            }
        }
    }
}
