//
//  GameBoardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI

struct GameBoardView: View {
    @EnvironmentObject var game: GameManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            // Background Color
            Color(red: 252 / 255, green: 220 / 255, blue: 187 / 255)
                .ignoresSafeArea()
            
            if game.isResolving {
                EncounterResolutionView()
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.96)),
                        removal: .opacity
                    ))
            } else {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        
                        // LEFT COLUMN: encounter label + Idiots row + healer cards
                        VStack(spacing: 0) {
                            Text("ENCOUNTER \(game.encounterNumber)")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.gray)
                                .padding(.top, 10)
                            
                            Spacer(minLength: 5)
                            
                            // idiots row
                            VStack {
                                HStack(alignment: .top, spacing: 8) {
                                    ForEach(game.teammates) { teammate in
                                        TeammateCardView(teammate: teammate)
                                    }
                                }
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 245/255, green: 215/255, blue: 180/255))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.brown, lineWidth: 2)
                                    )
                            )
                            .padding(.horizontal, 10)
                            
                            Spacer(minLength: 5)
                            
                            Divider().background(Color.brown).padding(.horizontal)
                            
                            // healer 'your cards' hand row
                            HStack(spacing: 8) {
                                VStack {
                                    Image("healer your card")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 70)
                                }
                                
                                HStack(spacing: 8) {
                                    ForEach(game.availableCards, id: \.self) { card in
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white)
                                            .frame(width: 70, height: 90)
                                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.brown, lineWidth: 2))
                                            .overlay(
                                                Text(card.rawValue)
                                                    .font(.caption)
                                                    .minimumScaleFactor(0.5)
                                                    .multilineTextAlignment(.center)
                                                    .padding(4)
                                            )
                                            .draggable(card.rawValue)
                                    }
                                }
                                .frame(minWidth: 230, minHeight: 95)
                                
                                Text("Drag one card\nonto each idiot's\nresponse slot")
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.brown)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color(red: 235/255, green: 205/255, blue: 165/255))
                            .contentShape(Rectangle())
                            .dropDestination(for: String.self) { items, _ in
                                guard let rawCard = items.first,
                                      let healerCard = HealerCard(rawValue: rawCard) else { return false }
                                
                                withAnimation {
                                    game.returnToHand(card: healerCard)
                                }
                                return true
                            }
                        }
                        .frame(width: geometry.size.width * 0.65)
                        
                        // RIGHT COLUMN: BONK section
                        VStack(spacing: 20) {
                            VStack(spacing: 5) {
                                Text("BONK")
                                    .font(.system(size: 36, weight: .black, design: .serif))
                                    .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                                
                                Text("\(max(0, game.bonkHP)) / 5 HP")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 5)
                                    .background(Color.red.cornerRadius(10))
                            }
                            .padding(.top, 30)
                            
                            Image("bonk")
                                .resizable()
                                .scaledToFit()
                                .padding()
                            
                            Spacer()
                            
                            VStack(spacing: 10) {
                                let assignedCount = game.livingTeammates.compactMap { $0.assignedCard }.count
                                let totalLiving = game.livingTeammates.count
                                
                                Text("\(assignedCount) of \(totalLiving) assigned")
                                    .font(.headline)
                                    .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.1))
                                
                                Button(action: {
                                    withAnimation { game.resolveEncounter() }
                                }) {
                                    Text("Begin Encounter")
                                        .font(.headline).bold()
                                        .foregroundColor(.white)
                                        .frame(width: 200, height: 45)
                                        .background(game.allLivingAssigned && !game.isGameOver ? Color.green : Color.gray)
                                        .cornerRadius(25)
                                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.gray.opacity(0.5), lineWidth: 3))
                                }
                                .disabled(!game.allLivingAssigned || game.isGameOver)
                            }
                            .padding(.bottom, 20)
                        }
                        .frame(width: geometry.size.width * 0.35)
                        .background(Color.white.opacity(0.3))
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .scale(scale: 0.85, anchor: .top).combined(with: .opacity)
                ))
            }
            
            // GAME OVER OVERLAY (You Win / You Lost)
            if game.isGameOver {
                GameOverOverlayView(
                    didWin: game.didPlayerWin,
                    onPlayAgain: {
                        game.resetGame()
                    },
                    onReturnHome: {
                        game.resetGame()
                        dismiss()
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .zIndex(10)
            }
        }
    }
}

struct GameOverOverlayView: View {
    let didWin: Bool
    let onPlayAgain: () -> Void
    let onReturnHome: () -> Void
    
    let darkBrown = Color(red: 0.35, green: 0.23, blue: 0.18)
    let cardTan = Color(red: 0.98, green: 0.88, blue: 0.74)
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 18) {
                Text(didWin ? "YOU WIN!" : "YOU LOST!")
                    .font(.system(size: 38, weight: .black, design: .serif))
                    .foregroundColor(didWin ? .green : .red)
                
                Text(didWin ? "Bonk has been defeated!" : "Two idiots became ghosts!")
                    .font(.headline)
                    .foregroundColor(darkBrown)
                
                HStack(spacing: 16) {
                    Button(action: onPlayAgain) {
                        Text("Play Again")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(width: 140, height: 44)
                            .background(Color.green)
                            .cornerRadius(22)
                    }
                    
                    Button(action: onReturnHome) {
                        Text("Return Home")
                            .font(.headline.bold())
                            .foregroundColor(darkBrown)
                            .frame(width: 140, height: 44)
                            .background(Color.white)
                            .cornerRadius(22)
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(darkBrown, lineWidth: 2))
                    }
                }
                .padding(.top, 6)
            }
            .padding(28)
            .background(cardTan)
            .cornerRadius(20)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(darkBrown, lineWidth: 3))
            .shadow(radius: 15)
        }
    }
}

#Preview {
    GameBoardView()
        .environmentObject(GameManager())
}
