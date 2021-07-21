//
//  TopTabCollectionView.swift
//
//  Created by Yugo Sugiyama on 2020/12/17.
//  Copyright © 2020 yugo.sugiyama. All rights reserved.
//

import UIKit

final class TopTabCollectionView: UICollectionView {
    private let bottomLineLayer = CALayer()
    private let cellKey = "TopTabCell"
    private var tabTitles: [String] = []
    private var isInitialSettingDone = false
    private var selectedIndex = 0 {
        didSet {
            switchSelected(index: selectedIndex)
        }
    }
    public var pageMenuParameter = PageMenuParameter() {
        didSet {
            setupByParameter(parameter: pageMenuParameter)
        }
    }
    var didSelectedIndexChanged: ((Int) -> Void)?
    private var rateInOneSection: CGFloat {
        return CGFloat(1) / CGFloat(tabTitles.count)
    }
    private var maxContentOffsetX: CGFloat {
        return contentSize.width - frame.width
    }
    private var contentFullWidth: CGFloat {
        return tabTitles.reduce(0) { [unowned self] (sum, title)  in
            return sum + self.itemWidth(title: title)
        }
    }
    private var horizontalScrollEnable: Bool {
        return pageMenuParameter.menuType.isHorizontalScrollEnable
            && contentFullWidth > frame.width
    }

    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.scrollDirection = .horizontal

        super.init(frame: .zero, collectionViewLayout: layout)

        register(TopTabCell.self, forCellWithReuseIdentifier: cellKey)
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        delegate = self
        dataSource = self
        backgroundColor = .systemBackground
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func refreshView() {
        collectionViewLayout.invalidateLayout()
        // 遅延入れないと、位置がずれる(boundsが確定した後)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            if !self.isInitialSettingDone {
                self.isInitialSettingDone.toggle()
                self.setContentOffset(.zero, animated: false)
            }
            let index = self.adjustedIndex(index: self.selectedIndex)
            self.changeSelectedIndex(index: index)
        }
    }

    func setTitles(titles: [String]) {
        tabTitles = titles
        // 遅延入れないと、位置がずれる(boundsが確定した後)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.setupBottomLineLayer()
        }
    }

    func changeSelectedIndex(index: Int) {
        selectedIndex = index
        let offset = adjustedContentOffset(by: index)
        setContentOffset(offset, animated: true)
        bottomLineLayer.frame = .init(
            x: distanceFromLeadingToTabLeading(index: index),
            y: bounds.height - pageMenuParameter.selectedIndicatorHeight,
            width: itemWidth(index: index),
            height: pageMenuParameter.selectedIndicatorHeight
        )
    }

    func setPagingStatus(type: PageMenuAction.PagingType) {
        switch type {
        case .paging(let rate):
            adjustContentOffset(by: rate)
        default: break
        }
    }

    private func setupByParameter(parameter: PageMenuParameter) {
        backgroundColor = parameter.menuBackgroundColor
        bottomLineLayer.backgroundColor = parameter.selectedIndicatorColor.cgColor
        bottomLineLayer.frame.size = CGSize(width: bottomLineLayer.frame.size.width, height: parameter.selectedIndicatorHeight)
        visibleCells.compactMap({ $0 as? TopTabCell })
            .forEach({ $0.pageMenuParameter = parameter })
        collectionViewLayout.invalidateLayout()
    }

    private func setupBottomLineLayer() {
        layer.addSublayer(bottomLineLayer)
        bottomLineLayer.frame = .init(x: 0,
                                      y: bounds.size.height - pageMenuParameter.selectedIndicatorHeight,
                                      width: itemWidth(index: 0),
                                      height: pageMenuParameter.selectedIndicatorHeight)
    }

    // rateからcontentOffsetの値/選択中のbottomの下線を操作する
    private func adjustContentOffset(by rate: CGFloat, animated: Bool = false) {
        let adjustedSelectedIndex = self.adjustedIndex(index: selectedIndex)
        let currentIndexContentOffset = adjustedContentOffset(by: adjustedSelectedIndex)
        let currentIndexRate = rateInOneSection * CGFloat(adjustedSelectedIndex)
        let transitionDistance: CGFloat
        let isDraggingToRight = rate > currentIndexRate
        let dragingRate = (rate - currentIndexRate) / rateInOneSection

        // bottomLineLayerの操作
        let currentTabWidth = itemWidth(index: adjustedSelectedIndex)
        let targetTabWidth: CGFloat
        if let validatedIndex = validatedIndex(index: selectedIndex + (isDraggingToRight ? 1 : -1)) {
            targetTabWidth = itemWidth(index: validatedIndex)
        } else {
            // Leading/Trailingでそれぞれ横にスクロールした時に、targetWidthが
            // 0にならないようにする対応
            targetTabWidth = currentTabWidth
        }
        let tabWidthDiff = (targetTabWidth - currentTabWidth) * dragingRate * (isDraggingToRight ? 1 : -1)

        let currentTabContentOffsetX = distanceFromLeadingToTabLeading(index: adjustedSelectedIndex)
        let layerOffsetDiff: CGFloat
        switch pageMenuParameter.menuType {
        case .horizontalScroll:
            layerOffsetDiff = itemWidth(index: isDraggingToRight ? adjustedSelectedIndex : (adjustedSelectedIndex - 1)) * dragingRate
        case .widthEqualSegment:
            layerOffsetDiff = itemWidth(index: selectedIndex) * dragingRate
        }
        bottomLineLayer.frame = .init(
            x: currentTabContentOffsetX + layerOffsetDiff,
            y: bounds.height - pageMenuParameter.selectedIndicatorHeight,
            width: currentTabWidth + tabWidthDiff,
            height: pageMenuParameter.selectedIndicatorHeight
        )
        if !horizontalScrollEnable { return }
        // Leading寄りで、contentOffsetXを変更しない場合、ドラッグ中に
        // contentOffsetXを移動するようになる場合
        if isLeadingScrollDisabled(index: adjustedSelectedIndex) {
            if isDraggingToRight {
                // 中央から右側
                transitionDistance = adjustedContentOffset(by: adjustedSelectedIndex + 1).x - currentIndexContentOffset.x
            } else {
                // 中央から左側
                transitionDistance = previousScrollDistance(index: adjustedSelectedIndex)
            }
        // Trailing寄りで、contentOffsetXを変更しない場合、ドラッグ中に
        // contentOffsetXを移動するようになる場合
        } else if isTrailingScrollDisabled(index: adjustedSelectedIndex) {
            if isDraggingToRight {
                // 中央から右側
                transitionDistance = nextScrollDistance(index: adjustedSelectedIndex)
            } else {
                // 中央から左側
                transitionDistance = currentIndexContentOffset.x - adjustedContentOffset(by: adjustedSelectedIndex - 1).x
            }
        } else {
            if isDraggingToRight {
                // 中央から右側
                transitionDistance = nextScrollDistance(index: adjustedSelectedIndex)
            } else {
                // 中央から左側
                transitionDistance = previousScrollDistance(index: adjustedSelectedIndex)
            }
        }
        let diff = dragingRate * transitionDistance
        // ContentOffsetの操作
        let offset = CGPoint(x: adjustedContentOffsetX(contentOffsetX: currentIndexContentOffset.x + diff),
                             y: currentIndexContentOffset.y)
        setContentOffset(offset, animated: animated)
    }

    // contentOffsetXの値が最小値/最大値を超えていないかの確認
    private func adjustedContentOffsetX(contentOffsetX: CGFloat) -> CGFloat {
        return max(0, min(maxContentOffsetX, contentOffsetX))
    }

    // TabTitleのcountの最小値/最大値をindexが超えていないかの確認
    // 超えている場合はnilを返す
    private func validatedIndex(index: Int) -> Int? {
        if index > tabTitles.count - 1 || index < 0 {
            return nil
        } else {
            return index
        }
    }

    // TabTitleのcountの最小値~最大値の範囲内に調整したindexを返す
    private func adjustedIndex(index: Int) -> Int {
        return max(0, min(tabTitles.count - 1, index))
    }

    // indexからそのタブの中央までのcontentOffsetを返す
    private func adjustedContentOffset(by index: Int) -> CGPoint {
        let adjustedIndex = self.adjustedIndex(index: index)
        if !horizontalScrollEnable {
            return .zero
        } else if distanceFromLeadingToCenter(index: adjustedIndex) < frame.width / 2 {
            return .zero
        } else if distanceFromTrailingToCenter(index: adjustedIndex) < frame.width / 2 {
            return CGPoint(x: maxContentOffsetX, y: contentOffset.y)
        } else {
            let offsetX = distanceFromLeadingToCenter(index: adjustedIndex) - frame.width / 2
            return CGPoint(x: offsetX, y: contentOffset.y)
        }
    }

    // Leadingからindexのタブの中央までの距離
    private func distanceFromLeadingToCenter(index: Int) -> CGFloat {
        let adjustedIndex = self.adjustedIndex(index: index)
        let halfCenterTitleWidth = itemWidth(title: tabTitles[adjustedIndex]) / 2
        return distanceFromLeadingToTabLeading(index: adjustedIndex)
            + halfCenterTitleWidth
    }

    // Trailingからindexのタブの中央までの距離
    private func distanceFromTrailingToCenter(index: Int) -> CGFloat {
        let adjustedIndex = self.adjustedIndex(index: index)
        let halfCenterTitleWidth = itemWidth(title: tabTitles[adjustedIndex]) / 2
        return tabTitles.suffix(from: adjustedIndex + 1).reduce(0) { [unowned self] (sum, title) in
            return sum + self.itemWidth(title: title)
        } + halfCenterTitleWidth
    }

    // Leadingからindexのタブのleadingの辺までの距離
    private func distanceFromLeadingToTabLeading(index: Int) -> CGFloat {
        let adjustedIndex = self.adjustedIndex(index: index)
        return tabTitles.prefix(adjustedIndex).enumerated()
            .reduce(0) { [unowned self] (sum, element)  in
                return sum + self.itemWidth(index: element.offset)
            }
    }

    // Leading側でタブ選択中にcontentOffsetの移動がない場合はtrueを返す
    private func isLeadingScrollDisabled(index: Int) -> Bool {
        let adjustedIndex = self.adjustedIndex(index: index)
        let contentOffsetByIndex = adjustedContentOffset(by: adjustedIndex)
        if contentOffsetByIndex.x - previousScrollDistance(index: adjustedIndex) <= 0 {
            return true
        } else {
            return false
        }
    }

    // Trailing側でタブ選択中にcontentOffsetの移動がない場合はtrueを返す
    private func isTrailingScrollDisabled(index: Int) -> Bool {
        let contentOffsetByIndex = adjustedContentOffset(by: index)
        if contentOffsetByIndex.x + nextScrollDistance(index: index) >= maxContentOffsetX {
            return true
        } else {
            return false
        }
    }

    // 現在のタブから次のタブまでに移動する距離
    private func nextScrollDistance(index: Int) -> CGFloat {
        let distance = (itemWidth(index: index)
            + itemWidth(index: index + 1)) / 2
        let diff = maxContentOffsetX - adjustedContentOffset(by: index).x
        return min(diff, distance)
    }

    // 現在のタブから前のタブまでに移動する距離
    private func previousScrollDistance(index: Int) -> CGFloat {
        let distance = (itemWidth(index: selectedIndex - 1)
                    + itemWidth(index: selectedIndex)) / 2
        let diff = adjustedContentOffset(by: index).x
        return min(diff, distance)
    }

    // indexから各タブの幅を計算する
    private func itemWidth(index: Int) -> CGFloat {
        switch pageMenuParameter.menuType {
        case .horizontalScroll:
            guard let validatedIndex = validatedIndex(index: index) else { return 0 }
            let title = tabTitles[validatedIndex]
            return itemWidth(title: title)
        case .widthEqualSegment:
            if tabTitles.count == 0 { return 0 }
            return frame.width / CGFloat(tabTitles.count)
        }
    }

    // 文字列から各タブの幅を計算する
    private func itemWidth(title: String) -> CGFloat {
        let label = UILabel()
        label.text = title
        label.sizeToFit()
        return label.frame.width + pageMenuParameter.menuHorizontalPadding * 2
    }

    private func switchSelected(index: Int) {
        selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .init())
    }

    private func switchSelected(indexPath: IndexPath) {
        selectItem(at: indexPath, animated: false, scrollPosition: .init())
    }
}

// MARK: UICollectionView Delegate
extension TopTabCollectionView: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectedIndexChanged?(indexPath.item)
    }
}

// MARK: UICollectionView DataSource
extension TopTabCollectionView: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabTitles.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellKey, for: indexPath) as? TopTabCell else { return .init() }
        cell.titleLabel.text = tabTitles[indexPath.item]
        cell.pageMenuParameter = pageMenuParameter
        return cell
    }
}

extension TopTabCollectionView: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch pageMenuParameter.menuType {
        case .horizontalScroll:
            let width = itemWidth(title: tabTitles[indexPath.item])
            return CGSize(width: width, height: collectionView.bounds.height)
        case .widthEqualSegment:
            let width = itemWidth(index: indexPath.item)
            return CGSize(width: width, height: collectionView.bounds.height)
        }
    }
}
