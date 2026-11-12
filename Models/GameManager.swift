//
//  GameManager.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import SwiftUI
import Combine
internal import GameplayKit

class GameManager: ObservableObject {
    @Published var teammates: [Teammate] = [
        Teammate(character: .vampireAssassin, hp: 3),
        Teammate(character: .knight, hp: 3),
        Teammate(character: .drBoomBoom, hp: 3)
    ]
    @Published var bonkHP: Int = 5
    @Published var availableCards: [HealerCard] = [.heal, .reverse, .doNothing]
    @Published var encounterNumber: Int = 1
    
    // win & lose state
    @Published var isGameOver: Bool = false
    @Published var didPlayerWin: Bool = false
    
    // step by step resolution
    @Published var isResolving: Bool = false
    @Published var activeResolvingIndex: Int = 0
    @Published var cardsFlipped: Bool = false
    @Published var resolutionBannerText: String = ""
    @Published var coinFlipResultText: String? = nil
    
    // bonk effects attack & heal
    @Published var bonkIsFlashingHit: Bool = false
    @Published var bonkDamagePopup: String? = nil
    
// idiots state tracker
    var ghostCount: Int {
        teammates.filter { $0.isGhost }.count
    }
    
    var livingTeammates: [Teammate] {
        teammates.filter { !$0.isGhost }
    }
    
    var allLivingAssigned: Bool {
        !livingTeammates.isEmpty && livingTeammates.allSatisfy { $0.assignedCard != nil }
    }
    
    var hasMoreLivingTeammatesToResolve: Bool {
        let nextIndex = activeResolvingIndex + 1
        guard nextIndex < teammates.count else { return false }
        return teammates[nextIndex..<teammates.count].contains { !$0.isGhost }
    }

    // drag & drop healer actions
    func assignCard(card: HealerCard, to teammate: Teammate) {
        guard !teammate.isGhost else { return }
        if teammate.assignedCard == card { return }
        
        for existing in teammates where existing.assignedCard == card {
            existing.assignedCard = nil
        }
        if let handIndex = availableCards.firstIndex(of: card) {
            availableCards.remove(at: handIndex)
        }
        if let previousCard = teammate.assignedCard {
            availableCards.append(previousCard)
        }
        teammate.assignedCard = card
    }
    
    func unassignCard(from teammate: Teammate) {
        guard let card = teammate.assignedCard else { return }
        teammate.assignedCard = nil
        availableCards.append(card)
    }
    
    func returnToHand(card: HealerCard) {
        for teammate in teammates where teammate.assignedCard == card {
            teammate.assignedCard = nil
        }
        if !availableCards.contains(card) {
            availableCards.append(card)
        }
    }

    // start encounter + stepbystep play
    func resolveEncounter() {
        guard !isResolving && !isGameOver else { return }
        
        // step 1. All living teammates select their move via IdiotBrain
        for teammate in livingTeammates {
            _ = teammate.resolveSelectedMove(allTeammates: teammates, bonkHP: bonkHP)
        }
        
        // step 2. Find the first living teammate to resolve
        guard let firstLivingIndex = teammates.firstIndex(where: { !$0.isGhost }) else { return }
        
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isResolving = true
        }
        
        // step 3. Present and resolve that first idiot immediately
        presentAndResolveTeammate(at: firstLivingIndex)
    }
    
    @MainActor
    func advanceResolutionStep() {
        if isGameOver {
            withAnimation {
                isResolving = false
            }
            return
        }
        
        let nextStartIndex = activeResolvingIndex + 1
        if nextStartIndex < teammates.count,
           let nextLivingIndex = teammates[nextStartIndex..<teammates.count].firstIndex(where: { !$0.isGhost }) {
            presentAndResolveTeammate(at: nextLivingIndex)
        } else {
            finishEncounterRound()
        }
    }
    
    @MainActor
    private func presentAndResolveTeammate(at index: Int) {
        for mate in teammates {
            mate.floatingFeedback = nil
            mate.isFlashingHit = false
        }
        bonkDamagePopup = nil
        bonkIsFlashingHit = false
        
        activeResolvingIndex = index
        cardsFlipped = false
        coinFlipResultText = nil
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            cardsFlipped = true
            applyMoveEffect(for: teammates[index])
        }
        
        checkGameOverConditions()
    }
    
    @MainActor
    private func finishEncounterRound() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isResolving = false
            cardsFlipped = false
            coinFlipResultText = nil
            encounterNumber += 1
            
            for teammate in teammates {
                teammate.prepareNextTurn()
            }
            availableCards = [.heal, .reverse, .doNothing]
        }
    }

    // core effect + healer steps
    @MainActor
    private func applyMoveEffect(for actor: Teammate) {
        guard let move = actor.chosenMove else { return }
        let response = actor.assignedCard ?? .doNothing
        let isReversed = (response == .reverse)
        
        actor.stateMachine?.enter(TeammateActingState.self)
        
        // step 1. Apply Healer's Heal Card (+1 HP) if played
        if response == .heal {
            healTeammate(actor, amount: 1)
        }
        
        // step 2. Resolve Idiot's Card Effect (accounting for Reverse)
        switch move.effect {
        case .attack(let dmg):
            if isReversed {
                damageTeammate(actor, amount: dmg)
                resolutionBannerText = "Reverse sends \(dmg) damage to \(actor.name)!"
            } else {
                damageBonk(amount: dmg)
                resolutionBannerText = "\(actor.name) hits Bonk for \(dmg)!"
            }
            
        case .mightySwing:
            if isReversed {
                damageTeammate(actor, amount: 2)
                resolutionBannerText = "Reverse redirects Mighty Swing (2 dmg) to Knight!"
            } else {
                damageBonk(amount: 2)
                resolutionBannerText = "Knight lands Mighty Swing for 2 damage!"
            }
            
        case .rally:
            if isReversed {
                damageTeammate(actor, amount: 3)
                resolutionBannerText = "Reverse sends Rally (3 dmg) straight to Knight!"
            } else {
                damageBonk(amount: 3)
                resolutionBannerText = "Rally deals 3 massive damage to Bonk!"
            }
            
        case .bigBomb:
            if isReversed {
                damageBonk(amount: 1)
                resolutionBannerText = "Reverse redirects BIG Bomb to Bonk for 1 damage!"
            } else {
                for ally in livingTeammates { damageTeammate(ally, amount: 1) }
                resolutionBannerText = "BIG Bomb hits all living allies for 1 damage!"
            }
            
        case .friendlyFizzle:
            if isReversed {
                for ally in livingTeammates { damageTeammate(ally, amount: 1) }
                resolutionBannerText = "Reverse turns Friendly Fizzle into 1 damage to all allies!"
            } else {
                for ally in livingTeammates { healTeammate(ally, amount: 1) }
                resolutionBannerText = "Healing bombs! All living allies heal 1 HP!"
            }
            
        case .miscalculation:
            let isHeads = actor.deck.flipCoin()
            coinFlipResultText = isHeads ? "Coin: Heads!" : "Coin: Tails!"
            if isHeads {
                if isReversed {
                    damageBonk(amount: 1)
                    resolutionBannerText = "Heads + Reverse! Bonk takes 1 damage!"
                } else {
                    for ally in livingTeammates { damageTeammate(ally, amount: 1) }
                    resolutionBannerText = "Heads! Miscalculation hits all living allies for 1!"
                }
            } else {
                resolutionBannerText = "Tails! Nothing happens."
            }
            
        case .hotPotato:
            let isHeads = actor.deck.flipCoin()
            coinFlipResultText = isHeads ? "Coin: Heads!" : "Coin: Tails!"
            let targetAlly = livingTeammates.first(where: { $0.id != actor.id }) ?? actor
            if isHeads {
                if isReversed {
                    damageBonk(amount: 1)
                    resolutionBannerText = "Heads + Reverse! Hot Potato hits Bonk for 1!"
                } else {
                    damageTeammate(targetAlly, amount: 1)
                    resolutionBannerText = "Heads! Hot Potato explodes on \(targetAlly.name)!"
                }
            } else {
                if isReversed {
                    damageTeammate(targetAlly, amount: 1)
                    resolutionBannerText = "Tails + Reverse! Hot Potato bounces to \(targetAlly.name)!"
                } else {
                    damageBonk(amount: 1)
                    resolutionBannerText = "Tails! Hot Potato hits Bonk for 1!"
                }
            }
            
        case .noodleLegs, .explosiveApology:
            if isReversed {
                damageBonk(amount: 2)
                resolutionBannerText = "Reverse sends 2 self-damage straight to Bonk!"
            } else {
                damageTeammate(actor, amount: 2)
                resolutionBannerText = "\(actor.name) takes 2 self-damage!"
            }
            
        case .oopsTheresARock:
            if isReversed {
                damageBonk(amount: 1)
                resolutionBannerText = "Reverse flings the rock at Bonk for 1 damage!"
            } else {
                damageTeammate(actor, amount: 1)
                resolutionBannerText = "\(actor.name) trips on a rock and takes 1 damage!"
            }
            
        case .bodySlam:
            if isReversed {
                damageTeammate(actor, amount: 1)
                damageBonk(amount: 1)
                resolutionBannerText = "Reverse swaps Body Slam targets!"
            } else {
                damageBonk(amount: 1)
                damageTeammate(actor, amount: 1)
                resolutionBannerText = "Body Slam! 1 damage to Bonk and 1 to Knight!"
            }
            
        case .missedThrow:
            let targetAlly = livingTeammates.first(where: { $0.id != actor.id }) ?? actor
            if isReversed {
                damageBonk(amount: 1)
                resolutionBannerText = "Reverse redirects Missed Throw to Bonk!"
            } else {
                damageTeammate(targetAlly, amount: 1)
                resolutionBannerText = "Missed Throw hits \(targetAlly.name) for 1 damage!"
            }
            
        case .omnivamp:
            let targetAlly = livingTeammates.first(where: { $0.id != actor.id }) ?? actor
            if isReversed {
                damageBonk(amount: 1)
                healTeammate(actor, amount: 1)
                resolutionBannerText = "Reverse redirects Omnivamp bite to Bonk!"
            } else {
                damageTeammate(targetAlly, amount: 1)
                healTeammate(actor, amount: 1)
                resolutionBannerText = "Omnivamp bites \(targetAlly.name) for 1 and heals Vampire!"
            }
            
        case .healingPotion:
            if isReversed {
                damageTeammate(actor, amount: 1)
                resolutionBannerText = "Reverse turns Healing Potion into 1 damage!"
            } else {
                healTeammate(actor, amount: 1)
                resolutionBannerText = "\(actor.name) drinks Healing Potion (+1 HP)!"
            }
            
        case .snackBreak, .removeArmor, .holyShield, .tank, .accidentalSavior:
            resolutionBannerText = response == .heal
                ? "Healer heals \(actor.name) for +1 HP!"
                : "\(actor.name) uses \(move.title)."
        }
    }
    
    // MARK: - Hit Flash, Healing & Win/Loss Checks
    @MainActor
    private func damageTeammate(_ teammate: Teammate, amount: Int) {
        guard !teammate.isGhost else { return }
        teammate.hp = max(0, teammate.hp - amount)
        teammate.feedbackIsHeal = false
        teammate.floatingFeedback = "-\(amount)"
        
        withAnimation(.easeInOut(duration: 0.12).repeatCount(4, autoreverses: true)) {
            teammate.isFlashingHit = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            teammate.isFlashingHit = false
        }
        
        if teammate.hp == 0 {
            teammate.stateMachine?.enter(TeammateGhostState.self)
        }
    }
    
    @MainActor
    private func healTeammate(_ teammate: Teammate, amount: Int) {
        guard !teammate.isGhost else { return }
        teammate.hp = min(teammate.maxHp, teammate.hp + amount)
        teammate.feedbackIsHeal = true
        teammate.floatingFeedback = "+\(amount) ♥"
    }
    
    @MainActor
    private func damageBonk(amount: Int) {
        bonkHP = max(0, bonkHP - amount)
        bonkDamagePopup = "-\(amount)"
        
        withAnimation(.easeInOut(duration: 0.12).repeatCount(4, autoreverses: true)) {
            bonkIsFlashingHit = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.bonkIsFlashingHit = false
            self.bonkDamagePopup = nil
        }
    }
    
    @MainActor
    @discardableResult
    private func checkGameOverConditions() -> Bool {
        if bonkHP <= 0 {
            didPlayerWin = true
            isGameOver = true
            resolutionBannerText = "BONK IS DEFEATED!"
            return true
        }
        if ghostCount >= 2 {
            didPlayerWin = false
            isGameOver = true
            resolutionBannerText = "2 Idiots became Ghosts!"
            return true
        }
        return false
    }
    
    func resetGame() {
        withAnimation {
            bonkHP = 5
            encounterNumber = 1
            isGameOver = false
            didPlayerWin = false
            isResolving = false
            cardsFlipped = false
            coinFlipResultText = nil
            bonkIsFlashingHit = false
            bonkDamagePopup = nil
            
            for teammate in teammates {
                teammate.resetForNewGame()
            }
            availableCards = [.heal, .reverse, .doNothing]
        }
    }
}
