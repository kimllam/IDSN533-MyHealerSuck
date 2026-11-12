//
//  Untitled.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//
import Foundation

enum HealerCard: String, CaseIterable, Identifiable {
    case heal = "Heal (+1 HP)"
    case reverse = "Reverse (Re-direct Dmg)"
    case doNothing = "Do Nothing"
    
    var id: String { rawValue }
}
