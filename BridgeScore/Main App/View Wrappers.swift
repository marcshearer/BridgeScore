//
//  View Wrappers.swift
//  BridgeScore
//
//  Created by Marc Shearer on 04/02/2025.
//

import SwiftUI

struct LeadingAttributedText: View {
    @State var text: AttributedString
    
    init(_ text: AttributedString) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer().frame(width: 2)
            Text(text)
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct LeadingText: View {
    @State var text: String
    
    init(_ text: String) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer().frame(width: 2)
            Text(text)
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct CenteredAttributedText: View {
    @State var text: AttributedString
    
    init(_ text: AttributedString) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct CenteredText: View {
    @State var text: String
    
    init(_ text: String) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct BindCenteredText: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct TrailingText: View {
    @State var text: String
    
    init(_ text: String) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer().frame(width: 2)
        }
        .contentShape(Rectangle())
    }
}

struct TrailingAttributedText: View {
    @State var text: AttributedString
    
    init(_ text: AttributedString) {
        _text = State(initialValue: text)
    }
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
            Spacer().frame(width: 2)
        }
        .contentShape(Rectangle())
    }
}

struct MiddleCentered<Content>: View where Content: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    var content: ()->Content
    
    var body: some View {
        VStack {
            Spacer().frame(height: padding)
            HStack {
                Spacer().frame(width: padding)
                VStack(spacing: 0) {
                    Spacer()
                    HStack(spacing: 0) {
                        Spacer()
                        content()
                        Spacer()
                    }
                    Spacer()
                }
                .contentShape(Rectangle())
                Spacer().frame(width: padding)

            }
            Spacer().frame(height: padding)
        }
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .if(height != nil) { view in
            view.frame(width: height!)
        }
    }
}

struct MiddleCenteredAttributed: View {
    var text: AttributedString
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    
    var body: some View {
        MiddleCentered(width: width, height: height, padding: padding) { Text(text) }
    }
}

struct MiddleCenteredText: View {
    var text: String
    var padding: CGFloat = 0
    var body: some View {
        MiddleCentered(padding: padding) { Text(text) }
    }
}
