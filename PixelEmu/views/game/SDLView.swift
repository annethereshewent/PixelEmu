//
//  SDLView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/1/25.
//

import SwiftUI
import UIKit

struct SDLView: UIViewControllerRepresentable {
    @Binding var romData: Data?

    func makeUIViewController(context: Context) -> SDLViewController {
        let vc = SDLViewController()
        vc.romData = romData
        return vc
    }

    func updateUIViewController(_ uiViewController: SDLViewController, context: Context) {
        uiViewController.romData = romData
    }
}

class SDLViewController: UIViewController {
    var romData: Data? = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let romData = romData else {
           print("No ROM data!")
           return
       }

        var data = Array(romData)

        let romSize = UInt32(data.count)

        data.withUnsafeMutableBufferPointer { ptr in
            initEmulator(ptr.baseAddress!, romSize)
        }

        DispatchQueue.global().async {
            while true {
                DispatchQueue.main.sync {
                    stepFrame()
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}
