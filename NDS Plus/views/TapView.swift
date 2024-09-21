//
//  TapView.swift
//  NDS Plus
//
//  Created by Anne Castrillon on 9/20/24.
//

import Foundation
import SwiftUI

struct TapView: UIViewRepresentable {

    var tappedCallback: ([UITouch:CGPoint]) -> Void

    func makeUIView(context: UIViewRepresentableContext<TapView>) -> TapView.UIViewType {
        let v = UIView(frame: .zero)
        let gesture = NFingerGestureRecognizer(target: context.coordinator, tappedCallback: tappedCallback)
        v.addGestureRecognizer(gesture)
        return v
    }
    
    func updateUIView(_ uiView: UIView, context: UIViewRepresentableContext<TapView>) {
        // empty
    }
}
