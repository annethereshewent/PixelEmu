//
//  N64GameView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/1/25.
//

import SwiftUI

struct N64GameView: View {
    @Binding var romData: Data?
    var body: some View {
        HStack {
            SDLView(romData: $romData)
                .edgesIgnoringSafeArea(.all)
        }
            .navigationBarTitle("")
            .navigationBarHidden(true)
            .ignoresSafeArea(.all)
            .edgesIgnoringSafeArea(.all)
            .statusBarHidden()
    }

}
