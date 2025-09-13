//
//  OverlayView.swift
//  The Game
//
//  Created by Balasaravanan Dhanwin Basil  on 26/7/25.
//

import SwiftUI
import AVFoundation

struct OverlayView: View {
    @Binding var playerHealth: Int
    
    @Binding var bossHealth: Int
    @Binding var bossDefense: Int
    
    @StateObject private var detector = HumanDetector()
    @StateObject private var camera = CameraManager()
    
    var body: some View {
        VStack{
            HStack(){
                // MARK: PLAYER UI
                VStack(alignment: .leading, spacing: 10){
                        HealthView(health: playerHealth)
                }
                
                Spacer()
                
                // MARK: BOSS UI
                VStack(spacing:20){
                    Text("BOB, KNOWER OF ALL THINGS BRUTAL.")
                        .font(
                            .system(
                                size: 20,
                                weight: .bold,
                                design: .default
                            )
                        )
                        .bold()
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .red, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                    
                    BossHealthView(health: bossHealth)
                    DefenseBarView(bossDefense: bossDefense)
                }
            }
            
            Text("what you need to do to survive...")
        }
    }
}

// UI ELEMENTS

struct HealthView: View {
    var health: Int
    
    var body: some View {
        HStack(spacing: 20){
            let hp = health
            let empty = 5 - health
            
            ForEach(0..<hp, id: \.self) { heart in
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.red)
            }
            ForEach(0..<empty, id: \.self) { heart in
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
        }
    }
}


struct BossHealthView: View {
    var health: Int
    
    var body: some View {
        let fullhealth = 100
        
        var healthColor: LinearGradient {
            switch Double(health) / Double(fullhealth) {
            case 0.8...:
                return LinearGradient(
                    colors: [.green, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            case 0.4..<0.8:
                return LinearGradient(
                    colors: [.blue, .yellow, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            default:
                return LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .leading,
                    endPoint: .trailing)
            }
        }
        
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 4)
                .frame(width: 300, height: 20)
                .foregroundColor(.gray.opacity(0.3))
            
            RoundedRectangle(cornerRadius: 4)
                .frame(width: (Double(health) / Double(fullhealth)) * 300, height: 20)
                .foregroundStyle(healthColor)
        }
        .frame(width: 200)
    }
}


struct DefenseBarView: View {
    var bossDefense: Int
    
    var body: some View {
        VStack{
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: 300, height: 20)
                    .foregroundColor(.yellow)
                
                RoundedRectangle(cornerRadius: 4)
                    .frame(width: (Double(bossDefense) / Double(15)) * 300, height: 20)
                    .foregroundStyle(.red)
            }
            .frame(width: 200)
        }
    }
}
