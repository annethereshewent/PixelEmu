//
//  DeleteDialog.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 10/19/24.
//

import SwiftUI

struct DeleteDialog: View {
    @Binding var showDialog: Bool
    @Binding var deleteAction: () -> Void
    var body: some View {
        VStack {
            Text("Confirm delete")
                .foregroundColor(Colors.accentColor)
                .font(.custom("Departure Mono", size: 24))
            Text("Are you sure you want to delete this save?")
            
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
                .foregroundColor(Colors.accentColor)
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
