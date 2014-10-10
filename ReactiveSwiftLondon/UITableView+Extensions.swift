//
//  UITableView+Extensions.swift
//  ReactiveSwiftLondon
//
//  Created by Colin Eberhardt on 10/10/2014.
//  Copyright (c) 2014 Colin Eberhardt. All rights reserved.
//

import Foundation

extension UITableView {
  func scrollToTop() {
    self.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
  }
}