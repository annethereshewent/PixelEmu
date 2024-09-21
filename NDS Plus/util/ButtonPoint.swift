//
//  ButtonPoints.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/21/24.
//

import Foundation


class ButtonPoint : Hashable, Equatable {
    static func == (lhs: ButtonPoint, rhs: ButtonPoint) -> Bool {
        lhs.top == rhs.top &&
        lhs.bottom == rhs.bottom &&
        lhs.left == rhs.left &&
        lhs.right == rhs.right
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(top)
        hasher.combine(bottom)
        hasher.combine(left)
        hasher.combine(right)
    }
    
    var top = 0.0
    var bottom = 0.0
    var left = 0.0
    var right = 0.0
    
    init(top: CGFloat, bottom: CGFloat, left: CGFloat, right: CGFloat) {
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}
