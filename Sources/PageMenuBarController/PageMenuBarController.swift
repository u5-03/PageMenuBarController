//
//  PageMenuBarController.swift
//
//  Created by Yugo Sugiyama on 2020/12/17.
//  Copyright © 2020 yugo.sugiyama. All rights reserved.
//

import UIKit

public class PageMenuBarController: UIViewController {
    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        return stackView
    }()
    private let tempLabel = UILabel()
    private let topTabCollectionView = TopTabCollectionView()
    private var topTabHeightConstraint: NSLayoutConstraint?
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: .none)
    private let viewModel = PageMenuBarViewModel()
    // DataSources
    private var viewControllers: [UIViewController] = []
    // Parameter
    public var pageMenuParameter = PageMenuParameter() {
        didSet {
            setupByParameter(parameter: pageMenuParameter)
        }
    }
    private var selectedIndexContentOffsetX: CGFloat {
        return CGFloat(viewModel.selectedIndex) * pageViewController.view.frame.width
    }
    // Delegate
    public weak var delegate: PageMenuDelegate?

    public init() {
        super.init(nibName: nil, bundle: nil)
        initialSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        topTabCollectionView.refreshView()
    }

    public func setContents(viewControllers: [UIViewController], selectedIndex: Int = 0) {
        let titles = viewControllers.map({ $0.title ?? "" })
        topTabCollectionView.setTitles(titles: titles)
        self.viewControllers = viewControllers
        viewModel.setSelectedIndex(index: selectedIndex)
        pageViewController.setViewControllers([viewControllers[selectedIndex]], direction: .forward, animated: true, completion: nil)
        topTabCollectionView.reloadData()
    }

    public func setSelectedIndex(index: Int) {
        viewModel.setSelectedIndex(index: index)
    }

    private func initialSetup() {
        setupViews()
        pageViewController.delegate = self
        pageViewController.dataSource = self
        if let scrollView = pageViewController.view
            .subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
            scrollView.delegate = self
        }
        viewModel.didSelectedIndexChanged = { [weak self] index in
            guard let self = self else { return }
            self.topTabCollectionView.changeSelectedIndex(index: index)
            self.switchContentPage(targetIndex: index)
        }
        viewModel.didChangePagingType = { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .paging(let type):
                self.topTabCollectionView.setPagingStatus(type: type)
            case .changeIndexByPaging(let index), .changeIndexBySelectTab(let index):
                self.topTabCollectionView.changeSelectedIndex(index: index)
            }
        }
        topTabCollectionView.didSelectedIndexChanged = { [weak self] index in
            guard let self = self else { return }
            self.viewModel.setSelectedIndex(index: index)
        }
    }

    private func setupViews() {
        view.addSubview(verticalStackView)

        verticalStackView.addArrangedSubview(tempLabel)
        verticalStackView.addArrangedSubview(topTabCollectionView)
        verticalStackView.addArrangedSubview(dividerView)
        verticalStackView.addArrangedSubview(pageViewController.view)
        verticalStackView.translatesAutoresizingMaskIntoConstraints = false
        topTabCollectionView.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false

        let topTabHeightConstraint = topTabCollectionView.heightAnchor.constraint(equalToConstant: pageMenuParameter.menuHeight)
        self.topTabHeightConstraint = topTabHeightConstraint
        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            verticalStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: verticalStackView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: verticalStackView.bottomAnchor),

            topTabHeightConstraint,
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            tempLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func switchContentPage(targetIndex: Int) {
        if viewControllers.isEmpty { return }
        let targetVC = viewControllers[targetIndex]
        guard let targetVCIndex = viewControllers.firstIndex(where: { $0 == targetVC }),
              let currentVC = pageViewController.viewControllers?.first,
              let currentVCIndex = viewControllers.firstIndex(where: { $0 == currentVC })
        else { return }
        if currentVCIndex == targetIndex { return }
        let direction: UIPageViewController.NavigationDirection = targetVCIndex > currentVCIndex ? .forward : .reverse
        delegate?.willMoveToPage(targetVC, index: targetIndex)
        pageViewController.setViewControllers([targetVC], direction: direction, animated: true) { [weak self] _ in
            self?.delegate?.didMoveToPage(targetVC, index: targetIndex)
        }
    }

    private func adjustedContentOffsetX(contentOffsetX: CGFloat) -> CGFloat? {
        let adjustedContentOffsetX: CGFloat
        let frameWidth = pageViewController.view.frame.width
        // PageMenuViewControllerではcontentOffsetXの初期値がfullContentWidth
        // の値になる
        if contentOffsetX < 0 {
            adjustedContentOffsetX = selectedIndexContentOffsetX - frameWidth
        } else if contentOffsetX > frameWidth * 2 {
            adjustedContentOffsetX = selectedIndexContentOffsetX + frameWidth
        } else {
            adjustedContentOffsetX = contentOffsetX - frameWidth + selectedIndexContentOffsetX
        }
        guard let lastContentOffset = viewModel.lastContentOffsetX else { return nil }
        // Pagingが終わり、PageViewControllerにより、ContentOffsetが調整された
        // 後の値は処理しない
        if abs(lastContentOffset - contentOffsetX) == frameWidth {
            viewModel.commitPageMenuAction(action: .paging(type: .complete))
            return nil
        }
        return adjustedContentOffsetX
    }

    private func contentOffsetRate(adjustedContentOffsetX: CGFloat) -> CGFloat? {
        let fullContentWidth = CGFloat(viewControllers.count) * pageViewController.view.frame.width
        let rate = adjustedContentOffsetX / fullContentWidth
        return rate
    }

    private func setupByParameter(parameter: PageMenuParameter) {
        dividerView.backgroundColor = parameter.dividerColor
        topTabHeightConstraint?.constant = parameter.menuHeight
        topTabCollectionView.pageMenuParameter = parameter
        view.backgroundColor = parameter.contentBackgroundColor
    }
}

extension PageMenuBarController: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        viewModel.commitPageMenuAction(action: .paging(type: .start(contentOffset: scrollView.contentOffset.x, adjustedContentOffset: selectedIndexContentOffsetX)))
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewModel.commitPageMenuAction(action: .paging(type: .complete))
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let adjustedContentOffsetX = adjustedContentOffsetX(contentOffsetX: scrollView.contentOffset.x),
            let rate = contentOffsetRate(adjustedContentOffsetX: adjustedContentOffsetX) else { return }
        tempLabel.text = " \(rate.description)"
        viewModel.commitPageMenuAction(action: .paging(type: .paging(rate: rate)))
    }
}

// MARK: PageViewControllerDelegate
extension PageMenuBarController: UIPageViewControllerDelegate {
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let targetIndex = viewControllers
                .firstIndex(where: { $0 == pendingViewControllers.first }) else { return }
        viewModel.setTargetIndex(index: targetIndex)
        delegate?.willMoveToPage(viewControllers[targetIndex], index: targetIndex)
    }

    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        defer {
            viewModel.setTargetIndex(index: nil)
        }
        guard completed, let currenVC = pageViewController.viewControllers?.first,
              let targetIndex = viewControllers.firstIndex(where: { $0 == currenVC }) else { return }
        viewModel.setSelectedIndex(index: targetIndex)
        if finished {
            delegate?.didMoveToPage(viewControllers[targetIndex], index: targetIndex)
        }
    }
}

// MARK: PageViewControllerDataSource
extension PageMenuBarController: UIPageViewControllerDataSource {
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.firstIndex(of: viewController),
           index > 0 {
            return viewControllers[index - 1]
        } else {
            return nil
        }
    }

    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.firstIndex(of: viewController),
           index < viewControllers.count - 1 {
            return viewControllers[index + 1]
        } else {
            return nil
        }
    }
}
