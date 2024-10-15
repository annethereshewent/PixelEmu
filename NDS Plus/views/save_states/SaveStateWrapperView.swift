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
    
    private func generateView(in g: GeometryProxy ) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ScrollView {
            if let game = game {
                ZStack(alignment: .topLeading) {
                    ForEach(game.saveStates.sorted(by: { $0.saveName < $1.saveName })) { saveState in
                        SaveStateView(saveState: saveState)
                            .padding([.horizontal, .vertical], 4)
                            .alignmentGuide(.leading, computeValue: { d in
                                if (abs(width - d.width) > g.size.width)
                                {
                                    width = 0
                                    height -= d.height
                                }
                                let result = width
                                if saveState == self.saveStates.last! {
                                    width = 0 //last item
                                } else {
                                    width -= d.width
                                }
                                return result
                            })
                            .alignmentGuide(.top, computeValue: {d in
                                let result = height
                                if saveState == self.saveStates.last! {
                                    height = 0 // last item
                                }
                                return result
                            })
                    }
                }
            }
        }
    }
    
    var body: some View {
//        GeometryReader { geometry in
//            generateView(in: geometry)
//        }
        ScrollView {
            VStack {
                if let game = game {
                    ForEach(game.saveStates.sorted(by: { $0.saveName < $1.saveName })) { saveState in
                        SaveStateView(saveState: saveState)
                    }
                }
            }
        }
    }
}
