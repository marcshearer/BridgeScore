    //
    //  Multi Select Picker Input.swift
    // Bridge Score
    //
    //  Created by Marc Shearer on 14/02/2021.
    //

    import SwiftUI

    struct MultiSelectPickerInput : View {
        var id: UUID
        var title: String? = nil
        var values: ()->[(text: String, id: AnyHashable)]
        @Binding var selected: Flags
        var popupTitle: String? = nil
        var placeholder: String = ""
        var multiplePlaceholder: String?
        var selectAll: String? = nil
        var topSpace: CGFloat = 0
        var leadingSpace: CGFloat = 0
        var width: CGFloat?
        var height: CGFloat = 45
        var maxLabelWidth: CGFloat = 200
        var centered: Bool = false
        var color: PaletteColor = Palette.clear
        var selectedColor: PaletteColor = Palette.clear
        var font: Font = inputFont
        var cornerRadius: CGFloat = 0
        var below: Bool = true
        var animation: ViewAnimation = .slideLeft
        var inlineTitle: Bool = true
        var inlineTitleWidth: CGFloat = 180
        var onChange: ((Int?)->())?
            
        var body: some View {
            VStack(alignment: .leading, spacing: 0) {
                if !inlineTitle && title != nil {
                    InputTitle(title: title, topSpace: topSpace, width: (width == nil ? nil : width! + leadingSpace + 16))
                } else {
                    Spacer().frame(height: topSpace)
                }
                let values = values()
                HStack {
                    Spacer().frame(width: leadingSpace)
                    if inlineTitle && title != nil {
                        HStack {
                            Spacer().frame(width: 8)
                            Text(title!)
                            Spacer()
                        }
                        .frame(width: inlineTitleWidth)
                        Spacer().frame(width: 12)
                    }
                    if !centered {
                        Spacer().frame(width: 6)
                    }
                    
                    GeometryReader { (geometry) in
                        HStack {
                            let top = (below ? geometry.frame(in: .global).maxY - 20 : geometry.frame(in: .global).minY - (slideInMenuRowHeight * 1.4))
                            let left = (below ? geometry.frame(in: .global).minX + 20 : geometry.frame(in: .global).maxX + 30)
                            let width = (below ? width ?? geometry.size.width : 400)
                            
                            PopupMenu(id: id, selected: selected, values: values, title: popupTitle ?? title, selectAll: selectAll, animation: animation, top: top, left: left, width: width, selectedColor: selectedColor, hideBackground: !below, onChange: onChange) {
                                
                                HStack {
                                    if centered {
                                        Spacer()
                                    } else {
                                        Spacer().frame(width: 2)
                                    }
                                    Text(pickerText)
                                        .foregroundColor(placeholder == "" ? color.themeText : color.text)
                                        .font(font)
                                        .frame(maxHeight: height)
                                    if !centered {
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(color.themeText)
                                        Spacer().frame(width: 16)
                                    } else {
                                        Spacer()
                                    }
                                }
                                .background(color.background)
                            }
                        }
                    }
                }
            }
            .if(width != nil) { (view) in
                view.frame(width: width!)
            }
            .frame(height: height)
            .background(color.background)
            .cornerRadius(cornerRadius)
        }
        
        var pickerText: String {
            if selected.isEmpty {
                return placeholder
            } else if selected.hasMultiple {
                return multiplePlaceholder ?? "Multiple"
            } else {
                if let firstId = selected.firstValue(equal: true) {
                    if let option = values().first(where: {$0.id == firstId}) {
                        return option.text
                    } else {
                        return "Error"
                    }
                } else {
                    return "Error"
                }
            }
        }
    }
