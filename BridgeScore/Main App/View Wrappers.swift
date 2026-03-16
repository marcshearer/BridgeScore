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
    var content: ()->Content
    
    var body: some View {
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
    }
}
