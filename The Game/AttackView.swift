//
//  AttackView.swift
//  The Game
//
//  Created by Balasaravanan Dhanwin Basil  on 2/8/25.
//
import SwiftUI

struct AttackView: View {
    @State private var x: CGFloat = 100
    @State private var y: CGFloat = 100
    @State private var dragStartX: CGFloat = 0
    @State private var dragStartY: CGFloat = 0
    
    let speed: CGFloat = 20
    
    var body: some View {
        VStack {
            Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.yellow)
                        .position(x: x, y: y)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    x = dragStartX + value.translation.width
                                    y = dragStartY + value.translation.height
                                }
                                .onEnded { _ in
                                    dragStartX = x
                                    dragStartY = y
                                }
                        )
                        .onAppear {
                            dragStartX = x
                            dragStartY = y
                        }
                }
        
        VStack(spacing: 15) {
                        Button("Up") {
                            y = max(y - speed, 0)
                        }
                        HStack(spacing: 40) {
                            Button("Left") {
                                x = max(x - speed, 0)
                            }
                            Button("Right") {
                                x = min(x + speed, UIScreen.main.bounds.width)
                            }
                        }
                        Button("Down") {
                            y = min(y + speed, 300)
                        }
                    }
        }
}

#Preview {
    ContentView()
}
