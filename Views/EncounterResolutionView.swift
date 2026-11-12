//
//  EncounterResolutionView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//
import SwiftUI

struct EncounterResolutionView: View {
    @EnvironmentObject var game: GameManager
    
    let darkBrown = Color(red: 0.35, green: 0.23, blue: 0.18)
    let cardTan = Color(red: 0.98, green: 0.88, blue: 0.74)
    
    var activeTeammate: Teammate {
        let safeIndex = min(game.activeResolvingIndex, game.teammates.count - 1)
        return game.teammates[safeIndex]
    }
    
    private var nextButtonTitle: String {
        if game.isGameOver {
            return "See Results"
        } else if game.hasMoreLivingTeammatesToResolve {
            return "Next"
        } else {
            return "Next Encounter"
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // idiots resolution bar
            HStack(spacing: 10) {
                ForEach(Array(game.teammates.enumerated()), id: \.element.id) { index, mate in
                    CompactIdiotStatusPill(
                        teammate: mate,
                        isActive: index == game.activeResolvingIndex
                    )
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Text("BONK")
                        .font(.system(size: 16, weight: .black, design: .serif))
                        .foregroundColor(darkBrown)
                    Text("\(max(0, game.bonkHP)) / 5 HP")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.cornerRadius(8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(cardTan.cornerRadius(12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(darkBrown, lineWidth: 1.5))
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            // idiot vs bonk
            HStack(spacing: 14) {
                // LEFT: idiot
                ZStack {
                    Image(activeTeammate.fullBodyImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 190)
                        .colorMultiply(activeTeammate.isFlashingHit ? .red : .white)
                        .offset(x: activeTeammate.isFlashingHit ? -6 : 0)
                        .shadow(
                            color: (activeTeammate.floatingFeedback != nil && activeTeammate.feedbackIsHeal)
                                ? Color.green.opacity(0.75) : .clear,
                            radius: 14
                        )
                    
                    if let feedback = activeTeammate.floatingFeedback {
                        HStack(spacing: 4) {
                            if activeTeammate.feedbackIsHeal {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.green)
                            }
                            Text(feedback)
                                .font(.title2.bold())
                                .foregroundColor(activeTeammate.feedbackIsHeal ? .green : .red)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.9).cornerRadius(10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(darkBrown, lineWidth: 1.5))
                        .offset(y: -75)
                        .transition(.opacity.combined(with: .scale))
                    }
                    
                    if let coinText = game.coinFlipResultText {
                        Text(coinText)
                            .font(.caption.bold())
                            .foregroundColor(darkBrown)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow.opacity(0.85).cornerRadius(8))
                            .offset(y: 80)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // CENTER: reveal card
                HStack(spacing: 12) {
                    FlippableRevealCard(
                        header: "Their move",
                        title: activeTeammate.chosenMove?.title ?? "???",
                        subtitle: activeTeammate.chosenMove?.description ?? "",
                        accentColor: Color.orange.opacity(0.25),
                        isFlipped: game.cardsFlipped
                    )
                    
                    FlippableRevealCard(
                        header: "Your response",
                        title: activeTeammate.assignedCard?.rawValue ?? "Do Nothing",
                        subtitle: responseDescription(for: activeTeammate.assignedCard),
                        accentColor: Color.purple.opacity(0.2),
                        isFlipped: game.cardsFlipped
                    )
                }
                
                // RIGHT: BONK
                ZStack {
                    Image("bonk")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 190)
                        .colorMultiply(game.bonkIsFlashingHit ? .red : .white)
                        .offset(x: game.bonkIsFlashingHit ? 6 : 0)
                    
                    if let dmg = game.bonkDamagePopup {
                        Text(dmg)
                            .font(.title)
                            .foregroundColor(.red)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white.cornerRadius(12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(darkBrown, lineWidth: 2))
                            .offset(x: 35, y: -65)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            
            // resolution text and next button
            HStack(spacing: 12) {
                Text(game.resolutionBannerText)
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(darkBrown)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(cardTan.cornerRadius(10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(darkBrown, lineWidth: 1.5))
                
                Spacer()
                
                Button(action: {
                    game.advanceResolutionStep()
                }) {
                    HStack(spacing: 6) {
                        Text(nextButtonTitle)
                            .font(.headline.bold())
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(darkBrown, lineWidth: 1.5))
                    .shadow(radius: 2)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
    }
    
    private func responseDescription(for card: HealerCard?) -> String {
        switch card {
        case .heal: return "Heal designated ally for 1 HP"
        case .reverse: return "Redirect their move"
        case .doNothing, .none: return "Save energy"
        }
    }
}

struct CompactIdiotStatusPill: View {
    @ObservedObject var teammate: Teammate
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(teammate.headImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(teammate.name)
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .lineLimit(1)
                
                HStack(spacing: 2) {
                    ForEach(0..<teammate.maxHp, id: \.self) { i in
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundColor(i < teammate.hp ? .red : .gray.opacity(0.4))
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? Color.white : Color.white.opacity(0.55))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isActive ? Color.purple : Color.brown.opacity(0.5), lineWidth: isActive ? 2 : 1)
        )
        .scaleEffect(isActive ? 1.05 : 0.95)
    }
}

struct FlippableRevealCard: View {
    let header: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let isFlipped: Bool
    
    let darkBrown = Color(red: 0.35, green: 0.23, blue: 0.18)
    
    var body: some View {
        VStack(spacing: 4) {
            Text(header)
                .font(.system(size: 12, weight: .bold, design: .serif))
                .foregroundColor(darkBrown)
            
            ZStack {
                if isFlipped {
                    VStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 14, weight: .black, design: .serif))
                            .foregroundColor(darkBrown)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)
                        
                        Divider()
                        
                        Text(subtitle)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(darkBrown)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(10)
                    .frame(width: 125, height: 155)
                    .background(Color.white)
                    .overlay(RoundedRectangle(cornerRadius: 12).fill(accentColor))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(darkBrown, lineWidth: 2))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.55, green: 0.42, blue: 0.35))
                        .frame(width: 125, height: 155)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.6), lineWidth: 2)
                                .padding(6)
                        )
                        .overlay(
                            Image(systemName: "questionmark.diamond.fill")
                                .font(.title)
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
            }
            .rotation3DEffect(
                .degrees(isFlipped ? 0 : 180),
                axis: (x: 0, y: 1, z: 0)
            )
        }
    }
}
