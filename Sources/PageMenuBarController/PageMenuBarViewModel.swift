//
//  PageMenuBarViewModel.swift
//
//  Created by Yugo Sugiyama on 2020/12/17.
//  Copyright © 2020 yugo.sugiyama. All rights reserved.
//

import UIKit

enum PageMenuAction {
    case paging(type: PagingType)
    case changeIndexByPaging(index: Int)
    case changeIndexBySelectTab(index: Int)

    enum PagingType {
        case start(contentOffset: CGFloat, adjustedContentOffset: CGFloat)
        case paging(rate: CGFloat)
        case complete
    }
}

final class PageMenuBarViewModel {
    private(set) var selectedIndex = 0 {
        didSet { didSelectedIndexChanged?(selectedIndex) }
    }
    private (set) var contentOffsetRate: CGFloat = 0
    private(set) var targetIndex: Int?
    // pageMenuControllerのcontentOffsetから、CollectionViewのように使える
    // contentOffsetに変換したもの
    var lastAdjustedContentOffsetX: CGFloat?
    var pageMenuAction: PageMenuAction? {
        didSet {
            guard let pageMenuAction = pageMenuAction else { return }
            didChangePagingType?(pageMenuAction)
        }
    }
    // pageMenuControllerの制御により、通常のScrollViewのcontentOffsetと異なる挙動をする
    var lastContentOffsetX: CGFloat?
    var didSelectedIndexChanged: ((Int) -> Void)?
    var didChangePagingType: ((PageMenuAction) -> Void)?

    func setSelectedIndex(index: Int) {
        if selectedIndex == index { return }
        selectedIndex = index
    }

    func setTargetIndex(index: Int?) {
        targetIndex = index
    }

    func commitPageMenuAction(action: PageMenuAction) {
        switch action {
        case .changeIndexByPaging(let index):
            targetIndex = index
        case .changeIndexBySelectTab(let index):
            targetIndex = index
        case .paging(let type):
            switch type {
            case .start(let contentOffset, let adjustedContentOffset):
                lastContentOffsetX = contentOffset
                lastAdjustedContentOffsetX = adjustedContentOffset
            case .paging(let rate):
                contentOffsetRate = rate
            case .complete:
                lastContentOffsetX = nil
                lastAdjustedContentOffsetX = nil
            }
        }
        pageMenuAction = action
    }
}
