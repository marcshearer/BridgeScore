//
// Banner.swift
// Bridge Score
//
//  Created by Marc Shearer on 05/02/2021.
//

import SwiftUI

struct BannerOption {
    let image: AnyView?
    let text: String?
    let likeBack: Bool
    let action: ()->()
    
    init(image: AnyView? = nil, text: String? = nil, likeBack: Bool = false, action: @escaping ()->()) {
        self.image = image
        self.text = text
        self.likeBack = likeBack
        self.action = action
    }
}

enum BannerOptionMode {
    case menu
    case buttons
    case none
}

struct Banner: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @Binding var title: String
    var color: PaletteColor = Palette.banner
    var back: Bool = true
    var backEnabled: Binding<Bool>?
    var backImage: AnyView? = AnyView(Image(systemName: "chevron.left"))
    var backAction: (()->(Bool))?
    var optionMode: BannerOptionMode = .none
    var menuImage: AnyView? = nil
    var options: [BannerOption]? = nil
    
    var body: some View {
        ZStack {
            Palette.banner.background
                .ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                HStack {
                    Spacer().frame(width: 32)
                    ZStack {
                        HStack {
                            if back {
                                Spacer()
                            }
                            Text(title).font(.largeTitle).bold().foregroundColor(Palette.banner.text)
                            Spacer()
                        }
                        HStack {
                            if back {
                                backButton
                            }
                            Spacer()
                            switch optionMode {
                            case .menu:
                                Banner_Menu(image: menuImage, options: options!)
                            case .buttons:
                                Banner_Buttons(options: options!)
                            default:
                                EmptyView()
                            }
                        }
                    }
                }
                Spacer().frame(height: bannerBottom)
            }
        }
        .frame(height: bannerHeight)
        .background(Palette.banner.background)
    }
    
    var backButton: some View {
        let enabled = backEnabled?.wrappedValue ?? true
        return Button(action: {
            if enabled {
                if backAction?() ?? true {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }, label: {
            HStack {
                backImage
                    .font(.largeTitle)
                    .foregroundColor(Palette.bannerBackButton.opacity(enabled ? 1.0 : 0.5))
            }
        })
        .disabled(!(enabled))
    }
}

struct Banner_Menu : View {
    var image: AnyView?
    
    var options: [BannerOption]
    let menuStyle = DefaultMenuStyle()

    var body: some View {
        let menuLabel = image ?? AnyView(Image(systemName: "gearshape").foregroundColor(Palette.banner.text).font(.largeTitle))
        Menu {
            ForEach(0..<(options.count)) { (index) in
                let option = options[index]
                Button {
                    option.action()
                } label: {
                    if option.image != nil {
                        option.image
                    }
                    if option.image != nil && option.text != nil {
                        Spacer().frame(width: 16)
                    }
                    if option.text != nil {
                        Text(option.text!)
                            .minimumScaleFactor(0.5)
                    }
                }
                .menuStyle(menuStyle)
            }
        } label: {
            menuLabel
        }
        Spacer().frame(width: 16)
    }
}

struct Banner_Buttons : View {
    var options: [BannerOption]
    
    var body: some View {
        HStack {
            ForEach(0..<(options.count)) { (index) in
                let option = options[index]
                let backgroundColor = (option.likeBack ? Palette.banner.background : Palette.bannerButton.background)
                let foregroundColor = (option.likeBack ? Palette.bannerBackButton : Palette.bannerButton.text)
                Button {
                    option.action()
                } label: {
                    VStack {
                        Spacer().frame(height: 6)
                        HStack {
                            Spacer().frame(width: 16)
                            if option.image != nil {
                                option.image.foregroundColor(foregroundColor)
                            }
                            if option.image != nil && option.text != nil {
                                Spacer().frame(width: 16)
                            }
                            if option.text != nil {
                                Text(option.text ?? "").foregroundColor(foregroundColor)
                            }
                            Spacer().frame(width: 16)
                        }
                        Spacer().frame(height: 6)
                    }
                }
                .font(option.likeBack ? .largeTitle : .title)
                .background(backgroundColor)
                .cornerRadius(10.0)
                Spacer().frame(width: 16)
                
            }
        }
    }
}
