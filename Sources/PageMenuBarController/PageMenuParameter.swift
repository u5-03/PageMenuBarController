//
//  PageMenuParameter.swift
//
//  Created by Yugo Sugiyama on 2021/01/14.
//  Copyright © 2021 yugo.sugiyama. All rights reserved.
//

import UIKit

public struct PageMenuParameter {
    public enum MenuType {
        case widthEqualSegment
        case horizontalScroll

        public var isHorizontalScrollEnable: Bool {
            switch self {
            case .horizontalScroll: return true
            case .widthEqualSegment: return false
            }
        }
    }
    public let menuType: MenuType
    public let menuHeight: CGFloat
    public let menuHorizontalPadding: CGFloat
    public let selectedIndicatorHeight: CGFloat
    public let selectedIndicatorColor: UIColor
    public let selectedMenuTitleColor: UIColor
    public let selectedMenuBackgroungColor: UIColor
    public let selectedMenuTitleFont: UIFont
    public let unselectedMenuTitleColor: UIColor
    public let unselectedMenuBackgroundColor: UIColor
    public let unselectedMenuTitleFont: UIFont
    public let menuBackgroundColor: UIColor
    public let dividerColor: UIColor
    public let contentBackgroundColor: UIColor

    public init(menuType: PageMenuParameter.MenuType = .horizontalScroll,
                menuHeight: CGFloat = 40,
                menuHorizontalPadding: CGFloat = 8,
                selectedIndicatorHeight: CGFloat = 1,
                selectedIndicatorColor: UIColor = .label,
                selectedMenuTitleColor: UIColor = .label,
                selectedMenuBackgroungColor: UIColor = .systemBackground,
                selectedMenuTitleFont: UIFont = .boldSystemFont(ofSize: 14),
                unselectedMenuTitleColor: UIColor = .label,
                unselectedMenuBackgroundColor: UIColor = .systemBackground,
                unselectedMenuTitleFont: UIFont = .systemFont(ofSize: 14),
                menuBackgroundColor: UIColor = .systemBackground,
                dividerColor: UIColor = .lightGray,
                contentBackgroundColor: UIColor = .systemBackground
    ) {
        self.menuType = menuType
        self.menuHeight = menuHeight
        self.menuHorizontalPadding = menuHorizontalPadding
        self.selectedIndicatorHeight = selectedIndicatorHeight
        self.selectedIndicatorColor = selectedIndicatorColor
        self.selectedMenuTitleColor = selectedMenuTitleColor
        self.selectedMenuBackgroungColor = selectedMenuBackgroungColor
        self.selectedMenuTitleFont = selectedMenuTitleFont
        self.unselectedMenuTitleColor = unselectedMenuTitleColor
        self.unselectedMenuBackgroundColor = unselectedMenuBackgroundColor
        self.unselectedMenuTitleFont = unselectedMenuTitleFont
        self.menuBackgroundColor = menuBackgroundColor
        self.dividerColor = dividerColor
        self.contentBackgroundColor = contentBackgroundColor
    }
}
