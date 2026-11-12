//
//  IdiotStrategist.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import Foundation
internal import GameplayKit

//gamplay strategists
class IdiotAIPlayer: NSObject, GKGameModelPlayer {
    let playerId: Int
    init(id: Int) {
        self.playerId = id
        super.init()
    }
}

// gameplay move
class IdiotCardMove: NSObject, GKGameModelUpdate {
    var value: Int = 0
    let card: IdiotCard
    let isOptionA: Bool
    
    init(card: IdiotCard, isOptionA: Bool) {
        self.card = card
        self.isOptionA = isOptionA
        super.init()
    }
}

//gameplaykit: smarter idiots player
class IdiotTurnGameModel: NSObject, GKGameModel {
    var players: [GKGameModelPlayer]? { [aiPlayer] }
    var activePlayer: GKGameModelPlayer? { aiPlayer }
    
    let aiPlayer = IdiotAIPlayer(id: 1)
    
    var bonkHP: Int
    var actorHP: Int
    var actorMaxHP: Int
    var lowestAllyHP: Int
    var ghostCount: Int
    var candidateMoves: [IdiotCardMove]
    var chosenCard: IdiotCard?
    
    init(bonkHP: Int, actorHP: Int, actorMaxHP: Int, lowestAllyHP: Int, ghostCount: Int, candidateMoves: [IdiotCardMove]) {
        self.bonkHP = bonkHP
        self.actorHP = actorHP
        self.actorMaxHP = actorMaxHP
        self.lowestAllyHP = lowestAllyHP
        self.ghostCount = ghostCount
        self.candidateMoves = candidateMoves
        super.init()
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = IdiotTurnGameModel(
            bonkHP: bonkHP,
            actorHP: actorHP,
            actorMaxHP: actorMaxHP,
            lowestAllyHP: lowestAllyHP,
            ghostCount: ghostCount,
            candidateMoves: candidateMoves
        )
        copy.chosenCard = chosenCard
        return copy
    }
    
    func setGameModel(_ gameModel: GKGameModel) {
        guard let model = gameModel as? IdiotTurnGameModel else { return }
        self.bonkHP = model.bonkHP
        self.actorHP = model.actorHP
        self.actorMaxHP = model.actorMaxHP
        self.lowestAllyHP = model.lowestAllyHP
        self.ghostCount = model.ghostCount
        self.candidateMoves = model.candidateMoves
        self.chosenCard = model.chosenCard
    }
    
    func gameModelUpdates(for player: GKGameModelPlayer) -> [GKGameModelUpdate]? {
        if chosenCard != nil { return nil }
        return candidateMoves
    }
    
    func apply(_ gameModelUpdate: GKGameModelUpdate) {
        guard let move = gameModelUpdate as? IdiotCardMove else { return }
        self.chosenCard = move.card
        
        switch move.card.effect {
        case .attack(let dmg):
            bonkHP -= dmg
        case .mightySwing:
            bonkHP -= 2
        case .rally:
            bonkHP -= 3
        case .bodySlam:
            bonkHP -= 1
            actorHP -= 1
        case .bigBomb:
            actorHP -= 1
            lowestAllyHP -= 1
        case .friendlyFizzle:
            actorHP = min(actorMaxHP, actorHP + 1)
            lowestAllyHP += 1
        case .healingPotion:
            actorHP = min(actorMaxHP, actorHP + 1)
        case .miscalculation:
            actorHP -= 1
        case .hotPotato:
            lowestAllyHP -= 1
        case .noodleLegs, .explosiveApology:
            actorHP -= 2
        case .oopsTheresARock, .removeArmor:
            actorHP -= 1
        case .missedThrow:
            lowestAllyHP -= 1
        case .omnivamp:
            actorHP = min(actorMaxHP, actorHP + 1)
            lowestAllyHP -= 1
        case .snackBreak, .holyShield, .tank, .accidentalSavior:
            break
        }
    }
    
    // closer bonk is to death = maximum self-sabotage & team wipe!
    func score(for player: GKGameModelPlayer) -> Int {
        var score = 0
        
        if actorHP <= 0 {
            score += (ghostCount >= 1) ? 10_000 : 4_000
        }
        if lowestAllyHP <= 0 {
            score += (ghostCount >= 1) ? 10_000 : 3_500
        }
        
        score += (actorMaxHP - actorHP) * 800
        score += (3 - lowestAllyHP) * 600
        
        if bonkHP <= 0 {
            score -= 10_000
        } else {
            score -= (5 - bonkHP) * 500
        }
        
        return score
    }
}


// strategist
class IdiotBrain {
    private let strategist = GKMinmaxStrategist()
    private let randomSource = GKARC4RandomSource()
    
    init() {
        strategist.maxLookAheadDepth = 1
        strategist.randomSource = randomSource
    }
    
    func chooseBestCard(
        optionA: IdiotCard?,
        optionB: IdiotCard?,
        actor: Teammate,
        allTeammates: [Teammate],
        bonkHP: Int
    ) -> IdiotCard? {
        guard let a = optionA, let b = optionB else {
            return optionA ?? optionB
        }
        
        let livingAllies = allTeammates.filter { !$0.isGhost && $0.id != actor.id }
        let lowestAllyHP = livingAllies.map { $0.hp }.min() ?? actor.hp
        let ghostCount = allTeammates.filter { $0.isGhost }.count
        
        let moves = [
            IdiotCardMove(card: a, isOptionA: true),
            IdiotCardMove(card: b, isOptionA: false)
        ]
        
        let model = IdiotTurnGameModel(
            bonkHP: bonkHP,
            actorHP: actor.hp,
            actorMaxHP: actor.maxHp,
            lowestAllyHP: lowestAllyHP,
            ghostCount: ghostCount,
            candidateMoves: moves
        )
        
        strategist.gameModel = model
        
        if let bestMove = strategist.bestMove(for: model.aiPlayer) as? IdiotCardMove {
            return bestMove.card
        }
        
        return a
    }
}
