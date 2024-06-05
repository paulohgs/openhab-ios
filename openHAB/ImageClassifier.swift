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
import CoreML
import Foundation
import Vision

class ImageClassifier {
    var mlModel: MLModel = .init()
    var detector: VNCoreMLModel?

    lazy var visionRequest: VNCoreMLRequest? = {
        if let unwrapedDetector = detector {
            let request = VNCoreMLRequest(model: unwrapedDetector) { [weak self] request, error in
                self?.processObservation(for: request, error: error)
            }
            return request
        }
        return nil
    }()

    init() {
        guard let unwrapedModel = try? yolov8m(configuration: .init()).model else { return }
        mlModel = unwrapedModel
        guard let unwrapedDetector = try? VNCoreMLModel(for: unwrapedModel) else { return }
        detector = unwrapedDetector
        print("passou")
    }

    func predict(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let handle = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            guard let unwrapedRequest = visionRequest else { return }
            try handle.perform([unwrapedRequest])
        } catch {
            print(error)
        }
    }

    func processObservation(for request: VNRequest, error: Error?) {
        // TODO: Colocar a lógica para predizer de acordo com a amostragem e retornar o label para o botão a ser pesquisado
        DispatchQueue.main.async {
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.showLabels(predictions: results)
            } else {
                self.showLabels(predictions: [])
            }
        }
    }

    func showLabels(predictions: [VNRecognizedObjectObservation]) {
        print("number of predictions: \(predictions.count)")
        for prediction in predictions {
            guard let bestClass = prediction.labels.first?.identifier else { return }
            guard let confindence = prediction.labels.first?.confidence else { return }

            print("Best class: \(String(describing: bestClass))\nConfindence:\(String(describing: confindence))")
        }
    }
}
