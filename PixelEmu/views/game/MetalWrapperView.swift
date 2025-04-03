//
//  MetalWrapperView.swift
//  PixelEmu
//
//  Created by Anne Castrillon on 4/1/25.
//

import SwiftUI
import UIKit

struct MetalWrapperView: UIViewControllerRepresentable {
    @Binding var romData: Data?

    func makeUIViewController(context: Context) -> MetalWrapperViewController {
        let vc = MetalWrapperViewController()
        vc.romData = romData
        return vc
    }

    func updateUIViewController(_ uiViewController: MetalWrapperViewController, context: Context) {
        uiViewController.romData = romData
    }
}

class MetalWrapperViewController: UIViewController {
    var romData: Data? = nil
    var metalView: MetalView!

    override func loadView() {
        self.metalView = MetalView()
        self.view = metalView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let romData = romData else {
           print("No ROM data!")
           return
       }

        var data = Array(romData)

        let romSize = UInt32(data.count)

        let layer = self.view.layer as! CAMetalLayer

        data.withUnsafeMutableBufferPointer { ptr in
            let metalLayerPtr =  Unmanaged.passUnretained(layer).toOpaque()
            initEmulator(ptr.baseAddress!, romSize, metalLayerPtr)
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
