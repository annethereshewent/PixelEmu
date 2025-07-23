//
//  GBCStateEntriesView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 7/22/25.
//

import SwiftUI

struct GBCStateEntriesView: View {
    @Binding var emulator: (any EmulatorWrapper)?
    @Binding var gameName: String
    @Binding var isMenuPresented: Bool
    @Binding var game: (any Playable)?

    var body: some View {
        Text("Hello, World!")
    }
}
