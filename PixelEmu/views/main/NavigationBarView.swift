//
//  NavigationBarView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/17/24.
//

import SwiftUI

struct NavigationBarView: View {
    @Binding var currentView: CurrentView
    @Binding var themeColor: Color
    var body: some View {
        ZStack {
            Image("Button Accent")
            HStack {
                Spacer()
                if currentView == .library {
                    Image("Library")
                        .padding(.trailing, 15)
                        .foregroundColor(themeColor)
                } else {
                    Button {
                        currentView = .library
                    } label: {
                        Image("Library")
                            .padding(.trailing, 15)
                            .foregroundColor(Colors.primaryColor)
                    }
                    
                }
                if currentView == .importGames {
                    Image("Plus")
                        .padding(.trailing, 15)
                        .foregroundColor(themeColor)
                } else {
                    Button {
                        currentView = .importGames
                    } label: {
                        Image("Plus")
                            .padding(.trailing, 15)
                            .foregroundColor(Colors.primaryColor)
                    }
                }
                if currentView == .saveManagement {
                    Image("Save Slots")
                        .padding(.trailing, 15)
                        .foregroundColor(themeColor)
                } else {
                    Button {
                        currentView = .saveManagement
                    } label: {
                        Image("Save Slots")
                            .padding(.trailing, 15)
                            .foregroundColor(Colors.primaryColor)
                    }
                }
                if currentView == .settings {
                    Image("Gear")
                        .padding(.trailing, 15)
                        .foregroundColor(themeColor)
                } else {
                    Button {
                        currentView = .settings
                    } label: {
                        Image("Gear")
                            .padding(.trailing, 15)
                            .foregroundColor(Colors.primaryColor)
                    }
                }
                Spacer()
            }
        }
    }
}
