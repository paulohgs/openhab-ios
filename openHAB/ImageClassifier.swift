//
//  ImageClassifier.swift
//  openHAB
//
//  Created by Paulo Henrique on 05/06/24.
//  Copyright © 2024 openHAB e.V. All rights reserved.
//

import Foundation
import CoreML
import Vision
import AVFoundation

@available(iOS 14.0, *)
class ImageClassifier {
    
    let mlModel: MLModel
    lazy var detector: VNCoreMLModel = try! VNCoreMLModel(for:mlModel)
    
    lazy var visionRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: detector, completionHandler: { [weak self] request, error in
            self?.processObservation(for: request, error: error)
        })
        return request
    }()
    
    init() {
        mlModel = try! yolov8m(configuration: .init()).model
    }
    
    func predict(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        let handle = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handle.perform([visionRequest])
        } catch {
            print(error)
        }
    }
    
    func processObservation(for request: VNRequest, error: Error?) {
        //TODO: Colocar a lógica para predizer de acordo com a amostragem e retornar o label para o botão a ser pesquisado
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
        for i in 0...predictions.count {
            let prediction = predictions[i]
            let bestClass = prediction.labels.first?.identifier
            let confindence = prediction.labels.first?.confidence
            
            print("Best class: \(String(describing: bestClass))\nConfindence:\(String(describing: confindence))")
        }
    }
}
