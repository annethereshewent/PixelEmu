//
//  DeleteDialog.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 10/19/24.
//

import SwiftUI

struct DeleteDialog: View {
    @Binding var showDialog: Bool
    @Binding var deleteAction: () -> Void
    @Binding var themeColor: Color

    let deleteMessage: String

    var body: some View {
        VStack {
            Text("Confirm delete")
                .foregroundColor(themeColor)
                .font(.custom("Departure Mono", size: 24))
            Text(deleteMessage)

            HStack {
                Button("Confirm") {
                    deleteAction()
                    showDialog = false
                }
                .foregroundColor(.red)
                .border(.gray)
                .cornerRadius(0.3)
                .padding(.top, 20)
                Button("Close") {
                    showDialog = false
                }
                .foregroundColor(themeColor)
                .border(.gray)
                .cornerRadius(0.3)
                .padding(.top, 20)
            }
        }
        .background(Colors.backgroundColor)
        .frame(width: 300, height: 300)
        .opacity(0.9)
        .font(.custom("Departure Mono", size: 20))
    }
}
