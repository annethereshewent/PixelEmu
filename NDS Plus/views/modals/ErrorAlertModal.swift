//
//  ErrorAlertModal.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/18/24.
//

import SwiftUI

struct ErrorAlertModal: View {
    @Binding var showAlert: Bool
    let errorMessage: String
    var body: some View {
        VStack {
            Text("Oops!")
                .foregroundColor(Colors.accentColor)
                .font(.custom("Departure Mono", size: 24))
            Text(errorMessage)
            Button("Close") {
                showAlert = false
            }
            .foregroundColor(Colors.accentColor)
            .border(.gray)
            .cornerRadius(0.3)
            .padding(.top, 20)
        }
        .padding()
        .background(Colors.backgroundColor)
        .frame(width: 300, height: 300)
        .opacity(0.9)
        .font(.custom("Departure Mono", size: 20))
    }
}
