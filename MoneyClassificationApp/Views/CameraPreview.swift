//
//  CameraPreview.swift
//  MoneyClassificationApp
//
//  Menampilkan layer kamera (AVCaptureVideoPreviewLayer di device,
//  AVSampleBufferDisplayLayer di simulator) di SwiftUI.
//

import SwiftUI
import QuartzCore

struct CameraPreview: UIViewRepresentable {
    let previewLayer: CALayer?

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        if let previewLayer {
            view.setPreviewLayer(previewLayer)
        }
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        if let previewLayer, uiView.previewLayer !== previewLayer {
            uiView.setPreviewLayer(previewLayer)
        }
    }

    final class PreviewUIView: UIView {
        private(set) var previewLayer: CALayer?

        func setPreviewLayer(_ layer: CALayer) {
            previewLayer?.removeFromSuperlayer()
            previewLayer = layer
            layer.frame = bounds
            self.layer.addSublayer(layer)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            previewLayer?.frame = bounds
        }
    }
}
