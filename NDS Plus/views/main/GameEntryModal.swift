//
//  GameEntryModal.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/18/24.
//

import SwiftUI

struct GameEntryModal: View {
    @Binding var entry: SaveEntry?
    var body: some View {
        ScrollView {
            VStack {
                if let entry = entry {
                    Text("Modify save for \(entry.game.gameName)")
                }
                Button {
                    
                } label: {
                    HStack {
                        Image(systemName: "something")
                    }
                }
            }
        }
        .background(Color(
            red: 0x38 / 0xff,
            green: 0x38 / 0xff,
            blue: 0x38 / 0xff
        ))
        .font(.custom("Departure Mono", size: 16))
        .border(.gray)
        .opacity(0.70)
        .frame(width: 300, height: 500)
    }
}
