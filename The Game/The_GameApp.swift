//
//  The_GameApp.swift
//  The Game
//
//  Created by Balasaravanan Dhanwin Basil  on 19/7/25.
//

import SwiftUI
import UIKit

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup {
            HostingControllerWrapper()
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct HostingControllerWrapper: UIViewControllerRepresentable {
    typealias UIViewControllerType = LandscapeHostingController<ContentView>

    func makeUIViewController(context: Context) -> LandscapeHostingController<ContentView> {
        return LandscapeHostingController(rootView: ContentView())
    }

    func updateUIViewController(_ uiViewController: LandscapeHostingController<ContentView>, context: Context) {}
}
