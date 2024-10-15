//
//  SaveStateWrapperView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/14/24.
//

import SwiftUI
import SwiftData

struct SaveStateWrapperView: View {
    @Query private var saveStates: [SaveState]
    @Binding var game: Game?
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ScrollView {
            if let game = game {
                LazyVGrid(columns: columns) {
                    ForEach(game.saveStates.sorted { $0.saveName < $1.saveName }) { saveState in
                        SaveStateView(saveState: saveState)
                    }
                }
            }
        }
    }
}
