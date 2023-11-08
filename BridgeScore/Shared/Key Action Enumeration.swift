//
//  Key Action Enumeration.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/11/2023.
//

import UIKit

enum KeyAction {
    case previous
    case next
    case up
    case down
    case left
    case right
    case characters
    case enter
    case escape
    case backspace
    case delete
    case save
    case other
    
    init(keyCode: UIKeyboardHIDUsage, modifierFlags: UIKeyModifierFlags) {
        let shift = modifierFlags.contains(.shift)
        let other = modifierFlags.contains(.control) || modifierFlags.contains(.alternate) || modifierFlags.contains(.command)
        if other {
            self = .other
        } else if shift {
            if keyCode == .keyboardTab {
                self = .previous
            } else  {
                self = .other
            }
        } else {
            if keyCode == .keyboardTab {
                self = .next
            } else if keyCode == .keyboardUpArrow  {
                self = .up
            } else if keyCode == .keyboardDownArrow {
                self = .down
            } else if keyCode == .keyboardLeftArrow  {
                self = .left
            } else if keyCode == .keyboardRightArrow {
                self = .right
            } else if keyCode == .keyboardEscape {
                self = .escape
            } else if keyCode == .keyboardReturn || keyCode == .keyboardReturnOrEnter {
                self = .enter
            } else if keyCode == .keyboardDeleteOrBackspace {
                self = .backspace
            } else if keyCode == .keyboardDeleteForward {
                self = .delete
            } else {
                self = .other
            }
        }
    }
    
    var leftRightKey: Bool {
        self == .left || self == .right
    }
    
    var upDownKey: Bool {
        self == .up || self == .down
    }
    
    var arrowKey: Bool {
        leftRightKey || upDownKey
    }
    
    var navigationKey: Bool {
        self == .previous || self == .next
    }
    
    var movementKey: Bool {
        navigationKey || upDownKey || self == .backspace
    }
    
    var deletionKey: Bool {
        self == .backspace || self == .delete
    }
}
