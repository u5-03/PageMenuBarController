//
//  TopTabCell.swift
//
//  Created by Yugo Sugiyama on 2020/12/17.
//  Copyright © 2020 yugo.sugiyama. All rights reserved.
//

import UIKit

final class TopTabCell: UICollectionViewCell {
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()
    private var titleLabelLeadingConstraint: NSLayoutConstraint?
    private var titleLabelTrailingConstraint: NSLayoutConstraint?
    public var pageMenuParameter = PageMenuParameter() {
        didSet {
            setupByParameter(parameter: pageMenuParameter)
        }
    }

    override var isSelected: Bool {
        didSet {
            switchSelected(isSelected: isSelected)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func switchSelected(isSelected: Bool) {
        if isSelected {
            titleLabel.font = pageMenuParameter.selectedMenuTitleFont
            titleLabel.textColor = pageMenuParameter.selectedMenuTitleColor
            backgroundColor = pageMenuParameter.selectedMenuBackgroungColor
        } else {
            titleLabel.font = pageMenuParameter.unselectedMenuTitleFont
            titleLabel.textColor = pageMenuParameter.unselectedMenuTitleColor
            backgroundColor = pageMenuParameter.unselectedMenuBackgroundColor
        }
    }

    private func initialSetup() {
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        let titleLabelLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: pageMenuParameter.menuHorizontalPadding)
        let titleLabelTrailingConstraint = trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: pageMenuParameter.menuHorizontalPadding)
        self.titleLabelLeadingConstraint = titleLabelLeadingConstraint
        self.titleLabelTrailingConstraint = titleLabelTrailingConstraint
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabelLeadingConstraint,
            titleLabelTrailingConstraint,
            bottomAnchor.constraint(equalTo: titleLabel.bottomAnchor)
        ])
        switchSelected(isSelected: isSelected)
    }

    private func setupByParameter(parameter: PageMenuParameter) {
        switchSelected(isSelected: isSelected)
        titleLabelLeadingConstraint?.constant = parameter.menuHorizontalPadding
        titleLabelTrailingConstraint?.constant = parameter.menuHorizontalPadding
    }
}
