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
    @Binding var isEnabled: Bool
    let action: ()->()
    
    init(image: AnyView? = nil, text: String? = nil, likeBack: Bool = false, isEnabled: Binding<Bool>? = nil, action: @escaping ()->()) {
        self.image = image
        self.text = text
        self.likeBack = likeBack
        self.action = action
        self._isEnabled = isEnabled ?? Binding.constant(true)
    }
}

enum BannerOptionMode {
    case menu
    case buttons
    case none
}

struct Banner: View {
    @Environment(\.presentationMode) private var presentationMode: Binding<PresentationMode>

    @Binding var title: String
    var color: PaletteColor = Palette.banner
    var bottomSpace: Bool = true
    var back: Bool = true
    var backEnabled: (()->(Bool))?
    var backImage: AnyView? = AnyView(Image(systemName: "chevron.left"))
    var backAction: (()->(Bool))?
    var leftTitle: Bool?
    var optionMode: BannerOptionMode = .none
    var menuImage: AnyView? = nil
    var menuTitle: String = appName
    var options: [BannerOption]? = nil
    
    var body: some View {
        ZStack {
            Palette.banner.background
                .ignoresSafeArea(edges: .all)
            VStack {
                Spacer()
                HStack {
                    Spacer().frame(width: 20)

                    if (leftTitle ?? !back) {
                        HStack {
                            backButton
                            Spacer().frame(width: 12)
                            titleText
                            Spacer().frame(width: 20)
                            Spacer()
                            menu
                        }
                        
                    } else {
                        ZStack {
                            HStack {
                                backButton
                                Spacer()
                                menu
                            }
                            HStack {
                                Spacer().frame(width: 80)
                                Spacer()
                                titleText
                                Spacer()
                                Spacer().frame(width: 80)
                            }
                        }
                    }
                
                    Spacer().frame(width: 20)
                }
                Spacer().frame(height: bannerBottom)
            }
        }
        .frame(height: bannerHeight)
        .background(Palette.banner.background)
    }
        
    var backButton: some View {
        HStack {
            if back {
                let enabled = backEnabled?() ?? true
                Button(action: {
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
            } else {
                EmptyView()
            }
        }
    }
    
    var titleText: some View {
        Text(title)
            .font(.largeTitle).bold()
            .foregroundColor(Palette.banner.text)
            .minimumScaleFactor(0.8)
    }
    
    var menu: some View {
        HStack {
            switch optionMode {
            case .menu:
                Banner_Menu(image: menuImage, title: menuTitle, options: options!)
            case .buttons:
                Banner_Buttons(options: options!)
            default:
                EmptyView()
            }
        }
    }
}

struct Banner_Menu : View {
    var image: AnyView?
    var title: String
    var options: [BannerOption]
    let menuStyle = DefaultMenuStyle()

    var body: some View {
        Button {
            let filteredOptions = options.filter{$0.isEnabled}
            SlideInMenu.shared.show(title: title, options: filteredOptions.map{$0.text ?? ""}, top: 80) { (option) in
                    if let selected = options.first(where: {$0.text == option}) {
                        selected.action()
                    }
                }
            } label: {
                image ?? AnyView(Image(systemName: "gearshape").foregroundColor(Palette.banner.text).font(.largeTitle))
            }
    
    }
}

struct Banner_Buttons : View {
    var options: [BannerOption]
    
    var body: some View {
        HStack {
            ForEach(0..<(options.count)) { (index) in
                let option = options[index]
                let backgroundColor = (option.likeBack ? Palette.banner.background : Palette.bannerButton.background)
                let foregroundColor = (option.isEnabled ? (option.likeBack ? Palette.bannerBackButton : Palette.bannerButton.text) : Palette.bannerButton.faintText)
                HStack {
                    Button {
                        option.action()
                    } label: {
                        VStack {
                            if !option.likeBack {
                                Spacer().frame(height: 6)
                            }
                            HStack {
                                if !option.likeBack {
                                    Spacer().frame(width: 16)
                                }
                                if option.image != nil {
                                    option.image.foregroundColor(foregroundColor)
                                }
                                if option.image != nil && option.text != nil {
                                    Spacer().frame(width: 16)
                                }
                                if option.text != nil {
                                    Text(option.text ?? "").foregroundColor(foregroundColor)
                                }
                                if !option.likeBack {
                                    Spacer().frame(width: 16)
                                }
                            }
                            if !option.likeBack {
                                Spacer().frame(height: 6)
                            }
                        }
                    }
                    .disabled(!option.isEnabled)
                    .font(option.likeBack ? .largeTitle : .title)
                    .background(backgroundColor)
                    .cornerRadius(option.likeBack ? 0 : 10.0)
                    if index != options.count - 1 {
                        Spacer().frame(width: 16)
                    }
                }
            }
        }
    }
}
