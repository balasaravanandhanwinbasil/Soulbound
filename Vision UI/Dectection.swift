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
    @Published var xAxis: CGFloat?
    @Published var yAxis: CGFloat?

    func detect(in pixelBuffer: CVPixelBuffer) async {
        do {
            let observations = try await DetectHumanRectanglesRequest().perform(on: pixelBuffer)
            guard let first = observations.first else {
                xAxis = nil
                yAxis = nil
                return
            }

            let box = first.boundingBox
            xAxis = box.origin.x
            yAxis = box.origin.y
        } catch {
            print("Detection failed:", error)
        }
    }
}
