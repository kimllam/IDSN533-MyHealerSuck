//
//  TeammateCardDeck.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

import Foundation
internal import GameplayKit

// idiot names
enum IdiotCharacter: String, CaseIterable {
    case drBoomBoom = "Dr. Boom Boom"
    case knight = "Super Hungry Knight"
    case vampireAssassin = "Stumbling Vampire Assasin"
}

// idiot card definition
struct IdiotCard: Identifiable, Equatable {
    let id = UUID()
    let owner: IdiotCharacter
    let title: String
    let description: String
    let effect: CardEffect
    
    static func == (lhs: IdiotCard, rhs: IdiotCard) -> Bool {
        lhs.id == rhs.id
    }
}

// idiot card effect
enum CardEffect {
    // dr.boom boom card
    case bigBomb
    case friendlyFizzle
    case miscalculation
    case explosiveApology
    case hotPotato
    case healingPotion
    
    // super hungry kngiht card
    case removeArmor
    case holyShield
    case snackBreak
    case mightySwing
    case rally
    case bodySlam
    case tank
    
    // stumbling vampire assasin card
    case accidentalSavior
    case missedThrow
    case noodleLegs
    case omnivamp
    case oopsTheresARock
    
    // shared cards
    case attack(damage: Int)
    
}

// gameplaykit controlled idiots deck
class IdiotDeck {
    let character: IdiotCharacter
    private(set) var cards: [IdiotCard] = []
    private(set) var discardPile: [IdiotCard] = []
    
    private let randomSource = GKARC4RandomSource()
    
    init(character: IdiotCharacter) {
        self.character = character
        self.cards = IdiotDeck.buildDeck(for: character)
        shuffle()
    }
    
    func shuffle() {
        cards = randomSource.arrayByShufflingObjects(in: cards) as? [IdiotCard] ?? cards
    }
    
    func drawCard() -> IdiotCard? {
        if cards.isEmpty {
            if discardPile.isEmpty { return nil }
            cards = randomSource.arrayByShufflingObjects(in: discardPile) as? [IdiotCard] ?? discardPile
            discardPile.removeAll()
        }
        let drawn = cards.removeFirst()
        assert(drawn.owner == character, "Card \(drawn.title) does not belong to \(character.rawValue)!")
        discardPile.append(drawn)
        return drawn
    }
    
    func flipCoin() -> Bool {
        let coinDistribution = GKRandomDistribution(randomSource: randomSource, lowestValue: 0, highestValue: 1)
        return coinDistribution.nextInt() == 1
    }

    
    // character specific effects
    private static func buildDeck(for character: IdiotCharacter) -> [IdiotCard] {
        var deck: [IdiotCard] = []
        
        switch character {
        case .drBoomBoom:
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .drBoomBoom, title: "BIG Bomb", description: "Deal 1 damage to all allies (including self)", effect: .bigBomb), count: 2))
            deck.append(IdiotCard(owner: .drBoomBoom, title: "Friendly Fizzle", description: "Heal all allies (including self) for 1 HP", effect: .friendlyFizzle))
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .drBoomBoom, title: "Miscalculation", description: "Flip a coin. Heads: 1 damage to all allies. Tails: nothing.", effect: .miscalculation), count: 2))
            deck.append(IdiotCard(owner: .drBoomBoom, title: "Explosive Apology", description: "Take 2 damage; Healer heals ally of choice", effect: .explosiveApology))
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .drBoomBoom, title: "Attack", description: "Deal 1 damage to Bonk", effect: .attack(damage: 1)), count: 3))
            deck.append(IdiotCard(owner: .drBoomBoom, title: "Healing Potion", description: "Heal 1 HP", effect: .healingPotion))
            deck.append(IdiotCard(owner: .drBoomBoom, title: "Hot Potato", description: "Flip a coin. Heads: 1 damage to ally. Tails: 1 damage to Bonk.", effect: .hotPotato))
            
        case .knight:
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .knight, title: "Remove Armor", description: "Take double damage this turn", effect: .removeArmor), count: 2))
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .knight, title: "Holy Shield", description: "Protect Bonk: takes no damage this turn", effect: .holyShield), count: 2))
            deck.append(IdiotCard(owner: .knight, title: "Mighty Swing", description: "Deal 2 damage to Bonk", effect: .mightySwing))
            deck.append(IdiotCard(owner: .knight, title: "Rally", description: "Deal 3 damage to Bonk", effect: .rally))
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .knight, title: "Attack", description: "Deal 1 damage to Bonk", effect: .attack(damage: 1)), count: 2))
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .knight, title: "Snack Break!", description: "Do nothing", effect: .snackBreak), count: 2))
            deck.append(IdiotCard(owner: .knight, title: "Body Slam", description: "Deal 1 damage to Bonk and take 1 damage", effect: .bodySlam))
            deck.append(IdiotCard(owner: .knight, title: "Tank", description: "Take all damage intended for allies", effect: .tank))
            
        case .vampireAssassin:
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .vampireAssassin, title: "Accidental Savior", description: "Take all damage intended for Bonk", effect: .accidentalSavior), count: 2))
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .vampireAssassin, title: "Missed Throw", description: "Deal 1 damage to a chosen ally", effect: .missedThrow), count: 2))
            deck.append(IdiotCard(owner: .vampireAssassin, title: "Noodle Legs", description: "Take 2 damage", effect: .noodleLegs))
            deck.append(IdiotCard(owner: .vampireAssassin, title: "Omnivamp", description: "Deal 1 damage to chosen ally and heal 1 HP", effect: .omnivamp))
            deck.append(contentsOf: Array(repeating: IdiotCard(owner: .vampireAssassin, title: "Attack", description: "Deal 1 damage to Bonk", effect: .attack(damage: 1)), count: 3))
            deck.append(IdiotCard(owner: .vampireAssassin, title: "oops there's a rock", description: "Take 1 damage", effect: .oopsTheresARock))
            
        }
        
        return deck
    }
}
