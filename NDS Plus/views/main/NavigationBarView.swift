//
//  NavigationBarView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI

struct NavigationBarView: View {
    @Binding var currentView: CurrentView
    var body: some View {
        ZStack {
            Image("Button Accent")
            HStack {
                Spacer()
                if currentView == .library {
                    Image("Library Selected")
                        .padding(.trailing, 15)
                } else {
                    Button {
                        currentView = .library
                    } label: {
                        Image("Library")
                            .padding(.trailing, 15)
                    }
                    
                }
                if currentView == .importGames {
                    Image("+ Selected")
                        .padding(.trailing, 15)
                } else {
                    Button {
                        currentView = .importGames
                    } label: {
                        Image("+")
                            .padding(.trailing, 15)
                    }
                }
                if currentView == .saveManagement {
                    Image("Save Slots Selected")
                        .padding(.trailing, 15)
                } else {
                    Button {
                        currentView = .saveManagement
                    } label: {
                        Image("Save Slots")
                            .padding(.trailing, 15)
                    }
                }
                if currentView == .settings {
                    Image("Gear Selected")
                        .padding(.trailing, 15)
                } else {
                    Button {
                        currentView = .settings
                    } label: {
                        Image("Gear")
                            .padding(.trailing, 15)
                    }
                }
                Spacer()
            }
        }
    }
}
