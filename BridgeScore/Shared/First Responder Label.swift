//
//  First Responder Label.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/11/2023.
//

import UIKit

class FirstResponderLabel: UILabel {
    var parent: ScorecardInputCollectionCell?
    var view: UIView?
    
    init(from parent: ScorecardInputCollectionCell? = nil, view: UIView? = nil) {
        self.parent = parent
        self.view = view
        super.init(frame: CGRect())
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var canBecomeFirstResponder: Bool {
        true
    }
    
    @discardableResult override func becomeFirstResponder() -> Bool {
        parent?.getFocus(becomeFirstResponder: false)
        return super.becomeFirstResponder()
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        parent?.loseFocus(resignFirstResponder: false)
        return super.resignFirstResponder()
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        (parent ?? view)?.pressesBegan(presses, with: event)
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        (parent ?? view)?.pressesEnded(presses, with: event)
    }
}

