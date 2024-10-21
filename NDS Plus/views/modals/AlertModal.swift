//
//  AlertModal.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/18/24.
//

import SwiftUI

struct AlertModal: View {
    let alertTitle: String
    let text: String

    @Binding var showAlert: Bool
    
    var body: some View {
        VStack {
            Text(alertTitle)
                .foregroundColor(Colors.accentColor)
                .font(.custom("Departure Mono", size: 24))
            Text(text)
            Button("Close") {
                showAlert = false
            }
            .foregroundColor(Colors.accentColor)
            .border(.gray)
            .cornerRadius(0.3)
            .padding(.top, 20)
        }
        .background(Colors.backgroundColor)
        .frame(width: 400, height: 400)
        .padding()
        .opacity(0.8)
        .font(.custom("Departure Mono", size: 20))
    }
}
