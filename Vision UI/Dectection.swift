//
//  File.swift
//  The Game
//
//  Created by T Krobot on 2/8/25.
//

import SwiftUI
import Vision
import AVFoundation

@MainActor
class HumanDetector: ObservableObject {
    @Published var xAxisBody: CGFloat?
    @Published var yAxisBody: CGFloat?
    @Published var xAxisFace: CGFloat?
    @Published var yAxisFace: CGFloat?
    
    func detect(in pixelBuffer: CVPixelBuffer) async {
        
        let bodyRequest = DetectHumanRectanglesRequest()
        let faceRequest = DetectFaceRectanglesRequest()
        
        do {
            
            async let bodyObservations = try await bodyRequest.perform(on: pixelBuffer)
            async let faceObservations = try await faceRequest.perform(on: pixelBuffer)
           
            let body = try await bodyObservations
            let face = try await faceObservations
            
            if !body.isEmpty{
                let allBodyX = body.map { $0.boundingBox.origin.x }
                let allBodyY = body.map { $0.boundingBox.origin.y }
                xAxisBody = allBodyX.reduce(0, +) / CGFloat(allBodyX.count)
                yAxisBody = allBodyY.reduce(0, +) / CGFloat(allBodyY.count)
            } else {
                xAxisBody = nil
                yAxisBody = nil
            }
            
            if !face.isEmpty{
                let allFaceX = body.map { $0.boundingBox.origin.x }
                let allFaceY = body.map { $0.boundingBox.origin.y }
                xAxisFace = allFaceX.reduce(0, +) / CGFloat(allFaceX.count)
                yAxisFace = allFaceY.reduce(0, +) / CGFloat(allFaceY.count)
            } else {
                xAxisFace = nil
                yAxisFace = nil
            }
        } catch {
            print("Detection failed:", error)
        }
    }
}
