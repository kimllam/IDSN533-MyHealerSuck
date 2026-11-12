//
//  TeammateCardView.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI

struct TeammateCardView: View {
    @ObservedObject var teammate: Teammate
    @EnvironmentObject var game: GameManager
    
    let cardBackground = Color(red: 0.98, green: 0.85, blue: 0.68)
    let darkBrownText = Color(red: 0.35, green: 0.23, blue: 0.18)
    let mediumBrown = Color(red: 0.65, green: 0.5, blue: 0.4)
    
    var body: some View {
        VStack(spacing: 4) {
            // character id (head + HP)
            HStack(alignment: .top, spacing: 6) {
                Image(teammate.headImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(teammate.name)
                        .font(.system(size: 12, weight: .bold, design: .serif))
                        .foregroundColor(darkBrownText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    
                    HStack(spacing: 2) {
                        ForEach(0..<teammate.maxHp, id: \.self) { i in
                            Image(systemName: "heart.fill")
                                .foregroundColor(i < teammate.hp ? .red : .gray)
                                .font(.system(size: 11))
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            
            if teammate.isGhost {
                Spacer()
                Image("ghost")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 85)
                Text("GHOST\n(Out of play)")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundColor(mediumBrown)
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                Text("Possible moves")
                    .font(.system(size: 11, weight: .bold, design: .serif))
                    .foregroundColor(darkBrownText)
                
                // idiot's card slot
                HStack(spacing: 6) {
                    MoveOptionBoxView(card: teammate.optionA, textColor: darkBrownText, borderColor: mediumBrown)
                    MoveOptionBoxView(card: teammate.optionB, textColor: darkBrownText, borderColor: mediumBrown)
                }
                .frame(height: 75)
                
                // response dropbox
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.01))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                                .foregroundColor(mediumBrown)
                        )
                        .frame(height: 32)
                    
                    if let card = teammate.assignedCard {
                        Text(card.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(darkBrownText)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.cornerRadius(6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(darkBrownText, lineWidth: 1))
                            .draggable(card.rawValue)
                            .onTapGesture {
                                withAnimation {
                                    game.unassignCard(from: teammate)
                                }
                            }
                    } else {
                        Text("Drop response here")
                            .font(.system(size: 10, weight: .semibold, design: .serif))
                            .foregroundColor(mediumBrown)
                    }
                }
                .contentShape(Rectangle())
                .dropDestination(for: String.self) { items, _ in
                    guard let rawCard = items.first,
                          let healerCard = HealerCard(rawValue: rawCard) else { return false }
                    
                    withAnimation {
                        game.assignCard(card: healerCard, to: teammate)
                    }
                    return true
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(teammate.isGhost ? cardBackground.opacity(0.65) : cardBackground)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(darkBrownText, lineWidth: 2)
        )
    }
}

struct MoveOptionBoxView: View {
    let card: IdiotCard?
    let textColor: Color
    let borderColor: Color
    
    var body: some View {
        VStack(spacing: 2) {
            if let card = card {
                Text(card.title)
                    .font(.system(size: 10, weight: .bold, design: .serif))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                
                Spacer(minLength: 0)
                
                Text(card.description)
                    .font(.system(size: 8))
                    .foregroundColor(textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
            } else {
                Text("Empty")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    TeammateCardView(teammate: Teammate(character: .drBoomBoom, hp: 3))
        .environmentObject(GameManager())
        .frame(width: 220, height: 260)
}
