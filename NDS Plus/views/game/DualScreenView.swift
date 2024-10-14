//
//  GameScreensView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/13/24.
//

import SwiftUI
import DSEmulatorMobile

struct DualScreenView: View {
    private let rectangleImage = UIImage(named: "Rectangle")
    @Binding var topImage: CGImage?
    @Binding var bottomImage: CGImage?
    @Binding var emulator: MobileEmulator?
    @Binding var buttonStarted: [ButtonEvent:Bool]
  
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        Image("Rectangle")
            .resizable()
            .frame(width: rectangleImage!.size.width * 1.05, height: rectangleImage!.size.height * 0.9 )
        VStack(spacing: 0) {
            VStack{
                GameScreenView(image: $topImage)
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * CGFloat(SCREEN_RATIO),
                        height: CGFloat(SCREEN_HEIGHT) * CGFloat(SCREEN_RATIO)
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                GameScreenView(image: $bottomImage)
                    .frame(
                        width: CGFloat(SCREEN_WIDTH) * CGFloat(SCREEN_RATIO),
                        height: CGFloat(SCREEN_HEIGHT) * CGFloat(SCREEN_RATIO)
                    )
                    .shadow(color: .gray, radius: 1.0, y: 1)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged() { value in
                                if value.location.x >= 0 &&
                                    value.location.y >= 0 &&
                                    value.location.x < CGFloat(SCREEN_WIDTH) * CGFloat(SCREEN_RATIO) &&
                                    value.location.y < CGFloat(SCREEN_HEIGHT) * CGFloat(SCREEN_RATIO)
                                {
                                    let x = UInt16(Float(value.location.x) / SCREEN_RATIO)
                                    let y = UInt16(Float(value.location.y) / SCREEN_RATIO)
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
                                    let x = UInt16(Float(value.location.x) / SCREEN_RATIO)
                                    let y = UInt16(Float(value.location.y) / SCREEN_RATIO)
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
            }
            .padding(.top, 40)
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
                    Image("Volume Button")
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
