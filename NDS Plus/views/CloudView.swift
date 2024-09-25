//
//  CloudView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/24/24.
//

import SwiftUI
import GoogleSignIn
import GoogleSignInSwift
import SwiftData

struct CloudView: View {
    @Binding var user: GIDGoogleUser?
    @Binding var cloudService: CloudService?
    
    @State private var saveEntries: [SaveEntry] = []
    
    @Query var games: [Game]
    
    @Environment(\.colorScheme) var colorScheme

    
    private func handleSignInButton() {
        guard let rootViewController = (UIApplication.shared.connectedScenes.first
                  as? UIWindowScene)?.windows.first?.rootViewController
        else {
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            guard let result = signInResult else {
                print(error!)
                return
            }
            user = result.user
        }
    }
    
    var body: some View {
        VStack {
            Text("Cloud saves")
                .font(.title)
            if user == nil {
                HStack {
                    GoogleSignInButton(
                        scheme: .dark,
                        style: .icon,
                        action: handleSignInButton
                    )
                    Text("Sign in")
                }
            } else {
                Button("Sign Out of Google") {
                    GIDSignIn.sharedInstance.signOut()
                    user = nil
                }
            }
            List {
                Section("Cloud saves") {
                    ForEach(saveEntries, id: \.game.gameName) { saveEntry in
                        HStack {
                            GameEntryView(game: saveEntry.game) {
                                print("you clicked on me!")
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if let user = user {
                Task {
                    if let saveEntries = await cloudService?.getSaves(games: games) {
                        self.saveEntries = saveEntries
                    }
                }
            }
        }
    }
}
