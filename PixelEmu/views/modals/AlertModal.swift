//
//  AlertModal.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/18/24.
//

import SwiftUI

struct AlertModal: View {
    let alertTitle: String
    let text: String

    @Binding var showAlert: Bool
    @Binding var themeColor: Color

    var body: some View {
        VStack {
            Text(alertTitle)
                .foregroundColor(themeColor)
                .font(.custom("Departure Mono", size: 24))
            Text(text)
            Button("Close") {
                showAlert = false
            }
            .foregroundColor(themeColor)
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
