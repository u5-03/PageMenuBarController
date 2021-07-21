//
//  PageMenuDelegate.swift
//
//  Created by Yugo Sugiyama on 2021/01/19.
//  Copyright © 2021 yugo.sugiyama. All rights reserved.
//

import UIKit

public protocol PageMenuDelegate: class {
    func willMoveToPage(_ controller: UIViewController, index: Int)
    func didMoveToPage(_ controller: UIViewController, index: Int)
}
