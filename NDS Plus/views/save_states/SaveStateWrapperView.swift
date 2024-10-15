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
    
    init(game: Game) {
        let id = game.persistentModelID
        let predicate = #Predicate<SaveState> { saveState in
            return saveState.game.persistentModelID == id
        }
        
        _saveStates = Query(filter: predicate)
    }
    var body: some View {
        HStack {
            ForEach(saveStates.sorted(by: { $0.saveName < $1.saveName })) { saveState in
                SaveStateView(saveState: saveState)
            }
        }
    }
}
