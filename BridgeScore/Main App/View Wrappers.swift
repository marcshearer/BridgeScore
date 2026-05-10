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

struct Centered<Content>: View where Content: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    var content: ()->Content
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, padding: CGFloat = 0, @ViewBuilder content: @escaping ()->Content) {
        self.width = width
        self.height = height
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: padding)
            Spacer()
            content()
            Spacer()
            Spacer().frame(width: padding)
        }
        .contentShape(Rectangle())
        
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .if(height != nil) { view in
            view.frame(height: height!)
        }
    }
}

struct Leading<Content>: View where Content: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    var content: ()->Content
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, padding: CGFloat = 0, @ViewBuilder content: @escaping ()->Content) {
        self.width = width
        self.height = height
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: padding)
            content()
            Spacer()
            Spacer().frame(width: padding)
        }
        .contentShape(Rectangle())
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .if(height != nil) { view in
            view.frame(height: height!)
        }
    }
}

struct Trailing<Content>: View where Content: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    var content: ()->Content
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, padding: CGFloat = 0, @ViewBuilder content: @escaping ()->Content) {
        self.width = width
        self.height = height
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Spacer().frame(width: padding)
            Spacer()
            content()
            Spacer().frame(width: padding)
        }
        .contentShape(Rectangle())
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .if(height != nil) { view in
            view.frame(height: height!)
        }
    }
}

struct Top<Content>: View where Content: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    var content: ()->Content
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, padding: CGFloat = 0, @ViewBuilder content: @escaping ()->Content) {
        self.width = width
        self.height = height
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: padding)
            content()
            Spacer()
            Spacer().frame(height: padding)
        }
        .contentShape(Rectangle())
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .if(height != nil) { view in
            view.frame(height: height!)
        }
    }
}

struct Middle<Content>: View where Content: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    var content: ()->Content
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, padding: CGFloat = 0, @ViewBuilder content: @escaping ()->Content) {
        self.width = width
        self.height = height
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: padding)
            Spacer()
            content()
            Spacer()
            Spacer().frame(height: padding)
        }
        .contentShape(Rectangle())
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .if(height != nil) { view in
            view.frame(height: height!)
        }
    }
}

struct Bottom<Content>: View where Content: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    var content: ()->Content
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, padding: CGFloat = 0, @ViewBuilder content: @escaping ()->Content) {
        self.width = width
        self.height = height
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: padding)
            Spacer()
            content()
            Spacer().frame(height: padding)
        }
        .contentShape(Rectangle())
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .if(height != nil) { view in
            view.frame(height: height!)
        }
    }
}

struct MiddleCentered<Content>: View where Content: View {
    var width: CGFloat? = nil
    var height: CGFloat? = nil
    var padding: CGFloat = 0
    var horizontalPadding: CGFloat? = nil
    var verticalPadding: CGFloat? = nil
    var content: ()->Content
    
    init(width: CGFloat? = nil, height: CGFloat? = nil, padding: CGFloat = 0, horizontalPadding: CGFloat? = nil, verticalPadding: CGFloat? = nil, @ViewBuilder content: @escaping ()->Content) {
        self.width = width
        self.height = height
        self.padding = padding
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.content = content
    }
    
    var body: some View {
        VStack {
            Spacer().frame(height: verticalPadding ?? padding)
            HStack {
                Spacer().frame(width: horizontalPadding ?? padding)
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
                Spacer().frame(width: horizontalPadding ?? padding)

            }
            Spacer().frame(height: verticalPadding ?? padding)
        }
        .if(width != nil) { view in
            view.frame(width: width!)
        }
        .if(height != nil) { view in
            view.frame(height: height!)
        }
    }
}
