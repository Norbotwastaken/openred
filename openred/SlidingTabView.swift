////
////  SlidingTabView.swift
////  openred
////
////  Created by Norbert Antal on 6/9/23.
////
//
//import Foundation
//import SwiftUI
//
//extension View {
//    /// - Parameters:
//    ///   - id: used to differentiate a view and its ancestor if they both call `readFrame`
//    /// - Note: `onChange` maybe called with duplicated values
//    public func readFrame(in space: CoordinateSpace, id: String = "shared", onChange: @escaping (CGRect) -> Void) -> some View {
//        background(
//            GeometryReader { proxy in
//                Color
//                    .clear
//                    .preference(
//                        key: FramePreferenceKey.self,
//                        value: [.init(space: space, id: id): proxy.frame(in: space)])
//            }
//        )
//        .onPreferenceChange(FramePreferenceKey.self) {
//            onChange($0[.init(space: space, id: id)] ?? .zero)
//        }
//    }
//}
//
//private struct FramePreferenceKey: PreferenceKey {
//    static var defaultValue: [PreferenceValueKey: CGRect] = [:]
//    
//    static func reduce(value: inout [PreferenceValueKey: CGRect], nextValue: () -> [PreferenceValueKey: CGRect]) {
//        value.merge(nextValue()) { $1 }
//    }
//}
//
//private struct PreferenceValueKey: Hashable {
//    let space: CoordinateSpace
//    let id: String
//}
//
//public struct SlidingTabBar: View {
//    @Binding
//    private var selection: CGFloat
//    
//    private let tabs: [String]
//    
//    private let style: Style
//    
//    @State
//    private var size: CGSize?
//    
//    @State
//    private var labelWidths: [Int: CGFloat] = [:]
//    
//    private let onTap: ((Int) -> Void)?
//    
//    public init(selection: Binding<CGFloat>,
//                tabs: [String],
//                style: Style = .default,
//                onTap: ((Int) -> Void)? = nil) {
//        self._selection = selection
//        self.tabs = tabs
//        self.style = style
//        self.onTap = onTap
//    }
//    
//    public init(selection: Binding<Int>,
//                tabs: [String],
//                style: Style = .default,
//                onTap: ((Int) -> Void)? = nil) {
//        self._selection = .init(get: {
//            CGFloat(selection.wrappedValue)
//        }, set: { newValue in
//            selection.wrappedValue = Int(newValue.rounded())
//        })
//        self.tabs = tabs
//        self.style = style
//        self.onTap = onTap
//    }
//    
//    public var body: some View {
//        VStack(alignment: .leading, spacing: 0) {
//            HStack(spacing: 0) {
//                ForEach(Array(tabs.enumerated()), id: \.offset) { obj in
//                    Button {
//                        selection = CGFloat(obj.offset)
//                        onTap?(obj.offset)
//                    } label: {
//                        HStack {
//                            Spacer()
//                            Text(obj.element)
//                                .font(isSelected(index: obj.offset) ? style.selectedFont : style.font)
//                                .readFrame(in: .local, id: "button") {
//                                    if labelWidths[obj.offset] != $0.width {
//                                        labelWidths[obj.offset] = $0.width
//                                    }
//                                }
//                            Spacer()
//                        }
//                        .padding(.vertical, style.buttonVInset)
//                    }
//                    .accentColor(
//                        isSelected(index: obj.offset) ? style.activeAccentColor : style.inactiveAccentColor
//                    )
//                }
//            }
//            
//            ZStack(alignment: .leading) {
//                Rectangle()
//                    .fill(style.borderColor)
//                    .frame(width: totalWidth(), height: style.borderHeight, alignment: .leading)
//                indicatorContainer()
//            }
//        }
//        .readFrame(in: .local) {
//            if size != $0.size {
//                size = $0.size
//            }
//        }
//    }
//}
//
//extension SlidingTabBar {
//    private func indicatorContainer() -> some View {
//        Rectangle()
//            .fill(Color.clear)
//            .frame(width: tabWidth(), height: style.indicatorHeight)
//            .overlay(indicator(), alignment: .center)
//            .offset(x: selectionBarXOffset(), y: 0)
//            .animation(.default, value: selection)
//    }
//    
//    private func indicator() -> some View {
//        Rectangle()
//            .fill(style.activeAccentColor)
//            .frame(width: indicatorWidth(selection: selection), height: style.indicatorHeight)
//    }
//}
//
//extension SlidingTabBar {
//    private func sanitizedSelection() -> CGFloat {
//        return max(0, min(CGFloat(tabs.count - 1), selection))
//    }
//    
//    private func isSelected(index: Int) -> Bool {
//        return Int(sanitizedSelection().rounded()) == index
//    }
//    
//    private func selectionBarXOffset() -> CGFloat {
//        return tabWidth() * sanitizedSelection()
//    }
//    
//    private func indicatorWidth(selection: CGFloat) -> CGFloat {
//        let leftIndex = max(0, Int(selection.rounded(.down)))
//        let rightIndex = min(tabs.count - 1, Int(selection.rounded(.up)))
//        
//        guard let leftWidth = labelWidths[leftIndex], let rightWidth = labelWidths[rightIndex] else {
//            return tabWidth()
//        }
//        guard leftIndex < rightIndex else {
//            return leftWidth
//        }
//        
//        let progress = selection - CGFloat(leftIndex)
//        return leftWidth * (1 - progress) + rightWidth * progress
//    }
//    
//    private func totalWidth() -> CGFloat {
//        return size?.width ?? .zero
//    }
//    
//    private func tabWidth() -> CGFloat {
//        return totalWidth() / CGFloat(tabs.count)
//    }
//}
//
//extension SlidingTabBar {
//    public struct Style {
//        public let font: Font
//        public let selectedFont: Font
//        
//        public let activeAccentColor: Color
//        public let inactiveAccentColor: Color
//        
//        public let indicatorHeight: CGFloat
//        
//        public let borderColor: Color
//        public let borderHeight: CGFloat
//        
//        public let buttonVInset: CGFloat
//        
//        public init(font: Font, selectedFont: Font, activeAccentColor: Color, inactiveAccentColor: Color, indicatorHeight: CGFloat, borderColor: Color, borderHeight: CGFloat, buttonVInset: CGFloat) {
//            self.font = font
//            self.selectedFont = selectedFont
//            self.activeAccentColor = activeAccentColor
//            self.inactiveAccentColor = inactiveAccentColor
//            self.indicatorHeight = indicatorHeight
//            self.borderColor = borderColor
//            self.borderHeight = borderHeight
//            self.buttonVInset = buttonVInset
//        }
//        
//        public static let `default` = Style(
//            font: .body,
//            selectedFont: .body.bold(),
//            activeAccentColor: .blue,
//            inactiveAccentColor: .black.opacity(0.4),
//            indicatorHeight: 2,
//            borderColor: .gray.opacity(0.2),
//            borderHeight: 1,
//            buttonVInset: 10
//        )
//    }
//}
