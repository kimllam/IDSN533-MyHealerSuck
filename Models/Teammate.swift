//
//  Teammate.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import Foundation
internal import GameplayKit
import Combine

class Teammate: ObservableObject, Identifiable {
    let id = UUID()
    let character: IdiotCharacter
    var name: String { character.rawValue }
    @Published var hp: Int
    let maxHp: Int
    
    @Published var optionA: IdiotCard?
    @Published var optionB: IdiotCard?
    @Published var chosenMove: IdiotCard?
    @Published var assignedCard: HealerCard?
    
    // Resolution animation triggers
    @Published var isFlashingHit: Bool = false
    @Published var floatingFeedback: String? = nil
    @Published var feedbackIsHeal: Bool = false
    
    let deck: IdiotDeck
    var stateMachine: GKStateMachine?
    private let brain = IdiotBrain()
    
    var isGhost: Bool {
        hp <= 0 || stateMachine?.currentState is TeammateGhostState
    }
    
    var headImageName: String {
        if isGhost { return "ghost" }
        switch character {
        case .vampireAssassin: return "vampire head"
        case .knight: return "knight head"
        case .drBoomBoom: return "boom head"
        }
    }
    
    var fullBodyImageName: String {
        if isGhost { return "ghost" }
        switch character {
        case .vampireAssassin: return "vampire full"
        case .knight: return "knight full"
        case .drBoomBoom: return "boom full"
        }
    }
    
    init(character: IdiotCharacter, hp: Int) {
        self.character = character
        self.hp = hp
        self.maxHp = hp
        self.deck = IdiotDeck(character: character)
        
        drawOptions()
        setupStateMachine()
    }
    
    private func setupStateMachine() {
        let idleState = TeammateIdleState(teammate: self)
        let actingState = TeammateActingState(teammate: self)
        let ghostState = TeammateGhostState(teammate: self)
        
        self.stateMachine = GKStateMachine(states: [idleState, actingState, ghostState])
        self.stateMachine?.enter(TeammateIdleState.self)
    }
    
    func drawOptions() {
        guard !isGhost else {
            self.optionA = nil
            self.optionB = nil
            self.chosenMove = nil
            return
        }
        self.optionA = self.deck.drawCard()
        self.optionB = self.deck.drawCard()
        self.chosenMove = nil
    }
    
    func resolveSelectedMove(allTeammates: [Teammate], bonkHP: Int) -> IdiotCard? {
        guard !isGhost else { return nil }
        let selected = brain.chooseBestCard(
            optionA: optionA,
            optionB: optionB,
            actor: self,
            allTeammates: allTeammates,
            bonkHP: bonkHP
        )
        self.chosenMove = selected
        return selected
    }
    
    func prepareNextTurn() {
        self.assignedCard = nil
        self.isFlashingHit = false
        self.floatingFeedback = nil
        
        if hp > 0 {
            drawOptions()
            stateMachine?.enter(TeammateIdleState.self)
        } else {
            stateMachine?.enter(TeammateGhostState.self)
        }
    }
    
    func resetForNewGame() {
        self.hp = maxHp
        self.assignedCard = nil
        self.isFlashingHit = false
        self.floatingFeedback = nil
        stateMachine?.enter(TeammateIdleState.self)
        drawOptions()
    }
}
