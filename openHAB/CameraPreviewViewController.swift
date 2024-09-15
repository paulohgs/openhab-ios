// Copyright (c) 2010-2024 Contributors to the openHAB project
//
// See the NOTICE file(s) distributed with this work for additional
// information.
//
// This program and the accompanying materials are made available under the
// terms of the Eclipse Public License 2.0 which is available at
// http://www.eclipse.org/legal/epl-2.0
//
// SPDX-License-Identifier: EPL-2.0

import AVFoundation
import Foundation
import UIKit

final class CameraPreviewViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, ImageClassifierDelegate {
    var captureSession: AVCaptureSession!
    var imageClassifier: ImageClassifier = .init()
    var dataOutput: AVCaptureVideoDataOutput!
    var boundingBoxView: BoundingBoxView!

    override func viewDidLoad() {
        super.viewDidLoad()
        captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }

        dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoOutput"))
        captureSession.addOutput(dataOutput)

        imageClassifier.delegate = self

        boundingBoxView = BoundingBoxView()
        boundingBoxView.addToLayer(view.layer)

        print("view instanciada")
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        imageClassifier.predict(sampleBuffer: sampleBuffer)
    }

    func showBoxes(at coordinates: CGRect, with label: String) {
        DispatchQueue.main.async {
            let width = self.view.frame.width * coordinates.width
            let height = self.view.frame.height * coordinates.height
            let x = self.view.frame.width * coordinates.origin.x
            let y = self.view.frame.height * (1 - coordinates.origin.y - coordinates.height)

            let frame = CGRect(x: x, y: y, width: width, height: height)
            self.boundingBoxView.show(frame: frame, label: label, color: UIColor.red, alpha: 0.75)
        }
    }
}
