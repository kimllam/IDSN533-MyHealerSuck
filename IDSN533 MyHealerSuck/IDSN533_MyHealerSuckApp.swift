//
//  IDSN533_MyHealerSuckApp.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI

@main
struct MyHealerSucksApp: App {
    @StateObject private var game = GameManager()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environmentObject(game)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject var game: GameManager
    
    let backgroundTan = Color(red: 252 / 255, green: 220 / 255, blue: 187 / 255)
    let darkBrown = Color(red: 0.35, green: 0.23, blue: 0.18)
    
    var body: some View {
        ZStack {
            backgroundTan.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("My Healer Sucks!")
                    .font(.system(size: 44, weight: .black, design: .serif))
                    .foregroundColor(darkBrown)
                
                Text("Defeat Bonk before two idiots die.")
                    .font(.headline)
                    .foregroundColor(darkBrown.opacity(0.8))
                
                NavigationLink(destination: GameBoardView()
                    .navigationBarBackButtonHidden(true)
                    .onAppear { game.resetGame() }
                ) {
                    Text("Start Game")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .frame(width: 200, height: 52)
                        .background(Color.green)
                        .cornerRadius(26)
                        .overlay(RoundedRectangle(cornerRadius: 26).stroke(darkBrown, lineWidth: 2))
                }
            }
        }
    }
}
