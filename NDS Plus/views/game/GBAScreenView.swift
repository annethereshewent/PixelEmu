//
//  GBAScreenView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 11/29/24.
//

import SwiftUI
import GBAEmulatorMobile

struct GBAScreenView: View {
    @Binding var gameController: GameController?
    @Binding var image: CGImage?
    @Binding var isHoldButtonsPresented: Bool
    @Binding var themeColor: Color
    @Binding var emulator: GBAEmulator?
    @Binding var heldButtons: Set<GBAButtonEvent>

    @EnvironmentObject var orientationInfo: OrientationInfo

    private var screenRatio: Float {
        if gameController?.controller?.extendedGamepad == nil {
            return GBA_SCREEN_RATIO
        }

        return GBA_FULLSCREEN_RATIO
    }

    private var currentHoldButtons: String {
        var buttons: [String] = []
        for button in heldButtons {
            switch button {
            case .ButtonA:
                buttons.append("A")
            case .ButtonB:
                buttons.append("B")
            case .ButtonL:
                buttons.append("L")
            case .ButtonR:
                buttons.append("R")
            case .Down:
                buttons.append("Down")
            case .Left:
                buttons.append("Left")
            case .Right:
                buttons.append("Right")
            case .Up:
                buttons.append("Up")
            case .Select:
                buttons.append("Select")
            case .Start:
                buttons.append("Start")
            }
        }

        return "Current: \(buttons.joined(separator: ","))"
    }

    var body: some View {
        if gameController?.controller?.extendedGamepad != nil {
            Spacer()
        }
        ZStack {
            GameScreenView(image: $image)
                .frame(
                    width: CGFloat(SCREEN_WIDTH) * CGFloat(screenRatio),
                    height: CGFloat(SCREEN_HEIGHT) * CGFloat(screenRatio)
                )
        }
        if gameController?.controller?.extendedGamepad != nil {
            Spacer()
        }
    }
}
