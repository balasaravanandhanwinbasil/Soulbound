//
//  File.swift
//  The Game
//
//  Created by T Krobot on 2/8/25.
//

import Vision
import SwiftUI

let image = URL(string: "image.png")!

let request = DetectHumanRectanglesRequest()

let humanObservations = try await request.perform(on: image)
