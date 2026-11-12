//
//  TeammateStates.swift
//  IDSN533 MyHealerSuck
//
//  Created by Kim Lam on 11/11/26.
//

internal import GameplayKit

class TeammateBaseState: GKState {
    unowned let teammate: Teammate
    
    init(teammate: Teammate) {
        self.teammate = teammate
        super.init()
    }
}

class TeammateIdleState: TeammateBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == TeammateActingState.self || stateClass == TeammateGhostState.self
    }
}

class TeammateActingState: TeammateBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == TeammateIdleState.self || stateClass == TeammateGhostState.self
    }
}

class TeammateGhostState: TeammateBaseState {
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return stateClass == TeammateIdleState.self
    }
    
    override func didEnter(from previousState: GKState?) {
        teammate.hp = 0
        teammate.assignedCard = nil
        teammate.optionA = nil
        teammate.optionB = nil
        teammate.chosenMove = nil
    }
}
