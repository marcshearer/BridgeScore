//
//  Adaptive Keyboard.swift
//  BridgeScore
//
//  Created by Marc Shearer on 07/02/2022.
//

import Combine
import SwiftUI

extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
                                                                .map { $0.keyboardHeight }
                                                            
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
                                                                .map { _ in CGFloat(0) }
        
        return MergeMany(willShow, willHide).eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}

struct KeyboardAdaptive: ViewModifier {
    @State private var bottomPadding: CGFloat = 0
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        GeometryReader { (geometry) in
            content
            .onReceive(Publishers.keyboardHeight) { (keyboardHeight) in
                if keyboardHeight == 0 {
                    offset = 0
                } else {
                    #if widget
                    offset = 0
                    #else
                    let keyboardTop = geometry.frame(in: .global).height - keyboardHeight
                    let focusedTextInputBottom = (UIResponder.currentFirstResponder?.globalFrame?.maxY ?? 0) + offset
                    bottomPadding = max(0, focusedTextInputBottom - keyboardTop - geometry.safeAreaInsets.bottom)
                    offset = bottomPadding
                    #endif
                }
            }
            .offset(y: -offset)
        }
    }
}

extension View {
    var keyboardAdaptive: some View {
        self.modifier(KeyboardAdaptive())
    }
}

#if !widget
extension UIResponder {
    static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)
        return _currentFirstResponder
    }

    private static weak var _currentFirstResponder: UIResponder?

    @objc private func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }

    var globalFrame: CGRect? {
        guard let view = self as? UIView else { return nil }
        return view.superview?.convert(view.frame, to: nil)
    }
}
#endif
