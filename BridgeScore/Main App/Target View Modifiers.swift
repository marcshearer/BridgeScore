//
//  Target View Modifiers.swift
// Bridge Score
//
//  Created by Marc Shearer on 26/02/2021.
//

import SwiftUI

struct NoNavigationBar : ViewModifier {
        
    #if canImport(UIKit)
    func body(content: Content) -> some View { content
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
    }
    #else
    func body(content: Content) -> some View { content
        
    }
    #endif
}

extension View {
    var noNavigationBar: some View {
        self.modifier(NoNavigationBar())
    }
}

struct RightSpacer : ViewModifier {
        
    func body(content: Content) -> some View { content
        .frame(width: (MyApp.target == .iOS ? 16 : 32))
    }
}

extension View {
    var rightSpacer: some View {
        self.modifier(RightSpacer())
    }
}

struct BottomSpacer : ViewModifier {
        
    func body(content: Content) -> some View { content
        .frame(height: (MyApp.target == .iOS ? 0 : 0))
    }
}

extension View {
    var bottomSpacer: some View {
        self.modifier(BottomSpacer())
    }
}

struct MyEditModeModifier : ViewModifier {
    @Binding var editMode: MyEditMode
    #if canImport(UIKit)
    func body(content: Content) -> some View { content
        .environment(\.editMode, $editMode)
    }
    #else
    func body(content: Content) -> some View { content
        
    }
    #endif
}

extension View {
    func editMode(_ editMode: Binding<MyEditMode>) -> some View {
        self.modifier(MyEditModeModifier(editMode: editMode))
    }
}

#if canImport(UIKit)
typealias MyEditMode = EditMode
#else
typealias MyEditMode = Bool
#endif

#if canImport(UIKit)
typealias IosStackNavigationViewStyle = StackNavigationViewStyle
#else
typealias IosStackNavigationViewStyle = DefaultNavigationViewStyle
#endif
