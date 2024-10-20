//
//  ErrorAlertModal.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/18/24.
//

import SwiftUI

struct ErrorAlertModal: View {
    @Binding var showAlert: Bool
    var body: some View {
        VStack {
            Text("Error!")
                .foregroundColor(Colors.accentColor)
                .font(.custom("Departure Mono", size: 24))
            Text("There was an error performing the action.")
            Button("Close") {
                showAlert = false
            }
            .foregroundColor(Colors.accentColor)
            .border(.gray)
            .cornerRadius(0.3)
            .padding(.top, 20)
        }
        .background(Colors.backgroundColor)
        .frame(width: 300, height: 300)
        .opacity(0.9)
        .font(.custom("Departure Mono", size: 20))
    }
}
