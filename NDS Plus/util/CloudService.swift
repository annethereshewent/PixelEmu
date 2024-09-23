//
//  CloudService.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/22/24.
//

import Foundation
import GoogleSignIn

class CloudService {
    private let user: GIDGoogleUser
    
    init(user: GIDGoogleUser) {
        self.user = user
    }
}
