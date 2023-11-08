//
//  First Responder Label.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/11/2023.
//

import UIKit

class FirstResponderLabel: UILabel, ScorecardResponder {
    var responderDelegate: ScorecardResponderDelegate?
    var view: UIView?
    
    public var updateFocus: Bool = false
    
    init(from responderDelegate: ScorecardResponderDelegate? = nil, view: UIView? = nil) {
        self.responderDelegate = responderDelegate
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
        if updateFocus {
            responderDelegate?.getFocus()
        }
        return super.becomeFirstResponder()
    }
    
    @discardableResult override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if updateFocus {
            responderDelegate?.resignedFirstResponder(from: self)
        }
        return result
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let responderDelegate = responderDelegate {
            responderDelegate.pressesBegan(presses, with: event)
        } else {
            view?.pressesBegan(presses, with: event)
        }
    }
    
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if let responderDelegate = responderDelegate {
            responderDelegate.pressesEnded(presses, with: event)
        } else {
            view?.pressesEnded(presses, with: event)
        }
    }
}

